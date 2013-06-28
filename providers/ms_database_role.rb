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

def database_role_present_sql
  <<SQL
SELECT
  U.name AS [user],
  R.name AS [role]
 FROM
  [#{new_resource.database}].sys.database_principals R
JOIN [#{new_resource.database}].sys.database_role_members RM ON RM.role_principal_id = R.principal_id
JOIN [#{new_resource.database}].sys.database_principals U ON RM.member_principal_id = U.principal_id
WHERE
  R.is_fixed_role = 1 AND
  U.name = '#{new_resource.user}' AND
  R.name = '#{new_resource.role}'
SQL
end

action :add do
  alter_role_sql = "EXEC sys.sp_addrolemember [#{new_resource.role}], [#{new_resource.user}]"
  sqlshell_exec alter_role_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{alter_role_sql}"
    not_if_sql database_role_present_sql
  end
end

action :remove do
  alter_role_sql = "EXEC sys.sp_droprolemember [#{new_resource.role}], [#{new_resource.user}]"
  sqlshell_exec alter_role_sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{alter_role_sql}"
    only_if_sql database_role_present_sql
  end
end
