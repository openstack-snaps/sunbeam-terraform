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

variable "openstack-channel" {
  description = "Operator channel for OpenStack deployment"
  default     = "2023.1/stable"
}

variable "mysql-channel" {
  description = "Operator channel for MySQL deployment"
  default     = "8.0/candidate"
}

variable "mysql-router-channel" {
  description = "Operator channel for MySQL router deployment"
  default     = "8.0/candidate"
  type        = string
}

variable "rabbitmq-channel" {
  description = "Operator channel for RabbitMQ deployment"
  default     = "3.9/stable"
}

variable "ovn-channel" {
  description = "Operator channel for OVN deployment"
  default     = "23.03/stable"
}

variable "model" {
  description = "Name of Juju model to use for deployment"
  default     = "openstack"
}

variable "cloud" {
  description = "Name of K8S cloud to use for deployment"
  default     = "microk8s"
}

# https://github.com/juju/terraform-provider-juju/issues/147
variable "credential" {
  description = "Name of credential to use for deployment"
  default     = ""
}

variable "config" {
  description = "Set configuration on model"
  default     = {}
}

variable "enable-ceph" {
  description = "Enable Ceph integration"
  default     = false
}

variable "ceph-offer-url" {
  description = "Offer URL from microceph app"
  default     = "admin/controller.microceph"
}

variable "ceph-osd-replication-count" {
  description = "Ceph OSD replication count to set on glance/cinder"
  default     = 1
}

variable "ha-scale" {
  description = "Scale of traditional HA deployments"
  # Need better name, because 1 is not HA, needs to encompass services like MySQL, RabbitMQ and OVN
  default = 1
}

variable "os-api-scale" {
  description = "Scale of OpenStack API service deployments"
  default     = 1
}

variable "ingress-scale" {
  description = "Scale of ingress deployment"
  default     = 1
}

variable "many-mysql" {
  description = "Enabling this will switch architecture from one global mysql to one per service"
  default     = false
}

variable "enable-heat" {
  description = "Enable OpenStack Heat service"
  default     = false
}
