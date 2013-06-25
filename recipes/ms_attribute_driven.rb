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

include_recipe 'sqlshell::default'

node['sqlshell']['servers'].each_pair do |key, value|
  server_prefix = "sqlshell.servers.#{key}"
  jdbc_url = Chef::AttributeChecker.ensure_attribute(value, 'jdbc.url', String, server_prefix)
  jdbc_driver = Chef::AttributeChecker.ensure_attribute(value, 'jdbc.driver', String, server_prefix)
  extra_classpath = Chef::AttributeChecker.ensure_attribute(value, 'jdbc.extra_classpath', Array, server_prefix)
  jdbc_properties = Chef::AttributeChecker.ensure_attribute(value, 'jdbc.properties', Hash, server_prefix)

  if value['logins']
    value['logins'].each_pair do |login, login_config|
      sqlshell_ms_login login do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties

        default_database login_config['default_database'] if login_config['default_database']
        default_language login_config['default_language'] if login_config['default_language']
        password login_config['password'] if login_config['password']
      end

      if value['server_roles']
        value['server_roles'].each_pair do |role, config|
          sqlshell_ms_server_role login do
            jdbc_url jdbc_url
            jdbc_driver jdbc_driver
            extra_classpath extra_classpath
            jdbc_properties jdbc_properties
            role role
          end
        end
      end
    end
  end

  if value['databases']
    value['databases'].each_pair do |database_name, database_config|
      database_prefix = "#{server_prefix}.databases.#{database_name}"
      if database_config['users']
        database_config['users'].each_pair do |user, user_config|
          user_prefix = "#{database_prefix}.users.#{user}"

          sqlshell_ms_user user do
            jdbc_url jdbc_url
            jdbc_driver jdbc_driver
            extra_classpath extra_classpath
            jdbc_properties jdbc_properties
            login Chef::AttributeChecker.ensure_attribute(user_config, 'login', String, user_prefix)
            database database_name
          end

          if user_config['permissions']
            user_config['permissions'].each_pair do |permission_key, permission_config|
              permission_prefix = "#{user_prefix}.permissions.#{permission_key}"
              permission = Chef::AttributeChecker.ensure_attribute(permission_config, 'permission', String, permission_prefix)
              securable_type = Chef::AttributeChecker.ensure_attribute(permission_config, 'securable_type', String, permission_prefix)
              securable = permission_config['securable'] ? Chef::AttributeChecker.ensure_attribute(permission_config, 'securable', String, permission_prefix) : nil
              permission_action = permission_config['permission_action'] ? Chef::AttributeChecker.ensure_attribute(permission_config, 'permission_action', String, permission_prefix) : nil

              sqlshell_ms_permission "#{permission_action} #{permission} TO #{user} ON #{securable_type}::#{securable || database_name}" do
                jdbc_url jdbc_url
                jdbc_driver jdbc_driver
                extra_classpath extra_classpath
                jdbc_properties jdbc_properties
                user user
                database database_name
                securable_type securable_type
                securable securable
                permission permission
                action permission_action.to_sym if permission_action
              end
            end
          end
        end
      end

      if value['logins']

        sqlshell_exec "Remove historic Server Roles" do
          jdbc_url jdbc_url
          jdbc_driver jdbc_driver
          extra_classpath extra_classpath
          jdbc_properties jdbc_properties
          command <<-SQL
              SELECT
                P.name, RP.name as role
              FROM
                sys.server_principals P
              JOIN sys.server_role_members SRM ON SRM.member_principal_id = P.principal_id
              JOIN sys.server_principals RP ON RP.principal_id = SRM.role_principal_id AND RP.type_desc = 'SERVER_ROLE'
              WHERE
                P.is_disabled = 0 AND
                P.name NOT LIKE 'NT AUTHORITY\\%' AND
                P.name NOT LIKE 'NT SERVICE\\%' AND
                P.type_desc IN ('SQL_LOGIN', 'WINDOWS_GROUP', 'WINDOWS_LOGIN')
          SQL
          block do
            logins_with_roles = []
            role_map = {}
            value['logins'].each_pair do |login, login_config|
              if login_config['server_roles']
                logins_with_roles << login
                role_map[login] = (role_map[login] || []) + login_config['server_roles'].keys
              end
            end

            @sql_results.each do |row|
              next if row['name'] == jdbc_properties['user']

              login = row['name']
              role = row['role']

              if !logins_with_roles.include?(login) || !(role_map[login] && role_map[login].include?(role))

                Chef::Log.info "Removing historic server role #{role} from #{login}"
                sqlshell_ms_server_role login do
                  jdbc_url jdbc_url
                  jdbc_driver jdbc_driver
                  extra_classpath extra_classpath
                  jdbc_properties jdbc_properties
                  role role

                  action :remove
                end
              end
            end
          end
        end

        sqlshell_exec "Remove historic logins" do
          jdbc_url jdbc_url
          jdbc_driver jdbc_driver
          extra_classpath extra_classpath
          jdbc_properties jdbc_properties
          command <<-SQL
            SELECT
              SP.name, SP.type_desc
            FROM
              sys.syslogins L
            JOIN sys.server_principals SP ON SP.sid = L.sid
            WHERE
              SP.type_desc IN ('SQL_LOGIN', 'WINDOWS_GROUP', 'WINDOWS_LOGIN') AND
              SP.is_disabled = 0 AND
              SP.name NOT LIKE 'NT AUTHORITY\\%' AND
              SP.name NOT LIKE 'NT SERVICE\\%'
          SQL
          block do
            @sql_results.each do |row|
              if value['logins'][row['name']].nil? && row['name'] != jdbc_properties['user']
                Chef::Log.info "Removing historic login #{row['name']}"
                sqlshell_ms_login row['name'] do
                  jdbc_url jdbc_url
                  jdbc_driver jdbc_driver
                  extra_classpath extra_classpath
                  jdbc_properties jdbc_properties

                  action :drop
                end
              end
            end
          end
        end
      end
    end
  end
end
