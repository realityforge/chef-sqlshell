#
# Copyright 2011, Peter Donald
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

include Chef::Mixin::ShellOut
include Chef::SqlShell

action :run do

  extra_classpath = []
  new_resource.extra_classpath.each do |classpath_element|
    if classpath_element =~ /^file\:\/\//
      extra_classpath << classpath_element[7, classpath_element.length]
    else
      local_classpath_element = "#{node.override['sqlshell']['lib']}/#{::File.basename(classpath_element)}"
      extra_classpath << local_classpath_element
      remote_file local_classpath_element do
        source classpath_element
        action :create_if_missing
      end
    end
  end

  ruby_block "execute_sql_#{new_resource.name}" do
    block do
      @sql_results = sql_to_json(new_resource.command, extra_classpath)
      if new_resource.block

          # So that we can refer to these within the sub-run-context block.
          cached_new_resource = new_resource
          cached_current_resource = current_resource

          # Setup a sub-run-context.
          sub_run_context = @run_context.dup
          sub_run_context.resource_collection = Chef::ResourceCollection.new

          # Declare sub-resources within the sub-run-context. Since they are declared here,
          # they do not pollute the parent run-context.
          begin
            original_run_context, @run_context = @run_context, sub_run_context

            p = Chef::Provider.new(new_resource, @run_context)
            p.instance_variable_set(:"@sql_results", @sql_results)
            p.instance_eval(&(new_resource.block))

          ensure
            @run_context = original_run_context
          end

          # Converge the sub-run-context inside the provider action.
          # Make sure to mark the resource as updated-by-last-action if any sub-run-context
          # resources were updated (any actual actions taken against the system) during the
          # sub-run-context convergence.
          begin
            Chef::Runner.new(sub_run_context).converge
          ensure
            if sub_run_context.resource_collection.any?(&:updated?)
              new_resource.updated_by_last_action(true)
            end
          end
      end
    end
    not_if do
      !sql_to_json(new_resource.not_if_sql, extra_classpath).empty? rescue false
    end if new_resource.not_if_sql

    only_if do
      !sql_to_json(new_resource.only_if_sql, extra_classpath).empty? rescue false
    end if new_resource.only_if_sql
  end
end
