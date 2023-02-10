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
      version = ">= 0.4.1"
    }
  }
}

resource "juju_application" "service" {
  name  = var.name
  trust = true
  model = var.model

  charm {
    name    = var.charm
    channel = var.channel
    series  = "jammy"
  }

  units = var.scale
}

resource "juju_application" "mysql_router" {
  name  = "${var.name}-mysql-router"
  trust = true
  model = var.model

  charm {
    name    = "mysql-router-k8s"
    channel = "latest/edge"
    series  = "jammy"
  }

  units = var.scale
}


resource "juju_integration" "mysql-router-to-mysql" {
  model = var.model

  application {
    name     = juju_application.mysql_router.name
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
    name     = juju_application.mysql_router.name
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

# juju integrate traefik-public glance
resource "juju_integration" "traefik-public-to-service" {
  model = var.model

  application {
    name     = var.ingress-public
    endpoint = "ingress"
  }

  application {
    name     = juju_application.service.name
    endpoint = "ingress-public"
  }
}

# juju integrate traefik-internal glance
resource "juju_integration" "traefik-internal-to-service" {
  model = var.model

  application {
    name     = var.ingress-internal
    endpoint = "ingress"
  }

  application {
    name     = juju_application.service.name
    endpoint = "ingress-internal"
  }
}