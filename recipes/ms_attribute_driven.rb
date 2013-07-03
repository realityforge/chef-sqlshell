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

node['sqlshell']['sql_server']['instances'].each_pair do |instance_key, value|
  server_prefix = "sqlshell.sql_server.instances.#{instance_key}"
  jdbc_url = RealityForge::AttributeTools.ensure_attribute(value, 'jdbc.url', String, server_prefix)
  jdbc_driver = RealityForge::AttributeTools.ensure_attribute(value, 'jdbc.driver', String, server_prefix)
  extra_classpath = RealityForge::AttributeTools.ensure_attribute(value, 'jdbc.extra_classpath', Array, server_prefix)
  jdbc_properties = RealityForge::AttributeTools.ensure_attribute(value, 'jdbc.properties', Hash, server_prefix)

  delete_unmanaged_permissions = !value['delete_unmanaged_permissions'].is_a?(FalseClass)
  delete_unmanaged_database_roles = !value['delete_unmanaged_database_roles'].is_a?(FalseClass)
  delete_unmanaged_users = !value['delete_unmanaged_users'].is_a?(FalseClass)
  delete_unmanaged_server_roles = !value['delete_unmanaged_server_roles'].is_a?(FalseClass)
  delete_unmanaged_logins = !value['delete_unmanaged_logins'].is_a?(FalseClass)
  delete_unmanaged_databases = value['delete_unmanaged_databases'].is_a?(TrueClass)

  if value['logins']
    value['logins'].each_pair do |login, login_config|
      sqlshell_ms_login "#{instance_key}-#{login}" do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties

        login login
        default_database login_config['default_database'] if login_config['default_database']
        default_language login_config['default_language'] if login_config['default_language']
        password login_config['password'] if login_config['password']
      end

      if login_config['server_roles']
        login_config['server_roles'].each_pair do |role, config|
          sqlshell_ms_server_role "#{instance_key}-#{login}-#{role}" do
            jdbc_url jdbc_url
            jdbc_driver jdbc_driver
            extra_classpath extra_classpath
            jdbc_properties jdbc_properties
            login login
            role role
          end
        end
      end
    end
  end

  if value['databases']
    value['databases'].each_pair do |database_name, database_config|
      database_prefix = "#{server_prefix}.databases.#{database_name}"

      is_database_managed = database_config['managed'].nil? ? true : database_config['managed']

      sqlshell_ms_database "#{instance_key}-#{database_name}" do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties

        database database_name

        recovery_model database_config['recovery_model'] if database_config['recovery_model']
        collation database_config['collation'] if database_config['collation']
      end unless ['master','msdb','model','tempdb'].include?(database_name)

      if database_config['users']
        database_config['users'].each_pair do |user, user_config|
          user_prefix = "#{database_prefix}.users.#{user}"

          sqlshell_ms_user "#{instance_key}-#{database_name}-#{user}" do
            jdbc_url jdbc_url
            jdbc_driver jdbc_driver
            extra_classpath extra_classpath
            jdbc_properties jdbc_properties
            login RealityForge::AttributeTools.ensure_attribute(user_config, 'login', String, user_prefix)
            database database_name
            user user
          end

          if user_config['database_roles']
            user_config['database_roles'].each_pair do |database_role, role_config|
              sqlshell_ms_database_role "#{instance_key}-ADD '#{user}' to role '#{database_role}' in '#{database_name}'" do
                jdbc_url jdbc_url
                jdbc_driver jdbc_driver
                extra_classpath extra_classpath
                jdbc_properties jdbc_properties
                user user
                database database_name
                role database_role
              end
            end
          end

          if user_config['permissions']
            user_config['permissions'].each_pair do |permission_key, permission_config|
              permission_prefix = "#{user_prefix}.permissions.#{permission_key}"
              permission = RealityForge::AttributeTools.ensure_attribute(permission_config, 'permission', String, permission_prefix)
              securable_type = RealityForge::AttributeTools.ensure_attribute(permission_config, 'securable_type', String, permission_prefix)
              securable = permission_config['securable'] ? RealityForge::AttributeTools.ensure_attribute(permission_config, 'securable', String, permission_prefix) : nil
              permission_action = permission_config['permission_action'] ? RealityForge::AttributeTools.ensure_attribute(permission_config, 'permission_action', String, permission_prefix) : nil

              sqlshell_ms_permission "#{instance_key}-#{database_name}-#{permission_action} #{permission} TO #{user} ON #{securable_type}::#{securable || database_name}" do
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

      sqlshell_exec "#{instance_key}-Remove historic permissions in #{database_name}" do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties
        command <<-SQL
          USE [#{database_name}];
          SELECT
            U.name AS [user],
            P.class_desc AS securable_type,
            P.permission_name AS permission,
            P.state_desc as permission_action,
            COALESCE(O.name,T.name) AS securable_name,
            S.name AS securable_schema
          FROM
            sys.database_permissions P
          JOIN sys.database_principals U ON P.grantee_principal_id = U.principal_id AND U.type_desc IN ('SQL_USER','WINDOWS_USER','WINDOWS_GROUP')
          JOIN sys.server_principals SP ON SP.sid = U.sid AND SP.is_disabled = 0 AND SP.name NOT LIKE 'NT AUTHORITY\\%' AND SP.name NOT LIKE 'NT SERVICE\\%'
          LEFT JOIN sys.all_objects O ON O.object_id = P.major_id
          LEFT JOIN sys.types T ON T.user_type_id = P.major_id
          LEFT JOIN sys.schemas S ON S.schema_id = COALESCE(O.schema_id,T.schema_id)
          WHERE
            P.class_desc IN ('DATABASE','TYPE','OBJECT_OR_COLUMN') AND
            U.name != 'dbo'
        SQL
        block do
          permissions = []
          database_config['users'].each_pair do |user, user_config|
            if user_config['permissions']
              user_config['permissions'].values.each do |permission_config|
                permission_action = (permission_config['permission_action'] || 'grant').upcase
                securable_type = permission_config['securable_type'] == 'OBJECT' ? 'OBJECT_OR_COLUMN' : permission_config['securable_type']
                permission = permission_config['permission']
                securable = permission_config['securable'] ? permission_config['securable'].gsub('[','').gsub(']','') : database_name
                permissions << "#{user}-#{permission}-#{securable_type}-#{securable}-#{permission_action}".downcase
              end
            end
          end

          @sql_results.each do |row|
            user = row['user']
            permission = row['permission']
            securable_type = row['securable_type']
            securable = row['securable_schema'] ? "#{row['securable_schema']}.#{row['securable_name']}" : row['securable_name']
            permission_action = row['permission_action']

            permission_description = "#{user}-#{permission}-#{securable_type}-#{securable || database_name}-#{permission_action}".downcase

            if !permissions.include?(permission_description)
              if is_database_managed && delete_unmanaged_permissions
                Chef::Log.info "Removing historic permission #{permission_action} #{permission} TO #{user} ON #{securable_type}::#{securable || database_name}"

                sqlshell_ms_permission "#{instance_key}-Revoking ... #{permission_action} #{permission} TO #{user} ON #{securable_type}::#{securable || database_name}" do
                  jdbc_url jdbc_url
                  jdbc_driver jdbc_driver
                  extra_classpath extra_classpath
                  jdbc_properties jdbc_properties
                  user user
                  database database_name
                  securable_type(securable_type == 'OBJECT_OR_COLUMN' ? 'OBJECT' : securable_type)
                  securable securable
                  permission permission
                  action :revoke
                end
              else
                Chef::Log.error "Unmanaged permission '#{permission_action} #{permission} TO #{user} ON #{securable_type}::#{securable || database_name}' found"
              end
            end
          end
        end
      end

      sqlshell_exec "#{instance_key}-Remove historic database roles in #{database_name}" do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties
        command <<-SQL
          USE [#{database_name}];
          SELECT
            U.name AS [user],
            R.name AS [role]
           FROM
            sys.database_principals R
          JOIN sys.database_role_members RM ON RM.role_principal_id = R.principal_id
          JOIN sys.database_principals U ON RM.member_principal_id = U.principal_id
          WHERE
            R.is_fixed_role = 1 AND
            U.name != 'dbo'
        SQL
        block do
          role_map = {}
          database_config['users'].each_pair do |user, user_config|
            role_map[user] = user_config['database_roles'] ? user_config['database_roles'].keys : []
          end

          @sql_results.each do |row|
            user = row['user']
            database_role = row['role']

            if !role_map[user] || !role_map[user].include?(database_role)
              if is_database_managed && delete_unmanaged_database_roles
                Chef::Log.info "Removing historic database role '#{database_role}' from user '#{user}' in database ''#{database_name}''"

                sqlshell_ms_database_role "#{instance_key}-Remove '#{user}' from role '#{database_role}' in '#{database_name}'" do
                  jdbc_url jdbc_url
                  jdbc_driver jdbc_driver
                  extra_classpath extra_classpath
                  jdbc_properties jdbc_properties
                  user user
                  database database_name
                  role database_role
                  action :remove
                end
              else
                Chef::Log.error "Unmanaged database role '#{database_role} for #{user} in #{database_name}' found"
              end
            end
          end
        end
      end

      sqlshell_exec "#{instance_key}-Remove historic users in #{database_name}" do
        jdbc_url jdbc_url
        jdbc_driver jdbc_driver
        extra_classpath extra_classpath
        jdbc_properties jdbc_properties
        command <<-SQL
          USE [#{database_name}];
          SELECT
            U.name AS [user]
          FROM
            sys.database_principals U
          JOIN sys.server_principals SP ON SP.sid = U.sid AND SP.is_disabled = 0 AND SP.name NOT LIKE 'NT AUTHORITY\\%' AND SP.name NOT LIKE 'NT SERVICE\\%'
          WHERE
            U.name != 'dbo' AND
            U.type_desc IN ('SQL_USER','WINDOWS_USER','WINDOWS_GROUP')
        SQL
        block do
          @sql_results.each do |row|
            user = row['user']

            if database_config['users'][user]
              if is_database_managed && delete_unmanaged_users
                Chef::Log.info "Removing historic user #{user} in #{database_name}"

                sqlshell_ms_user "#{instance_key}-#{database_name}-#{user}" do
                  jdbc_url jdbc_url
                  jdbc_driver jdbc_driver
                  extra_classpath extra_classpath
                  jdbc_properties jdbc_properties
                  database database_name
                  user user

                  action :drop
                end
              else
                Chef::Log.error "Unmanaged user '#{user}' in '#{database_name}' found"
              end
            end
          end
        end
      end
    end
  end

  if value['logins']
    sqlshell_exec "Remove historic Server Roles on instance #{instance_key}" do
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
            if delete_unmanaged_server_roles
              Chef::Log.info "#{instance_key}-Removing historic server role #{role} from #{login}"
              sqlshell_ms_server_role login do
                jdbc_url jdbc_url
                jdbc_driver jdbc_driver
                extra_classpath extra_classpath
                jdbc_properties jdbc_properties
                role role

                action :remove
              end
            else
              Chef::Log.error "Unmanaged server role #{role} from #{login} found"
            end
          end
        end
      end
    end

    sqlshell_exec "Remove historic logins on instance #{instance_key}" do
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
          login = row['name']
          if value['logins'][login].nil? && login != jdbc_properties['user']
            if delete_unmanaged_logins
              Chef::Log.info "#{instance_key}-Removing historic login #{login}"
              sqlshell_ms_login "##{instance_key}-#{login}" do
                jdbc_url jdbc_url
                jdbc_driver jdbc_driver
                extra_classpath extra_classpath
                jdbc_properties jdbc_properties

                login login

                action :drop
              end
            else
              Chef::Log.error "Unmanaged login #{login} found"
            end
          end
        end
      end
    end

    sqlshell_exec "Remove historic databases on instance #{instance_key}" do
      jdbc_url jdbc_url
      jdbc_driver jdbc_driver
      extra_classpath extra_classpath
      jdbc_properties jdbc_properties
      command <<-SQL
        SELECT name
        FROM sys.databases
        WHERE name NOT IN ('master','model','msdb','tempdb')
      SQL
      block do
        @sql_results.each do |row|
          database_name = row['name']
          if value['databases'][database_name].nil?
            if delete_unmanaged_databases
              Chef::Log.info "Removing historic database #{database_name}"
              sqlshell_ms_database "#{instance_key}-#{database_name}" do
                jdbc_url jdbc_url
                jdbc_driver jdbc_driver
                extra_classpath extra_classpath
                jdbc_properties jdbc_properties

                database database_name

                action :drop
              end
            else
              Chef::Log.error "Unmanaged database named '#{database_name}' found"
            end
          end
        end
      end
    end
  end
end
