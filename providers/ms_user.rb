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

use_inline_resources

action :create do
  create_user_sql = "CREATE USER [#{new_resource.user}] FOR LOGIN [#{new_resource.login}]"
  sqlshell_exec create_user_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{create_user_sql}"
    not_if_sql "SELECT * FROM [#{new_resource.database}].sys.sysusers WHERE name = '#{new_resource.user}'"
  end
end

action :drop do
  sqlshell_exec "DROP USER [#{new_resource.user}]" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "DROP USER [#{new_resource.user}]"
    only_if_sql "SELECT * FROM [#{new_resource.database}].sys.sysusers WHERE name = '#{new_resource.user}'"
  end
end
