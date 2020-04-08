Configure MSSQL database mail
MSSQL 2005 Enterprise or Standard versions provide mail feature integrated in the database, so that one can send bulk [:)] emails from the database.
-----------------------------------------------------------------------------
Step 1
One should enable Database mail on the server, before setting up the Database Mail profile and accounts. Either can be done by using Transact SQL to enable Database Mail or the second method to use a GUI.
In the SQL Server Management Studio 2005, run the following statement.

use master
go
sp_configure 'show advanced options',1
go
reconfigure with override
go
sp_configure 'Database Mail XPs',1
--go
--sp_configure 'SQL Mail XPs',0
go
reconfigure
go
OR


-----------------------------------------------------------------------------

bcp "SELECT Col1,Col2,Col3 FROM MyDatabase.dbo.MyTable" queryout "D:\MyTable.csv" -c -t , -S SERVERNAME -T


-----------------------------------------------------------------------------
Step 2
One can enable the Configuration Component Database account by using the sysmail_add_account procedure.
You’d execute the below query.

EXECUTE msdb.dbo.sysmail_add_account_sp
@account_name = 'TestMailAccount',
@description = 'Mail account for Database Mail',
@email_address = 'tanmaya@mydomain.com',
@display_name = 'MyAccount',
@username='tanmaya@mydomain.com',
@password='1qwe432',
@mailserver_name = 'mail.mydomain.com',
@file_attachments='D:\MyTable.csv' 

-----------------------------------------------------------------------------
Step 3
Now one should create a Mail profile.
You’d execute the below query.

EXECUTE msdb.dbo.sysmail_add_profile_sp
@profile_name = 'TestMailProfile',
@description = 'Profile needed for database mail'



-----------------------------------------------------------------------------
Step 4
Next will be the sysmail_add_profileaccount procedure, to include the Database Mail account which is created in step 2, along with the Database Mail profile in step 3.
You’d execute the below query.

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = 'TestMailProfile',
@account_name = 'TestMailAccount',
@sequence_number = 1


-----------------------------------------------------------------------------
Step 5
You’d execute the below query.

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
@profile_name = 'TestMailProfile',
@principal_name = 'public',
@is_default = 1 ;


-----------------------------------------------------------------------------
Step 6
After all these settings done, try to send a test mail from MSSQL Server.
You’d execute the below query.

declare @body1 varchar(100)
set @body1 = 'Server :'+@@servername+ ' Test DB Email '
EXEC msdb.dbo.sp_send_dbmail @recipients='tanmaya@mydomain.com',
@subject = 'Test',
@body = @body1,
@body_format = 'HTML' ;


-----------------------------------------------------------------------------
Step 7
You’d configure the Database Mail profile and its account using MSSQL Server Management Studio by right click Database Mail > Configuration.


-----------------------------------------------------------------------------
Step 8
You can review the logs linked to Database Mail.
You’d execute the below query.

SELECT * FROM msdb.dbo.sysmail_event_log
