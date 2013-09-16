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

def database_exist_sql
  "SELECT * FROM [#{new_resource.database}].sys.databases WHERE name = '#{new_resource.database}'"
end

action :create do
  create_user_sql = "CREATE DATABASE [#{new_resource.database}] COLLATE #{new_resource.collation}"
  sqlshell_exec create_user_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command create_user_sql
    not_if_sql database_exist_sql
  end

  update_recovery_sql = "ALTER DATABASE [#{new_resource.database}] SET RECOVERY #{new_resource.recovery_model} WITH NO_WAIT"
  sqlshell_exec update_recovery_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command update_recovery_sql
    not_if_sql <<-SQL
      SELECT name, recovery_model_desc
      FROM sys.databases
      WHERE name = '#{new_resource.database}' AND recovery_model_desc = '#{new_resource.recovery_model}'
    SQL
  end

  update_recovery_sql = "ALTER DATABASE [#{new_resource.database}] COLLATE #{new_resource.collation}"
  sqlshell_exec update_recovery_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command update_recovery_sql
    not_if_sql <<-SQL
      SELECT name, collation_name
      FROM sys.databases
      WHERE name = '#{new_resource.database}' AND collation_name = '#{new_resource.collation}'
    SQL
  end
end

action :drop do
  drop_database_sql = "DROP DATABASE [#{new_resource.database}]"
  sqlshell_exec drop_database_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "ALTER DATABASE [#{new_resource.database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; #{drop_database_sql}"
    only_if_sql database_exist_sql
  end
end
