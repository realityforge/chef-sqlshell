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

# Resources

* [sqlshell_exec](#sqlshell_exec) - Execute a sql command on the specified database.
* [sqlshell_pg_user](#sqlshell_pg_user) - Manage a user resource in postgres database.

## sqlshell_exec

Execute a sql command on the specified database. Typically this is used as an atomic component
from which the other database automation elements are driven.

### Actions

- run: Execute the command. Default action.

### Attribute Parameters

- command: The sql command (s) to execute.
- not_if_sql: Do not execute command if specified sql returns 1 or more rows. Defaults to <code>nil</code>.
- only_if_sql: Only execute command if specified sql returns 1 or more rows. Defaults to <code>nil</code>.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Create a schema if it does not exist
    sqlshell_exec "CREATE SCHEMA c" do
      jdbc_url "jdbc:postgresql://127.0.0.1:5432/mydb"
      jdbc_driver 'org.postgresql.Driver'
      extra_classpath ['http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      command "CREATE SCHEMA c"
      not_if_sql "SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'c'"
    end

## sqlshell_pg_user

Manage a user resource in postgres database.

### Actions

- create: Create the user account. Default action.
- drop: Drop the user account.

### Attribute Parameters

- username: The name of the user to create or drop.
- password: The password of the account if creating user. Defaults to <code>nil</code>.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Create a user
    sqlshell_pg_user "fred" do
      jdbc_url "jdbc:postgresql://127.0.0.1:5432/mydb"
      jdbc_driver 'org.postgresql.Driver'
      extra_classpath ['http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      password "secret"
    end

# License and Maintainer

Maintainer:: Peter Donald (<peter@realityforge.org>)

License:: Apache 2.0
