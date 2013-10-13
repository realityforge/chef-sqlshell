#
# Copyright Peter Donald
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

version = '0.6'
#<> SqlShell Version: The version of SqlShell to install.
default['sqlshell']['package']['version'] = version
#<> SqlShell package url: The url to the omnibus SqlShell jar file.
default['sqlshell']['package']['url'] = "https://github.com/realityforge/repository/raw/master/org/realityforge/sqlshell/sqlshell/#{version}/sqlshell-#{version}-all.jar"
default['sqlshell']['java']['min_memory'] = 16
default['sqlshell']['java']['max_memory'] = 40

#<> Configuration for 0 or more sql server instances
default['sqlshell']['sql_server']['instances'] = Mash.new
