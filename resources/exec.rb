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
Execute a sql command on the specified database. Typically this is used as an atomic component
from which the other database automation elements are driven.

@action run Execute the command.

@section Examples

    # Create a schema if it does not exist
    sqlshell_exec "CREATE SCHEMA c" do
      jdbc_url "jdbc:postgresql://127.0.0.1:5432/mydb"
      jdbc_driver 'org.postgresql.Driver'
      extra_classpath ['http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      command "CREATE SCHEMA c"
      not_if_sql "SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'c'"
    end
#>
=end

actions :run

#<> @attribute command The sql command (s) to execute.
attribute :command, :kind_of => String, :required => true
#<> @attribute not_if_sql Do not execute command if specified sql returns 1 or more rows.
attribute :not_if_sql, :kind_of => [String, NilClass], :default => nil
#<> @attribute only_if_sql Only execute command if specified sql returns 1 or more rows.
attribute :only_if_sql, :kind_of => [String, NilClass], :default => nil

#<> @attribute jdbc_url The jdbc connection url.
attribute :jdbc_url, :kind_of => String, :required => true
#<> @attribute jdbc_driver The class name of the jdbc driver.
attribute :jdbc_driver, :kind_of => String, :required => true
#<> @attribute extra_classpath An array of urls to jars to add to the classpath.
attribute :extra_classpath, :kind_of => Array, :required => true
#<> @attribute jdbc_properties A collection of jdbc connection properties.
attribute :jdbc_properties, :kind_of => Hash, :default => {}

default_action :run
