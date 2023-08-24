# Terraform module for deployment of OpenStack API services
#
# Copyright (c) 2022 Canonical Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = ">= 0.7.0"
    }
  }
}

resource "juju_application" "service" {
  name  = var.name
  model = var.model

  charm {
    name    = var.charm
    channel = var.channel
    series  = "jammy"
  }

  config = var.resource-configs

  units = var.scale
}

resource "juju_application" "mysql-router" {
  name  = "${var.name}-mysql-router"
  trust = true
  model = var.model

  charm {
    name    = "mysql-router-k8s"
    channel = var.mysql-router-channel
    series  = "jammy"
  }

  units = var.scale
}

resource "juju_integration" "mysql-router-to-mysql" {
  model = var.model

  application {
    name     = juju_application.mysql-router.name
    endpoint = "backend-database"
  }

  application {
    name     = var.mysql
    endpoint = "database"
  }
}

resource "juju_integration" "service-to-mysql-router" {
  model = var.model

  application {
    name     = juju_application.service.name
    endpoint = "database"
  }

  application {
    name     = juju_application.mysql-router.name
    endpoint = "database"
  }
}

# NOTE: this integration is optional
resource "juju_integration" "service-to-rabbitmq" {
  for_each = var.rabbitmq == "" ? {} : { target = var.rabbitmq }

  model = var.model

  application {
    name     = juju_application.service.name
    endpoint = "amqp"
  }

  application {
    name     = each.value
    endpoint = "amqp"
  }
}

# NOTE: this integration is optional
resource "juju_integration" "keystone-to-service" {
  for_each = var.keystone == "" ? {} : { target = var.keystone }
  model    = var.model

  application {
    name     = each.value
    endpoint = "identity-service"
  }

  application {
    name     = juju_application.service.name
    endpoint = "identity-service"
  }
}

resource "juju_integration" "service-to-keystone" {
  for_each = var.keystone-credentials == "" ? {} : { target = var.keystone-credentials }
  model    = var.model

  application {
    name     = each.value
    endpoint = "identity-credentials"
  }

  application {
    name     = juju_application.service.name
    endpoint = "identity-credentials"
  }
}

resource "juju_integration" "service-to-keystone-ops" {
  for_each = var.keystone-ops == "" ? {} : { target = var.keystone-ops }
  model    = var.model

  application {
    name     = each.value
    endpoint = "identity-ops"
  }

  application {
    name     = juju_application.service.name
    endpoint = "identity-ops"
  }
}

# juju integrate traefik-public glance
resource "juju_integration" "traefik-public-to-service" {
  for_each = var.ingress-public == "" ? {} : { target = var.ingress-public }
  model    = var.model

  application {
    name     = each.value
    endpoint = "ingress"
  }

  application {
    name     = juju_application.service.name
    endpoint = "ingress-public"
  }
}

# juju integrate traefik-internal glance
resource "juju_integration" "traefik-internal-to-service" {
  for_each = var.ingress-internal == "" ? {} : { target = var.ingress-internal }
  model    = var.model

  application {
    name     = each.value
    endpoint = "ingress"
  }

  application {
    name     = juju_application.service.name
    endpoint = "ingress-internal"
  }
}

# TODO: specific module for nova?
resource "juju_application" "nova-api-mysql-router" {
  count = var.name == "nova" ? 1 : 0
  name  = "nova-api-mysql-router"
  model = var.model

  charm {
    name    = "mysql-router-k8s"
    channel = var.mysql-router-channel
    series  = "jammy"
  }

  units = var.scale
}

resource "juju_integration" "nova-api-to-mysql-router" {
  count = length(juju_application.nova-api-mysql-router)
  model = var.model

  application {
    name     = juju_application.service.name
    endpoint = "api-database"
  }

  application {
    name     = juju_application.nova-api-mysql-router[count.index].name
    endpoint = "database"
  }
}

resource "juju_integration" "nova-api-router-to-mysql" {
  count = length(juju_application.nova-api-mysql-router)
  model = var.model

  application {
    name     = var.mysql
    endpoint = "database"
  }

  application {
    name     = juju_application.nova-api-mysql-router[count.index].name
    endpoint = "backend-database"
  }
}

resource "juju_application" "nova-cell-mysql-router" {
  count = var.name == "nova" ? 1 : 0
  name  = "nova-cell-mysql-router"
  model = var.model

  charm {
    name    = "mysql-router-k8s"
    channel = var.mysql-router-channel
    series  = "jammy"
  }

  units = var.scale
}

resource "juju_integration" "nova-cell-router-to-mysql" {
  count = length(juju_application.nova-cell-mysql-router)
  model = var.model

  application {
    name     = var.mysql
    endpoint = "database"
  }

  application {
    name     = juju_application.nova-cell-mysql-router[count.index].name
    endpoint = "backend-database"
  }
}

resource "juju_integration" "nova-cell-to-mysql-router" {
  count = length(juju_application.nova-cell-mysql-router)
  model = var.model

  application {
    name     = juju_application.service.name
    endpoint = "cell-database"
  }

  application {
    name     = juju_application.nova-cell-mysql-router[count.index].name
    endpoint = "database"
  }
}

resource "juju_offer" "keystone-offer" {
  count            = var.name == "keystone" ? 1 : 0
  model            = var.model
  application_name = juju_application.service.name
  endpoint         = "identity-credentials"
}
