#
# Copyright 2012, Peter Donald
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

=begin
#<
Installs the SqlShell binaries.
#>
=end

include_recipe 'java::default'

a = archive 'sqlshell' do
  url node['sqlshell']['package']['url']
  version node['sqlshell']['package']['version']
end

node.override['sqlshell']['base_directory'] = a.base_directory
node.override['sqlshell']['lib'] = "#{a.base_directory}/lib"

directory node['sqlshell']['lib']

node.override['sqlshell']['package']['local_archive'] = a.target_artifact
