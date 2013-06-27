#
# Copyright Peter Donald
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
Manage permissions in in SQL Server. Grant, deny and revoke permissions.

@action grant Grant a permission.
@action deny Deny a permission.
@action revoke Revoke a previous grant or deny permission.

@section Examples

    # Grant fred the ability to select in a database
    sqlshell_ms_permission "Allow fred to perform SELECTs in database" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'

      user "fred"
      database "bigdb"
      securable_type 'DATABASE'
      permission 'SELECT'
      action :grant
    end

    # Deny fred the ability to select from a table
    sqlshell_ms_permission "Deny fred the ability to perform SELECTs on table" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'

      user "fred"
      database "bigdb"
      securable_type 'OBJECT_OR_COLUMN'
      permission 'SELECT'
      action :deny
    end


    # Revoke the deny
    sqlshell_ms_permission "Revoke the deny" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'

      user "fred"
      database "bigdb"
      securable_type 'OBJECT_OR_COLUMN'
      permission 'SELECT'
      action :revoke
    end
#>
=end

actions :grant, :deny, :revoke

#<> @attribute user The name of the user.
attribute :user, :kind_of => String, :required => true
#<> @attribute database The database in which to create the user.
attribute :database, :kind_of => String, :required => true
#<> @attribute securable_type The type of the securable.
attribute :securable_type, :equal_to => ['DATABASE','OBJECT','TYPE'], :required => true
#<> @attribute securable The name of the securable element.
attribute :securable, :kind_of => [String, NilClass], :default => nil
#<> @attribute permission The type of the permission.
attribute :permission,
          :equal_to =>
            [
              'BACKUP DATABASE', 'BACKUP LOG', 'CREATE DATABASE', 'CREATE DEFAULT', 'CREATE FUNCTION',
              'CREATE PROCEDURE', 'CREATE RULE', 'CREATE TABLE', 'CREATE VIEW',
              'EXECUTE', 'REFERENCES', 'DELETE', 'INSERT', 'UPDATE', 'SELECT', 'CONNECT'
            ],
          :required => true

#<> @attribute jdbc_url The jdbc connection url.
attribute :jdbc_url, :kind_of => String, :required => true
#<> @attribute jdbc_driver The class name of the jdbc driver.
attribute :jdbc_driver, :kind_of => String, :required => true
#<> @attribute extra_classpath An array of urls to jars to add to the classpath.
attribute :extra_classpath, :kind_of => Array, :required => true
#<> @attribute jdbc_properties A collection of jdbc connection properties.
attribute :jdbc_properties, :kind_of => Hash, :default => {}

default_action :grant

def resolved_securable
  unless @resolved_securable
    if securable_type == 'DATABASE'
      raise "Must not specify securable if securable_type is DATABASE" if securable
      @resolved_securable = [database, database]
    else
      raise "Must specify securable if securable_type is not DATABASE" unless securable
      @resolved_securable = securable.dup.gsub('[','').gsub(']','').split('.')
      @resolved_securable = ['dbo'] + @resolved_securable if @resolved_securable.size == 1
    end
  end
  @resolved_securable
end

def quoted_securable
  securable_type == 'DATABASE' ? "[#{securable_name}]" : "[#{securable_schema}].[#{securable_name}]"
end

def securable_name
  resolved_securable[1]
end

def securable_schema
  resolved_securable[0]
end

def securable_type_class_desc
  securable_type == 'OBJECT' ? 'OBJECT_OR_COLUMN' : securable_type
end
