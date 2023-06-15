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
      version = ">= 0.7.0"
    }
  }
}

provider "juju" {}

locals {
  services-with-mysql = ["keystone", "glance", "nova", "horizon", "neutron", "placement", "cinder"]
}

data "juju_offer" "microceph" {
  count = var.enable-ceph ? 1 : 0
  url   = var.ceph-offer-url
}

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
  source     = "./modules/mysql"
  model      = juju_model.sunbeam.name
  name       = "mysql"
  channel    = var.mysql-channel
  scale      = var.ha-scale
  many-mysql = var.many-mysql
  services   = local.services-with-mysql
}

module "rabbitmq" {
  source  = "./modules/rabbitmq"
  model   = juju_model.sunbeam.name
  scale   = var.ha-scale
  channel = var.rabbitmq-channel
}

module "glance" {
  source               = "./modules/openstack-api"
  charm                = "glance-k8s"
  name                 = "glance"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  rabbitmq             = module.rabbitmq.name
  mysql                = module.mysql.name["glance"]
  keystone             = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.enable-ceph ? var.os-api-scale : 1
  mysql-router-channel = var.mysql-router-channel
  resource-configs = {
    ceph-osd-replication-count = var.ceph-osd-replication-count
  }
}

module "keystone" {
  source               = "./modules/openstack-api"
  charm                = "keystone-k8s"
  name                 = "keystone"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  mysql                = module.mysql.name["keystone"]
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

module "nova" {
  source               = "./modules/openstack-api"
  charm                = "nova-k8s"
  name                 = "nova"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  rabbitmq             = module.rabbitmq.name
  mysql                = module.mysql.name["nova"]
  keystone             = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

module "horizon" {
  source               = "./modules/openstack-api"
  charm                = "horizon-k8s"
  name                 = "horizon"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  mysql                = module.mysql.name["horizon"]
  keystone-credentials = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

module "neutron" {
  source               = "./modules/openstack-api"
  charm                = "neutron-k8s"
  name                 = "neutron"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  rabbitmq             = module.rabbitmq.name
  mysql                = module.mysql.name["neutron"]
  keystone             = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

module "placement" {
  source               = "./modules/openstack-api"
  charm                = "placement-k8s"
  name                 = "placement"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  mysql                = module.mysql.name["placement"]
  keystone             = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

resource "juju_application" "traefik" {
  name  = "traefik"
  trust = true
  model = juju_model.sunbeam.name

  charm {
    name    = "traefik-k8s"
    channel = "1.0/candidate"
    series  = "focal"
  }

  units = var.ingress-scale
}

resource "juju_application" "certificate-authority" {
  name  = "certificate-authority"
  trust = true
  model = juju_model.sunbeam.name

  charm {
    name    = "tls-certificates-operator"
    channel = "latest/stable"
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
  channel     = var.ovn-channel
  scale       = var.ha-scale
  relay       = true
  relay-scale = var.os-api-scale
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

# juju integrate glance microceph
resource "juju_integration" "glance-to-ceph" {
  count = length(data.juju_offer.microceph)
  model = juju_model.sunbeam.name

  application {
    name     = module.glance.name
    endpoint = "ceph"
  }

  application {
    offer_url = data.juju_offer.microceph[count.index].url
  }
}

module "cinder" {
  source               = "./modules/openstack-api"
  charm                = "cinder-k8s"
  name                 = "cinder"
  model                = juju_model.sunbeam.name
  channel              = var.openstack-channel
  rabbitmq             = module.rabbitmq.name
  mysql                = module.mysql.name["cinder"]
  keystone             = module.keystone.name
  ingress-internal     = juju_application.traefik.name
  ingress-public       = juju_application.traefik.name
  scale                = var.os-api-scale
  mysql-router-channel = var.mysql-router-channel
}

module "cinder-ceph" {
  source           = "./modules/openstack-api"
  charm            = "cinder-ceph-k8s"
  name             = "cinder-ceph"
  model            = juju_model.sunbeam.name
  channel          = var.openstack-channel
  rabbitmq         = module.rabbitmq.name
  mysql            = module.mysql.name["cinder"]
  ingress-internal = ""
  ingress-public   = ""
  scale            = var.ha-scale
  resource-configs = {
    ceph-osd-replication-count = var.ceph-osd-replication-count
  }
  mysql-router-channel = var.mysql-router-channel
}

# juju integrate cinder cinder-ceph
resource "juju_integration" "cinder-to-cinder-ceph" {
  model = juju_model.sunbeam.name

  application {
    name     = module.cinder.name
    endpoint = "storage-backend"
  }

  application {
    name     = module.cinder-ceph.name
    endpoint = "storage-backend"
  }
}

# juju integrate cinder-ceph microceph
resource "juju_integration" "cinder-ceph-to-ceph" {
  count = length(data.juju_offer.microceph)
  model = juju_model.sunbeam.name
  application {
    name     = module.cinder-ceph.name
    endpoint = "ceph"
  }
  application {
    offer_url = data.juju_offer.microceph[count.index].url
  }
}

resource "juju_offer" "ca-offer" {
  model            = juju_model.sunbeam.name
  application_name = juju_application.certificate-authority.name
  endpoint         = "certificates"
}
