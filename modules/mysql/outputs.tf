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

output "name" {
  description = "Map containing the name of the deployed MYSQL resource for specific service"
  # always outputs a map, even if there is only one mysql
  value       = zipmap(var.services, var.many-mysql ? juju_application.mysql[*].name : [for _ in var.services: juju_application.mysql[0].name])
}
