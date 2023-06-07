# Terraform manifest for deployment of OpenStack Sunbeam
#
# Copyright (c) 2023 Canonical Ltd.
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

output "ca-offer-url" {
  description = "URL of the certificates authority offer"
  value       = juju_offer.ca-offer.url
}

output "keystone-offer-url" {
  description = "URL of the keystone offer"
  value       = one(module.keystone.keystone-offer-url[*])
}

output "rabbitmq-offer-url" {
  description = "URL of the RabbitMQ offer"
  value       = module.rabbitmq.rabbitmq-offer-url
}

output "ovn-relay-offer-url" {
  description = "URL of the ovn relay offer"
  value       = one(module.ovn.ovn-relay-offer-url[*])
}
