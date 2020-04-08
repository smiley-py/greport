CREATE FUNCTION [dbo].[get_bulletins_with_groups](@startdate datetime, @enddate datetime,@grp nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(Select Distinct(BulletinId) from [CategorizedView] 
				Left JOIN [Group] ON([CategorizedView].[GroupId]=[Group].[Id]) 
				Left JOIN [Item] ON([CategorizedView].[ItemId]=[Item].[Id]) 
				where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < DATEADD(day,1,@enddate) 
					and (
						([Group].[Name] like '%'+@grp+'%') or
						([Group].[TagName1] like '%'+@grp+'%') or
						([Group].[TagName2] like '%'+@grp+'%') or
						([Group].[TagName3] like '%'+@grp+'%')
						)
					)
			)
		)
GO


CREATE FUNCTION [dbo].[get_bulletins_with_items](@startdate datetime, @enddate datetime,@item nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(Select Distinct(BulletinId) from [CategorizedView] 
				Left JOIN [Group] ON([CategorizedView].[GroupId]=[Group].[Id]) 
				Left JOIN [Item] ON([CategorizedView].[ItemId]=[Item].[Id]) 
				where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < DATEADD(day,1,@enddate) 
					and (
						([Item].[Name] like '%'+@item+'%') or
						([Item].[TagName1] like '%'+@item+'%') or
						([Item].[TagName2] like '%'+@item+'%') or
						([Item].[TagName3] like '%'+@item+'%')
						)
					)
			)
		)
GO

CREATE FUNCTION [dbo].[get_bulletins_with_contacts](@startdate datetime, @enddate datetime,@cont nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(Select Distinct(BulletinId) from [CategorizedView]
				Left JOIN [Contact] ON([CategorizedView].[ContactId]=[Contact].[Id]) 
				where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < DATEADD(day,1,@enddate) 
					and (
						([Contact].[Name] like '%'+@cont+'%') or
						([Contact].[TagName1] like '%'+@cont+'%') or
						([Contact].[TagName2] like '%'+@cont+'%') or
						([Contact].[TagName3] like '%'+@cont+'%')
						)
					)
			)
		)
GO


CREATE FUNCTION [dbo].[get_group_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	Name nvarchar(250) null,
	SumMaintenance int null,
	SumOutage int null,
	CountMaintenance int null,
	CountOutage int null,
	[Availability] float null
)
AS
BEGIN
	Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @totaldate int;

	Declare @msum int;
	Declare @osum int;
	Declare @mcount int;
	Declare @ocount int;
	Declare @availability float;
	
	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;
	
	DECLARE crs CURSOR FOR SELECT [Id],[Name] FROM [Group] where [Is_Deleted]=0 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name;  
	WHILE @@FETCH_STATUS=0   
		BEGIN 
			   	
			Select  @msum=isnull(sum(cast([duration] as int)),0),@mcount=Count(bulletin_id) from [bulletin] where  ([btype]='Planned Maintenance' or [btype]='Urgent Maintenance') and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_groups(@startdate,@enddate,@Name)); 
			Select  @osum=isnull(sum(cast([duration] as int)),0),@ocount=Count(bulletin_id) from [bulletin] where  [btype]='Outage' and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_groups(@startdate,@enddate,@Name)); 
						
			set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
			insert into @typetable (Name,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Name;   
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END
GO

CREATE FUNCTION [dbo].[get_item_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	[Group] nvarchar(250) null,
	Name nvarchar(250) null,
	SumMaintenance int null,
	SumOutage int null,
	CountMaintenance int null,
	CountOutage int null,
	[Availability] float null
)
AS
BEGIN
	Declare @msum int;
	Declare @osum int;
	Declare @mcount int;
	Declare @ocount int;
	Declare @totaldate int;
	Declare @availability float;	

	Declare @Id int;
	Declare @Group nvarchar(250);
	Declare @Name nvarchar(250);

	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;

	DECLARE crs CURSOR FOR 
		SELECT [Item].[Id],[Group].[Name] as [Group],[Item].[Name] FROM [Item] 
		JOIN [Group] ON ([Item].[GroupId]=[Group].[Id])
		where [Item].[Is_Deleted]=0 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Group,@Name;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			set @msum=0;
			set @osum=0;
			set @mcount=0;
			set @ocount=0;

				Select @msum=isnull(sum(cast([duration] as int)),0), @mcount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Planned Maintenance' or [btype]='Urgent Maintenance') and ([begin_time] >= @startdate and [begin_time] < DATEADD(day,1,@enddate))
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_items(@startdate,@enddate,@Name));
				
				Select @msum=isnull(sum(cast([duration] as int)),0), @mcount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Outage') and ([begin_time] >= @startdate and [begin_time] < DATEADD(day,1,@enddate))
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_items(@startdate,@enddate,@Name));
				
			set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
			insert into @typetable ([Group],Name,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Group,@Name,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Group,@Name;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END
GO

CREATE FUNCTION [dbo].[get_contact_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	Name nvarchar(250) null,
	SumMaintenance int null,
	SumOutage int null,
	CountMaintenance int null,
	CountOutage int null,
	[Availability] float null
)
AS
BEGIN
	Declare @msum int;
	Declare @osum int;
	Declare @mcount int;
	Declare @ocount int;

	Declare @totaldate int;
	Declare @availability float;

	Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName1 nvarchar(250);	
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	
	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName1],[TagName2],[TagName3] FROM [Contact] where [Is_Deleted]=0 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			set @msum=0;
			set @osum=0;	
			set @mcount=0;
			set @ocount=0;		
			
			
				Select @msum=isnull(sum(cast([duration] as int)),0), @mcount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Planned Maintenance' or [btype]='Urgent Maintenance') and ([begin_time] >= @startdate and [begin_time] < DATEADD(day,1,@enddate))
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_contacts(@startdate,@enddate,@Name));
				
				Select @msum=isnull(sum(cast([duration] as int)),0), @mcount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Outage') and ([begin_time] >= @startdate and [begin_time] < DATEADD(day,1,@enddate))
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_contacts(@startdate,@enddate,@Name));							

				
			set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
			insert into @typetable (Name,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END
GO



