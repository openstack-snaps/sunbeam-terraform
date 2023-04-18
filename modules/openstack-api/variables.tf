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

variable "name" {
  description = "Name of the deployed operator"
  type        = string
}

variable "channel" {
  description = "Operator channel"
  default     = "latest/edge"
  type        = string
}

variable "scale" {
  description = "Scale of application"
  type        = number
  default     = 1
}

variable "charm" {
  description = "Charmed operator to deploy"
  type        = string
}

variable "model" {
  description = "Juju model to deploy resources in"
  type        = string
}

variable "rabbitmq" {
  description = "RabbitMQ operator to integrate with"
  type        = string
  default     = ""
}

variable "mysql" {
  description = "MySQL operator to integrate with"
  type        = string
}

variable "mysql_router_channel" {
  description = "Operator channel for MySQL Router deployment"
  default     = "8.0/edge"
}

variable "keystone" {
  description = "Keystone operator to integrate with"
  type        = string
  default     = ""
}

variable "keystone-credentials" {
  description = "Keystone operator to integrate with"
  type        = string
  default     = ""
}

variable "ingress-internal" {
  description = "Ingress operator to integrate with for internal endpoints"
  type        = string
}

variable "ingress-public" {
  description = "Ingress operator to integrate with for public endpoints"
  type        = string
}
