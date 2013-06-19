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
Manage a user resource in postgres database.

@action create Create the user account.
@action drop Drop the user account.

@section Examples

    # Create a user
    sqlshell_pg_user "fred" do
      jdbc_url "jdbc:postgresql://127.0.0.1:5432/mydb"
      jdbc_driver 'org.postgresql.Driver'
      extra_classpath ['http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      password "secret"
    end
#>
=end

actions :create, :drop

#<> @attribute username The name of the user to create or drop.
attribute :username, :kind_of => String, :name_attribute => true
#<> @attribute password The password of the account if creating user.
attribute :password, :kind_of => [String, NilClass], :default => nil

#<> @attribute jdbc_url The jdbc connection url.
attribute :jdbc_url, :kind_of => String, :required => true
#<> @attribute jdbc_driver The class name of the jdbc driver.
attribute :jdbc_driver, :kind_of => String, :required => true
#<> @attribute extra_classpath An array of urls to jars to add to the classpath.
attribute :extra_classpath, :kind_of => Array, :required => true
#<> @attribute jdbc_properties A collection of jdbc connection properties.
attribute :jdbc_properties, :kind_of => Hash, :default => {}

default_action :create
