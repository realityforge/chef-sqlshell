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

name             'sqlshell'
maintainer       'Peter Donald'
maintainer_email 'peter@realityforge.org'
license          'Apache 2.0'
description      'Cookbook that provides LWRPs for automating the contents of a database.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'ubuntu'
supports 'windows'

depends 'cutlery'
depends 'archive'
depends 'java'

recipe 'sqlshell::default', 'Installs the SqlShell binaries'

attribute 'sqlshell/package/version',
  :display_name => 'SqlShell Version',
  :description => 'The version of SqlShell to install',
  :type => 'string',
  :default => '0.1'

attribute 'sqlshell/package/url',
  :display_name => 'SqlShell package url',
  :description => 'The url to the omnibus SqlShell jar file',
  :type => 'string',
  :default => 'https://github.com/realityforge/repository/raw/master/org/realityforge/sqlshell/sqlshell/0.1/sqlshell-0.1-all.jar'
