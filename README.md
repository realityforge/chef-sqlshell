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

* `node['sqlshell']['package']['version']` - SqlShell Version: The version of SqlShell to install. Defaults to `version`.
* `node['sqlshell']['package']['url']` - SqlShell package url: The url to the omnibus SqlShell jar file. Defaults to `https://github.com/realityforge/repository/raw/master/org/realityforge/sqlshell/sqlshell/#{version}/sqlshell-#{version}-all.jar`.
* `node['sqlshell']['java']['min_memory']` -  Defaults to `16`.
* `node['sqlshell']['java']['max_memory']` -  Defaults to `40`.
* `node['sqlshell']['sql_server']['instances']` - Configuration for 0 or more sql server instances. Defaults to `Mash.new`.

# Recipes

* [sqlshell::default](#sqlshelldefault) - Installs the SqlShell binaries.
* [sqlshell::ms_attribute_driven](#sqlshellms_attribute_driven) - Configures 0 or more SQL Server instances using the sqlshell/sql_server/instances attribute.

## sqlshell::default

Installs the SqlShell binaries.

## sqlshell::ms_attribute_driven

Configures 0 or more SQL Server instances using the sqlshell/sql_server/instances attribute.

# Resources

* [sqlshell_exec](#sqlshell_exec) - Execute a sql command on the specified database.
* [sqlshell_ms_database](#sqlshell_ms_database) - Manage databases in in SQL Server.
* [sqlshell_ms_database_role](#sqlshell_ms_database_role) - Manage the membership of a database user in a role for a particular database.
* [sqlshell_ms_login](#sqlshell_ms_login) - Manage a login resource in SQL Server.
* [sqlshell_ms_permission](#sqlshell_ms_permission) - Manage permissions in in SQL Server.
* [sqlshell_ms_server_role](#sqlshell_ms_server_role) - Manage a server role for a login resource in SQL Server.
* [sqlshell_ms_user](#sqlshell_ms_user) - Manage a user resource in a database in SQL Server.
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

## sqlshell_ms_database

Manage databases in in SQL Server.

### Actions

- create: Create the database. Default action.
- drop: Drop the database.

### Attribute Parameters

- database: The database to create/drop.
- recovery_model: The recovery model of the database. Defaults to <code>"SIMPLE"</code>.
- collation: The collation of the database. Defaults to <code>"SQL_Latin1_General_CP1_CS_AS"</code>.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Create a database
    sqlshell_ms_database "ResourceDB" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'

      recovery_model "SIMPLE"
      collation 'SQL_Latin1_General_CP1_CS_AS'
    end

## sqlshell_ms_database_role

Manage the membership of a database user in a role for a particular database.

### Actions

- add: Create the database role membership. Default action.
- remove: Remove the database role membership.

### Attribute Parameters

- user: The name of the user.
- role: The associated role.
- database: The associated database.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Put fred in db_datareader role
    sqlshell_ms_database_role "fred in role db_datareader" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'

      user "fred"
      role "db_datareader"
      database "bigdb"
    end

## sqlshell_ms_login

Manage a login resource in SQL Server.

### Actions

- create: Create the login. Default action.
- drop: Drop the login.

### Attribute Parameters

- login: The name of the login to create or drop.
- password: The password of the account if creating user and creating a sql server login. Defaults to <code>nil</code>.
- default_database: The default database for the login. Defaults to <code>"master"</code>.
- default_language: The default language for the login. Defaults to <code>"us_english"</code>.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Create a sql server login
    sqlshell_ms_login "fred" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      password "secret"
    end

    # Create a domain login
    sqlshell_ms_login "MYDOMAIN\Fred" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
    end

    # Create a domain group login
    sqlshell_ms_login "MYDOMAIN\SQL Server Admins" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
    end

## sqlshell_ms_permission

Manage permissions in in SQL Server. Grant, deny and revoke permissions.

### Actions

- grant: Grant a permission. Default action.
- deny: Deny a permission.
- revoke: Revoke a previous grant or deny permission.

### Attribute Parameters

- user: The name of the user.
- database: The database in which to create the user.
- securable_type: The type of the securable.
- securable: The name of the securable element. Defaults to <code>nil</code>.
- permission: The type of the permission.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

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

## sqlshell_ms_server_role

Manage a server role for a login resource in SQL Server.

### Actions

- add: Add the server admin role. Default action.
- remove: Remove the server admin role.

### Attribute Parameters

- login: The name of the login to create or drop.
- role: The role to add or remove.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Ensure fred has the server admin role
    sqlshell_ms_server_role "fred" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      role "sysadmin"
    end

## sqlshell_ms_user

Manage a user resource in a database in SQL Server. The user is a mapping of a login to a particular database.

### Actions

- create: Create the user. Default action.
- drop: Drop the user.

### Attribute Parameters

- user: The name of the user.
- login: The login to associate with the user.
- database: The database in which to create the user.
- jdbc_url: The jdbc connection url.
- jdbc_driver: The class name of the jdbc driver.
- extra_classpath: An array of urls to jars to add to the classpath.
- jdbc_properties: A collection of jdbc connection properties. Defaults to <code>{}</code>.

### Examples

    # Create a sql server user
    sqlshell_ms_user "fred" do
      jdbc_url "jdbc:jtds:sqlserver://127.0.0.1:5432/mydb"
      jdbc_driver 'net.sourceforge.jtds.jdbc.Driver'
      extra_classpath ['http://repo1.maven.org/maven2/net/sourceforge/jtds/jtds/1.2.7/jtds-1.2.7.jar']
      jdbc_properties 'user' => 'sa', 'password' => 'secret'
      login "fred"
      database "bigdb"
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
