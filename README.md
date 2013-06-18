# Description

[![Build Status](https://secure.travis-ci.org/realityforge/chef-sqlshell.png?branch=master)](http://travis-ci.org/realityforge/chef-sqlshell)

The sqlshell cookbook installs the SqlShell binary and provides LWRPs to execute the tool.


# Requirements

## Platform:

* Ubuntu
* Windows

## Cookbooks:

* cutlery
* archive
* java

# Attributes

* `node['sqlshell']['package']['version']` - The version of SqlShell to install. Defaults to `0.1`.
* `node['sqlshell']['package']['url']` - The url to the omnibus SqlShell jar file. Defaults to `https://github.com/realityforge/repository/raw/master/org/realityforge/sqlshell/sqlshell/0.1/sqlshell-0.1-all.jar`.

# Recipes

* sqlshell::default - Installs the SqlShell binaries

# License and Maintainer

Maintainer:: Peter Donald (<peter@realityforge.org>)

License:: Apache 2.0
