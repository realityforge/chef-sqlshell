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
Manage a server role for a login resource in SQL Server.

@action add Add the server admin role.
@action remove Remove the server admin role.

@section Examples

    # Ensure fred has the server admin role
    sqlshell_ms_server_role "fred" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      role "sysadmin"
    end

#>
=end

actions :add, :remove

#<> @attribute login The name of the login to create or drop.
attribute :login, :kind_of => String, :name_attribute => true
#<> @attribute role The role to add or remove.
attribute :role, :equal_to => ['public','sysadmin','securityadmin','serveradmin','setupadmin','processadmin','diskadmin','dbcreator','bulkadmin'], :required => true

#<> @attribute jdbc_url The jdbc connection url.
attribute :jdbc_url, :kind_of => String, :required => true
#<> @attribute jdbc_driver The class name of the jdbc driver.
attribute :jdbc_driver, :kind_of => String, :required => true
#<> @attribute extra_classpath An array of urls to jars to add to the classpath.
attribute :extra_classpath, :kind_of => Array, :required => true
#<> @attribute jdbc_properties A collection of jdbc connection properties.
attribute :jdbc_properties, :kind_of => Hash, :default => {}

default_action :add
