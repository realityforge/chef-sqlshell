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
  from = ""
  options = []
  if new_resource.password
    options << "PASSWORD=N'#{new_resource.password}'"
  end
  options << "DEFAULT_DATABASE=[#{new_resource.default_database}]"
  options << "DEFAULT_LANGUAGE=[#{new_resource.default_language}]"
  if new_resource.password
    options << "CHECK_EXPIRATION=OFF"
    options << "CHECK_POLICY=OFF"
    types = ['SQL_LOGIN']
  else
    types = ['WINDOWS_GROUP','WINDOWS_LOGIN']
    from = 'FROM WINDOWS'
  end

  sqlshell_exec "CREATE LOGIN [#{new_resource.login}]" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "CREATE LOGIN [#{new_resource.login}] #{from} WITH #{options.join(', ')}"
    not_if_sql "SELECT * FROM sys.server_principals WHERE name = '#{new_resource.login}' AND type_desc IN (#{types.collect{|t| "'#{t}'"}.join(', ')})"
  end

  sqlshell_exec "ALTER LOGIN [#{new_resource.login}]" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "ALTER LOGIN [#{new_resource.login}] WITH #{options.join(', ')}"
    not_if_sql "SELECT * FROM sys.server_principals WHERE name = '#{new_resource.login}' AND default_database_name = '#{new_resource.default_database}' AND default_language_name = '#{new_resource.default_language}' AND type_desc IN (#{types.collect{|t| "'#{t}'"}.join(', ')})"
  end
end

action :drop do
  sqlshell_exec "DROP LOGIN [#{new_resource.login}]" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "DROP LOGIN [#{new_resource.login}]"
    only_if_sql "SELECT * FROM sys.server_principals WHERE name = N'#{new_resource.login}'"
  end
end
