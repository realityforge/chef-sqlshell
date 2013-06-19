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
Asadmin is the command line application used to manage a GlassFish application server. Typically this resource is
used when there is not yet a resource defined in this cookbook for executing an underlying command on the server.

@action run Execute the command.

@section Examples

    # List all the domains on the server
    sqlshell_exec "list-domains" do
       domain_name 'my_domain'
    end
#>
=end

actions :run

#<> @attribute command The sql command (s) to execute.
attribute :command, :kind_of => String, :required => true
#<> @attribute command_type The command type, a query or an update.
attribute :command_type, :equal_to => [:update, :query], :default => :update
#<> @attribute not_if_sql Do not execute command if specified sql returns 1 or more rows.
attribute :not_if_sql, :kind_of => [String, NilClass], :default => nil
#<> @attribute only_if_sql Only execute command if specified sql returns 1 or more rows.
attribute :only_if_sql, :kind_of => [String, NilClass], :default => nil

#<> @attribute jdbc_url The jdbc connection url.
attribute :jdbc_url, :kind_of => String, :required => true
#<> @attribute driver The class name of the jdbc driver.
attribute :driver, :kind_of => String, :required => true
#<> @attribute extra_classpath An array of urls to jars to add to the classpath.
attribute :extra_classpath, :kind_of => Array, :required => true
#<> @attribute properties A collection of jdbc connection properties.
attribute :properties, :kind_of => Hash, :default => {}

default_action :run
