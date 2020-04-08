declare @startdate as datetime = '2017-01-24'
declare @enddate as datetime = dateadd(day,1,@startdate)

declare @sql varchar(8000)

set @sql =
'bcp "select * from tblBOJEOJ where system = ''MKEV03'' and [date] between ''' + cast(@startdate as nvarchar(11)) + ''' and ''' + cast(@enddate as nvarchar(11)) + ''' " queryout D:\Temp\Galaxy\BOJEOJ_.csv -c -t, -T -S ' + @@SERVERNAME 

print @sql

exec master..xp_cmdshell @sql

----------------------------------------------------------------------------------------

declare @sql varchar(2000)
declare @server varchar(100)
set @server = 'SIMONWHALE\SQL_2005'

set @sql = 'bcp oak_underwriting.dbo.broker out "c:\tests.csv" -c -t -T -S"' + @server + '"'
exec master..xp_cmdshell @sql