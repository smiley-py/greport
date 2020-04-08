Declare @Object as Int;
Declare @ResponseText as Varchar(8000);

Code Snippet
Exec sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
Exec sp_OAMethod @Object, 'open', NULL, 'get',
                 'http://www.webservicex.com/stockquote.asmx/GetQuote?symbol=MSFT', --Your Web Service Url (invoked)
                 'false'
Exec sp_OAMethod @Object, 'send'
Exec sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT

Select @ResponseText

Exec sp_OADestroy @Object