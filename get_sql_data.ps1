# $Id: get_sql_data.ps1,v 1.1 2012/01/12 01:12:38 powem Exp $
# Assembled and modified by M. Powe
# Last Modified:  $Date: 2012/01/12 01:12:38 $

function Get-Data{
<#
 .Synopsis
  Send a SQL query to a database and return the resultset to stdout.
 
 .Description
  A simple database request to retrieve data.  Intended for use with SELECT.
  
 .Parameter server
  The server to connect to.  The local system by default.
  
 .Parameter instance
  The database to connect to. WTSYSTEMDB by default.
  
 .Parameter query
  The SQL statement to be executed. This should be a data retrieval statement.
  
 .Return
  The resultset to stdout.
  
 .Notes
  Originally taken from a web forum.
#>
	param (
	    [string]$server = ".",
	      [string]$instance = "WTSYSTEMDB",
	    [string]$query
	)

	$connection = new-object system.data.sqlclient.sqlconnection( `
	    "Data Source=$server;Initial Catalog=$instance;Integrated Security=SSPI;");

	$adapter = new-object system.data.sqlclient.sqldataadapter ($query, $connection)
	$set = new-object system.data.dataset

	$adapter.Fill($set)

	$table = new-object system.data.datatable
	$table = $set.Tables[0]
	 
	#return table
	$table
}

# SqlQuery.psm1
#
# Functions for getting data from a SQL Server.


[string]$DEFAULT_SQL_SERVER = 'sqlserver'
[string]$DEFAULT_SQL_DB = 'SQLDB'


function Run-SqlSelect {
<#
 .Synopsis 
  Execute a SQL query against a database.
  
 .Description
  Takes a select string and runs it against a given database and server.
  
 .Parameter SqlServer
  A server to connect to.
  
 .Parameter Db
  A database to connect to.
  
 .Parameter RecordSeparator
  A record separator for the results.  Defaults to TAB.
  
 .Parameter Query
  The select string to run against the database.
  
 .Return
  An array of the results.  Each element of the array is a complete row from the resultset.
  
 .Notes
  Taken from http://www.vistax64.com/powershell/190352-executing-sql-queries-powershell.html
#>
	param([string]$Query,
	[string]$SqlServer = $DEFAULT_SQL_SERVER,
	[string]$DB = $DEFAULT_SQL_DB,
	[string]$RecordSeparator = "`t")

	$conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" +
	"Integrated Security=SSPI")
	$conn = New-Object
	System.Data.SqlClient.SqlConnection($conn_options)
	$conn.Open()
	$cmd = $conn.CreateCommand()
	$cmd.CommandText = $Query
	$reader = $cmd.ExecuteReader()

	$results = @()
	$record = 0
	$columns = New-Object object[] $reader.FieldCount

	while($reader.Read()) {
	$results += $null
	$reader.GetValues($columns) > $null
	$results[$record] = ($columns | join-string2 $RecordSeparator)
	$record++
	}

	return $results
}


# Run-SqlNonQuery
# Runs a non-query SQL statement.
#
# Args:
# $Statement: The SQL statement to be executed
# $SqlServer: The name of the target SQL Server
# $DB: The initial DB to connect to
#
# Returns:
# The number of rows affected.

function Run-SqlNonQuery {
<#
 .Synopsis
  Run a query against the database that does not return a resultset.
  
 .Description
  Intended to run queries that perform some other action than capturing and returning 
  data.  
  
 .Parameter Statement
  The SQL statement to be run against the database.
  
 .Parameter SqlServer
  The server to be connected to.
  
 .Parameter Db
  The database to connect to.
  
 .Return
  The number of rows affected by the statement.
  
 .Notes
  Taken from http://www.vistax64.com/powershell/190352-executing-sql-queries-powershell.html
#>
	param([string]$Statement,
	[string]$SqlServer = $DEFAULT_SQL_SERVER,
	[string]$DB = $DEFAULT_SQL_DB)

	$conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" +
	"Integrated Security=SSPI")
	$conn = New-Object
	System.Data.SqlClient.SqlConnection($conn_options)
	$conn.Open()
	$cmd = $conn.CreateCommand()
	$cmd.CommandText = $Statement
	$result = $cmd.ExecuteNonQuery()
	return $result
}
