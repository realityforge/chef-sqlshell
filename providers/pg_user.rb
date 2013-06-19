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

def does_user_exist_sql
  "SELECT * FROM pg_user WHERE usename='#{new_resource.username}'"
end

action :create do
   sqlshell_exec "CREATE USER #{new_resource.username}" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "CREATE USER \"#{new_resource.username}\" WITH PASSWORD '#{new_resource.password}'"
    not_if_sql does_user_exist_sql
  end
end

action :drop do
   sqlshell_exec "CREATE USER #{new_resource.username}" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "DROP USER \"#{new_resource.username}\""
    only_if_sql does_user_exist_sql
  end
end
