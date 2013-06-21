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

def is_role_present_sql
  <<-SQL
      SELECT
        *
      FROM
        sys.server_principals P
      JOIN sys.server_role_members SRM ON SRM.member_principal_id = P.principal_id
      JOIN sys.server_principals RP ON RP.principal_id = SRM.role_principal_id AND RP.type_desc = 'SERVER_ROLE'
      WHERE P.name = N'#{new_resource.login}' AND RP.name = N'#{new_resource.role}'
  SQL
end


action :add do
  sqlshell_exec "ADD SERVER ROLE MEMBER '#{new_resource.login}', '#{new_resource.role}'" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "EXEC sys.sp_addsrvrolemember @loginame = N'#{new_resource.login}', @rolename = N'#{new_resource.role}'"
    not_if_sql is_role_present_sql
  end
end

action :remove do
  sqlshell_exec "REMOVE SERVER ROLE MEMBER '#{new_resource.login}', '#{new_resource.role}'" do
    jdbc_url new_resource.jdbc_url
    jdbc_driver new_resource.jdbc_driver
    extra_classpath new_resource.extra_classpath
    jdbc_properties new_resource.jdbc_properties
    command "EXEC sys.sp_dropsrvrolemember @loginame = N'#{new_resource.login}', @rolename = N'#{new_resource.role}'"
    only_if_sql is_role_present_sql
  end
end
