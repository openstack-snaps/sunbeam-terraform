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
  description = "Name of the deployed MySQL K8S operator"
  default     = "mysql"
  type        = string
}

variable "channel" {
  description = "MySQL K8S operator channel"
  default     = "8.0/stable"
  type        = string
}

variable "constraints" {
  description = "Constraints for MySQL charm"
  default     = "mem=2048"
  type        = string
}

variable "scale" {
  description = "Scale of MySQL K8S operator"
  default     = 1
}

variable "model" {
  description = "Juju model to deploy resources in"
}
