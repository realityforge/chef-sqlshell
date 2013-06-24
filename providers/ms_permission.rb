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

def is_permission_present_sql(state)
  <<-SQL
      SELECT
        U.name, P.class_desc, P.permission_name, P.state_desc, O.name, S.name
      FROM
        sys.database_permissions P
      JOIN sys.database_principals U ON P.grantee_principal_id = U.principal_id AND U.type_desc IN ('SQL_USER','WINDOWS_USER','WINDOWS_GROUP')
      LEFT JOIN sys.all_objects O ON O.object_id = P.major_id
      LEFT JOIN sys.types T ON T.user_type_id = P.major_id
      LEFT JOIN sys.schemas S ON S.schema_id = COALESCE(O.schema_id,T.schema_id)
      WHERE
        U.name = '#{new_resource.user}' AND
        P.class_desc = '#{new_resource.securable_type_class_desc}' AND
        P.permission_name = '#{new_resource.permission}' AND
        #{state ? "P.state_desc = '#{state}' AND" : ''}
        COALESCE(O.name,T.name,'#{new_resource.database}') = '#{new_resource.securable_name}' AND
        COALESCE(S.name,'#{new_resource.database}') = '#{new_resource.securable_schema}'
  SQL
end

def action_sql(action)
  "#{action} #{new_resource.permission} ON #{new_resource.securable_type}::#{new_resource.quoted_securable} TO [#{new_resource.user}]"
end

action :grant do
  action = 'GRANT'
  sql = action_sql(action)
  sqlshell_exec sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{sql}"
    not_if_sql "USE [#{new_resource.database}]; #{is_permission_present_sql(action)}"
  end
end

action :deny do
  action = 'DENY'
  sql = action_sql(action)
  sqlshell_exec sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{sql}"
    not_if_sql "USE [#{new_resource.database}]; #{is_permission_present_sql(action)}"
  end
end

action :revoke do
  sql = action_sql('REVOKE')
  sqlshell_exec sql do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "USE [#{new_resource.database}]; #{sql}"
    only_if_sql "USE [#{new_resource.database}]; #{is_permission_present_sql(nil)}"
  end
end
