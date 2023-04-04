# Terraform manifest for deployment of OpenStack Sunbeam
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

provider "juju" {}

resource "juju_model" "sunbeam" {
  name = var.model

  cloud {
    name   = var.cloud
    region = "localhost"
  }

  credential = var.credential
  config     = var.config
}

module "mysql" {
  source  = "./modules/mysql"
  model   = juju_model.sunbeam.name
  name    = "mysql"
  channel = var.mysql_channel
}

module "rabbitmq" {
  source  = "./modules/rabbitmq"
  model   = juju_model.sunbeam.name
  scale   = 1
  channel = var.rabbitmq_channel
}

module "glance" {
  source           = "./modules/openstack-api"
  charm            = "glance-k8s"
  name             = "glance"
  model            = juju_model.sunbeam.name
  channel          = var.openstack_channel
  rabbitmq         = module.rabbitmq.name
  mysql            = module.mysql.name
  keystone         = module.keystone.name
  ingress-internal = juju_application.traefik.name
  ingress-public   = juju_application.traefik.name
}

module "keystone" {
  source           = "./modules/openstack-api"
  charm            = "keystone-k8s"
  name             = "keystone"
  model            = juju_model.sunbeam.name
  channel          = var.openstack_channel
  mysql            = module.mysql.name
  ingress-internal = juju_application.traefik.name
  ingress-public   = juju_application.traefik.name
}

module "nova" {
  source           = "./modules/openstack-api"
  charm            = "nova-k8s"
  name             = "nova"
  model            = juju_model.sunbeam.name
  channel          = var.openstack_channel
  rabbitmq         = module.rabbitmq.name
  mysql            = module.mysql.name
  keystone         = module.keystone.name
  ingress-internal = juju_application.traefik.name
  ingress-public   = juju_application.traefik.name
  scale            = 1
}

module "horizon" {
  source               = "./modules/openstack-api"
  charm                = "horizon-k8s"
  name                 = "horizon"
  model                = juju_model.sunbeam.name
  channel              = var.openstack_channel
  mysql                = module.mysql.name
  keystone-credentials = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
}

# TODO: specific module for nova?
resource "juju_integration" "nova-api-to-mysql" {
  model = juju_model.sunbeam.name

  application {
    name     = module.nova.name
    endpoint = "api-database"
  }

  application {
    name     = module.mysql.name
    endpoint = "database"
  }
}

resource "juju_integration" "nova-cell-to-mysql" {
  model = juju_model.sunbeam.name

  application {
    name     = module.nova.name
    endpoint = "cell-database"
  }

  application {
    name     = module.mysql.name
    endpoint = "database"
  }
}

module "neutron" {
  source           = "./modules/openstack-api"
  charm            = "neutron-k8s"
  name             = "neutron"
  model            = juju_model.sunbeam.name
  channel          = var.openstack_channel
  rabbitmq         = module.rabbitmq.name
  mysql            = module.mysql.name
  keystone         = module.keystone.name
  ingress-internal = juju_application.traefik.name
  ingress-public   = juju_application.traefik.name
  scale            = 1
}

module "placement" {
  source           = "./modules/openstack-api"
  charm            = "placement-k8s"
  name             = "placement"
  model            = juju_model.sunbeam.name
  channel          = var.openstack_channel
  mysql            = module.mysql.name
  keystone         = module.keystone.name
  ingress-internal = juju_application.traefik.name
  ingress-public   = juju_application.traefik.name
  scale            = 1
}

resource "juju_application" "traefik" {
  name  = "traefik"
  trust = true
  model = juju_model.sunbeam.name

  charm {
    name    = "traefik-k8s"
    channel = "1.0/stable"
  }

  units = 1
}

resource "juju_application" "certificate-authority" {
  name  = "certificate-authority"
  trust = true
  model = juju_model.sunbeam.name

  charm {
    name    = "tls-certificates-operator"
    channel = "edge"
    series  = "jammy"
  }

  config = {
    generate-self-signed-certificates = true
    ca-common-name                    = "internal-ca"
  }
}

module "ovn" {
  source      = "./modules/ovn"
  model       = juju_model.sunbeam.name
  channel     = var.ovn_channel
  scale       = 1
  relay       = true
  relay_scale = 1
  ca          = juju_application.certificate-authority.name
}



# juju integrate ovn-central neutron
resource "juju_integration" "ovn-central-to-neutron" {
  model = juju_model.sunbeam.name

  application {
    name     = module.ovn.name
    endpoint = "ovsdb-cms"
  }

  application {
    name     = module.neutron.name
    endpoint = "ovsdb-cms"
  }
}


# juju integrate neutron vault
resource "juju_integration" "neutron-to-ca" {
  model = juju_model.sunbeam.name

  application {
    name     = module.neutron.name
    endpoint = "certificates"
  }

  application {
    name     = juju_application.certificate-authority.name
    endpoint = "certificates"
  }
}

# juju integrate nova placement
resource "juju_integration" "nova-to-placement" {
  model = juju_model.sunbeam.name

  application {
    name     = module.nova.name
    endpoint = "placement"
  }

  application {
    name     = module.placement.name
    endpoint = "placement"
  }
}
