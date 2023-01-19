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

variable "channel" {
  description = "Operator channel"
  default     = "22.03/edge"
  type        = string
}

variable "scale" {
  description = "Scale of OVN central application"
  type        = number
  default     = 1
}

variable "model" {
  description = "Juju model to deploy resources in"
  type        = string
}

variable "relay" {
  description = "Enable OVN relay"
  type        = bool
  default     = true
}

variable "relay_scale" {
  description = "Scale of OVN relay application"
  type        = number
  default     = 1
}

variable "ca" {
  description = "Application name of certificate authority operator"
  type        = string
  default     = ""
}
