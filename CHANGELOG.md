## v0.2.0:

* Make securable_type parameter to ms_permission LWRP optional.
* Avoid attempting to configure databases unless marked as managed and not one of the default
  sql server databases: model, master, msdb, tempdb.
* Change default behaviour of `ms_attribute_driven` recipe to not delete unmanaged elements
  unless explicit directed.
* Cache current sql server instance in `run_state` when processing `ms_attribute_driven` recipe.

## v0.1.0:

* Initial release
