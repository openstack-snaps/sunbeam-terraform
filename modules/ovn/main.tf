# Terraform module for deployment of OVN
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

resource "juju_application" "ovn-central" {
  name  = "ovn-central"
  model = var.model

  charm {
    name    = "ovn-central-k8s"
    channel = var.channel
    series  = "jammy"
  }

  units = var.scale
}

resource "juju_application" "ovn-relay" {
  count = var.relay != "" ? 1 : 0
  name  = "ovn-relay"
  trust = true
  model = var.model

  charm {
    name    = "ovn-relay-k8s"
    channel = var.channel
    series  = "jammy"
  }

  units = var.relay-scale
}


resource "juju_integration" "ovn-central-to-ovn-relay" {
  count = var.relay != "" ? 1 : 0
  model = var.model

  application {
    name     = juju_application.ovn-central.name
    endpoint = "ovsdb-cms"
  }

  application {
    name     = juju_application.ovn-relay[0].name
    endpoint = "ovsdb-cms"
  }
}

resource "juju_integration" "ovn-central-to-ca" {
  model = var.model

  application {
    name     = juju_application.ovn-central.name
    endpoint = "certificates"
  }

  application {
    name     = var.ca
    endpoint = "certificates"
  }
}

resource "juju_integration" "ovn-relay-to-ca" {
  count = var.relay != "" ? 1 : 0
  model = var.model

  application {
    name     = juju_application.ovn-relay[0].name
    endpoint = "certificates"
  }

  application {
    name     = var.ca
    endpoint = "certificates"
  }
}

resource "juju_offer" "ovn-relay-offer" {
  count            = var.relay != "" ? 1 : 0
  model            = var.model
  application_name = juju_application.ovn-relay[count.index].name
  endpoint         = "ovsdb-cms-relay"
}
