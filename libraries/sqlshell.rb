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

class Chef
  module SqlShell

    def build_launch_command(input_file, extra_classpath)
      classpath = [node['sqlshell']['package']['local_archive']] + extra_classpath

      args = []
      args << '-cp' << classpath.join(::File::PATH_SEPARATOR)
      args << 'org.realityforge.sqlshell.Main'
      args << '--database-driver' << new_resource.jdbc_driver
      args << '-f' << input_file
      new_resource.jdbc_properties.each_pair do |key, value|
        args << '--database-property' << "#{key}=#{value}"
      end
      args << "\"#{new_resource.jdbc_url}\""

      java_exe =
        if node['platform'] == 'windows'
          "\"#{node['java']['java_home']}\\bin\\java.exe\""
        else
          "#{node['java']['java_home']}/bin/java"
        end

      "#{java_exe} #{args.join(' ')}"
    end

    def sql_to_json(sql, extra_classpath)
      f = Tempfile.new('sqlshell_exec', Chef::Config[:file_cache_path])
      f.write sql
      f.flush
      f.close
      begin
        cmd = shell_out!(build_launch_command(f.path, extra_classpath), {:returns => [0]})
        return JSON.parse(cmd.stdout)
      ensure
        f.unlink
      end
    end
  end
end
