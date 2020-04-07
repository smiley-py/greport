
CREATE TABLE [dbo].[Bulletins](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreatedBy] [int] NOT NULL,
	[Datetime] [datetime] NOT NULL,
	[Code] [nvarchar](50) NULL,
	[Type] [nvarchar](255) NOT NULL,
	[Title] [text] NOT NULL,
	[Detail] [text] NULL,
	[Effect] [text] NULL,
	[BeginTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ResponsibleGroupId] [int] NOT NULL,
	[Duration] [nvarchar](50) NULL,
	[IncidentId] [nvarchar](50) NULL,
	[Priority] [nvarchar](50) NOT NULL,
	[BulletinStateId] [int] NOT NULL,
	[LanguageId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[TemporarySolutionMethod] [text] NULL,
	[PermanentSolutionMethod] [text] NULL,
	[ResolutionState] [nvarchar](50) NULL,
	[ResolutionTime] [datetime] NULL,
	[ResolvedBy] [int] NULL,
	[BulletinMailStateId] [int] NULL
GO

--- Application
CREATE TABLE [dbo].[Items](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DeploymentType] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[URL] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[Status] [int] NOT NULL,
	[ApplicationGroupId] [int] NULL,
	[TagName] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	[TagName4] [nvarchar](250) NULL,
	[Responsible] [nvarchar](250) NULL,
	[Hostnames] [nvarchar](500) NULL,
	[ProjectId] [int] NULL,
	[LocationId] [int] NULL,
	[ShowOnReport] [int] NULL,
	[Databases] [nvarchar](500) NULL
	)
GO

CREATE TABLE [dbo].[Contact](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Mail] [text] NULL,
	[Type] [nvarchar](10) NOT NULL,
	[Phone] [nvarchar](50) NULL,
	[Status] [int] NOT NULL,
	[Description] [nvarchar](500) NULL,
	[TagName] [nvarchar](255) NULL
	)
GO

CREATE TABLE [dbo].[GrouppedBulletinView](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BulletinId] [int] NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](500) NULL,
	[Duration] [nvarchar](250) NULL,
	[GroupId] [int] NULL,
	[ApplicationId] [int] NULL,
	[BeginTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL
	)
GO

---- applicationgroup
CREATE TABLE [dbo].[Groups](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](255) NULL,
	[Description] [nvarchar](500) NULL,
	[Status] [int] NULL,
	[TagName] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	[TagName4] [nvarchar](250) NULL
	)
GO

--------------------------------------------------------------------
---sp_SetStreamingAllBulletins
CREATE Proc [dbo].[sp_set_categorize_all_bulletins]
AS
BEGIN
	Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	Declare @TagName4 nvarchar(250);

	Declare @IdApp int;
	Declare @NameApp nvarchar(250);
	Declare @TagNameApp nvarchar(250);
	Declare @TagNameApp2 nvarchar(250);
	Declare @TagNameApp3 nvarchar(250);
	Declare @TagNameApp4 nvarchar(250);
	
	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;

	Declare @code nvarchar(250);
	Declare @type nvarchar(250);
	Declare @duration nvarchar(250);
	Declare @grp nvarchar(250);
	Declare @app nvarchar(250);

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName],[TagName2],[TagName3],[TagName4] FROM [ApplicationGroup] where [Status]=1 order by [Name];
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			if ((@TagName is null) or (@TagName = ''))
			BEGIN
				set @TagName='Empty00';
			END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagNameApp3 = ''))
				BEGIN
					set @TagNameApp3='Empty03';
				END
			if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
				BEGIN
					set @TagNameApp4='Empty04';
				END

				DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration], [Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
				where 
					(([Detail] like '%'+@Name+'%') or ([Effect] like '%'+@Name+'%') 
					or ([Detail] like '%'+@TagName+'%') or ([Effect] like '%'+@TagName+'%')
					or ([Detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
					or ([Detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')
					or ([Detail] like '%'+@TagName4+'%') or ([Effect] like '%'+@TagName4+'%')) 
					and [BulletinStateId]=11 and [Status]=1;

				OPEN crsBlt;     
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
				WHILE @@FETCH_STATUS=0   
				BEGIN 
					insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@BeginTimeBlt,@EndTimeBlt);
						
					FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
				END
				CLOSE crsBlt;  
				DEALLOCATE crsBlt;


				DECLARE crsApp CURSOR FOR SELECT [Application].[Id],[Application].[Name],[Application].[TagName],[Application].[TagName2],[Application].[TagName3],[Application].[TagName4] from [Application] INNER JOIN [ApplicationGroup] ON([Application].[ApplicationGroupId]= [ApplicationGroup].[Id]) where [ApplicationGroup].[Name]=@Name and [Application].[Status]=1;
				OPEN crsApp;     
				FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;  
				WHILE @@FETCH_STATUS=0   
					BEGIN 
						if ((@TagNameApp is null) or (@TagNameApp = ''))
							BEGIN
								set @TagNameApp='Empty00';
							END
						if ((@TagNameApp2 is null) or (@TagNameApp2 = ''))
							BEGIN
								set @TagNameApp2='Empty02';
							END
						if ((@TagNameApp3 is null) or (@TagNameApp3 = ''))
							BEGIN
								set @TagNameApp3='Empty03';
							END
						if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
							BEGIN
								set @TagNameApp4='Empty04';
							END


						DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration],[Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
						where 
							(([Detail] like '%'+@NameApp+'%') or ([Effect] like '%'+@NameApp+'%') 
							or ([Detail] like '%'+@TagNameApp+'%') or ([Effect] like '%'+@TagNameApp+'%') 
							or ([Detail] like '%'+@TagNameApp2+'%') or ([Effect] like '%'+@TagNameApp2+'%') 
							or ([Detail] like '%'+@TagNameApp3+'%') or ([Effect] like '%'+@TagNameApp3+'%')
							or ([Detail] like '%'+@TagNameApp4+'%') or ([Effect] like '%'+@TagNameApp4+'%')) 
							and [BulletinStateId]=11 and [Status]=1;

						OPEN crsBlt;     
						FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						WHILE @@FETCH_STATUS=0   
						BEGIN 
							insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[ApplicationId],[BeginTime],[EndTime]) values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@IdApp,@BeginTimeBlt,@EndTimeBlt);
						
							FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						END
						CLOSE crsBlt;  
						DEALLOCATE crsBlt;

					FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;   
				END
				CLOSE crsApp;  
				DEALLOCATE crsApp;
						
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return 1;
END
GO

--------------------------------------------------------------------------------------------------------------------------


create trigger [dbo].[SetGrouppedBulletinDelete] on [dbo].[Bulletin]
for delete 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[Id] from deleted;

	Delete from [GrouppedBulletinView] where BulletinId = @InsertedId;

end
GO

CREATE trigger [dbo].[CategorizeBulletinInsert] on [dbo].[Bulletin]
for insert 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[Id] from inserted;

    Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	Declare @TagName4 nvarchar(250);

	Declare @IdApp int;
	Declare @NameApp nvarchar(250);
	Declare @TagNameApp nvarchar(250);
	Declare @TagNameApp2 nvarchar(250);
	Declare @TagNameApp3 nvarchar(250);
	Declare @TagNameApp4 nvarchar(250);
	
	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;

	Declare @code nvarchar(250);
	Declare @type nvarchar(250);
	Declare @duration nvarchar(250);
	Declare @grp nvarchar(250);
	Declare @app nvarchar(250);

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName],[TagName2],[TagName3],[TagName4] FROM [ApplicationGroup] where [Status]=1 order by [Name];
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			if ((@TagName is null) or (@TagName = ''))
			BEGIN
				set @TagName='Empty00';
			END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagNameApp3 = ''))
				BEGIN
					set @TagNameApp3='Empty03';
				END
			if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
				BEGIN
					set @TagNameApp4='Empty04';
				END

				DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration], [Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
				where 
					(([Detail] like '%'+@Name+'%') or ([Effect] like '%'+@Name+'%') 
					or ([Detail] like '%'+@TagName+'%') or ([Effect] like '%'+@TagName+'%')
					or ([Detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
					or ([Detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')
					or ([Detail] like '%'+@TagName4+'%') or ([Effect] like '%'+@TagName4+'%')) 
					and [BulletinStateId]=11 and [Status]=1 and [Id]=@InsertedId;

				OPEN crsBlt;     
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
				WHILE @@FETCH_STATUS=0   
				BEGIN 
					insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@BeginTimeBlt,@EndTimeBlt);
						
					FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
				END
				CLOSE crsBlt;  
				DEALLOCATE crsBlt;


				DECLARE crsApp CURSOR FOR SELECT [Application].[Id],[Application].[Name],[Application].[TagName],[Application].[TagName2],[Application].[TagName3],[Application].[TagName4] from [Application] INNER JOIN [ApplicationGroup] ON([Application].[ApplicationGroupId]= [ApplicationGroup].[Id]) where [ApplicationGroup].[Name]=@Name and [Application].[Status]=1;
				OPEN crsApp;     
				FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;  
				WHILE @@FETCH_STATUS=0   
					BEGIN 
						if ((@TagNameApp is null) or (@TagNameApp = ''))
							BEGIN
								set @TagNameApp='Empty00';
							END
						if ((@TagNameApp2 is null) or (@TagNameApp2 = ''))
							BEGIN
								set @TagNameApp2='Empty02';
							END
						if ((@TagNameApp3 is null) or (@TagNameApp3 = ''))
							BEGIN
								set @TagNameApp3='Empty03';
							END
						if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
							BEGIN
								set @TagNameApp4='Empty04';
							END


						DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration],[Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
						where 
							(([Detail] like '%'+@NameApp+'%') or ([Effect] like '%'+@NameApp+'%') 
							or ([Detail] like '%'+@TagNameApp+'%') or ([Effect] like '%'+@TagNameApp+'%') 
							or ([Detail] like '%'+@TagNameApp2+'%') or ([Effect] like '%'+@TagNameApp2+'%') 
							or ([Detail] like '%'+@TagNameApp3+'%') or ([Effect] like '%'+@TagNameApp3+'%')
							or ([Detail] like '%'+@TagNameApp4+'%') or ([Effect] like '%'+@TagNameApp4+'%')) 
							and [BulletinStateId]=11 and [Status]=1 and [Id]=@InsertedId;

						OPEN crsBlt;     
						FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						WHILE @@FETCH_STATUS=0   
						BEGIN 
							insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[ApplicationId],[BeginTime],[EndTime]) values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@IdApp,@BeginTimeBlt,@EndTimeBlt);
						
							FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						END
						CLOSE crsBlt;  
						DEALLOCATE crsBlt;

					FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;   
				END
				CLOSE crsApp;  
				DEALLOCATE crsApp;
						
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

end
GO


CREATE trigger [dbo].[CategorizeBulletinUpdate] on [dbo].[Bulletin]
for update 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[Id] from deleted;

	Delete from [GrouppedBulletinView] where BulletinId = @InsertedId;

    Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	Declare @TagName4 nvarchar(250);

	Declare @IdApp int;
	Declare @NameApp nvarchar(250);
	Declare @TagNameApp nvarchar(250);
	Declare @TagNameApp2 nvarchar(250);
	Declare @TagNameApp3 nvarchar(250);
	Declare @TagNameApp4 nvarchar(250);
	
	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;

	Declare @code nvarchar(250);
	Declare @type nvarchar(250);
	Declare @duration nvarchar(250);
	Declare @grp nvarchar(250);
	Declare @app nvarchar(250);

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName],[TagName2],[TagName3],[TagName4] FROM [ApplicationGroup] where [Status]=1 order by [Name];
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			if ((@TagName is null) or (@TagName = ''))
			BEGIN
				set @TagName='Empty00';
			END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagNameApp3 = ''))
				BEGIN
					set @TagNameApp3='Empty03';
				END
			if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
				BEGIN
					set @TagNameApp4='Empty04';
				END

				DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration], [Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
				where 
					(([Detail] like '%'+@Name+'%') or ([Effect] like '%'+@Name+'%') 
					or ([Detail] like '%'+@TagName+'%') or ([Effect] like '%'+@TagName+'%')
					or ([Detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
					or ([Detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')
					or ([Detail] like '%'+@TagName4+'%') or ([Effect] like '%'+@TagName4+'%')) 
					and [BulletinStateId]=11 and [Status]=1 and [Id]=@InsertedId;

				OPEN crsBlt;     
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
				WHILE @@FETCH_STATUS=0   
				BEGIN 
					insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@BeginTimeBlt,@EndTimeBlt);
						
					FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
				END
				CLOSE crsBlt;  
				DEALLOCATE crsBlt;


				DECLARE crsApp CURSOR FOR SELECT [Application].[Id],[Application].[Name],[Application].[TagName],[Application].[TagName2],[Application].[TagName3],[Application].[TagName4] from [Application] INNER JOIN [ApplicationGroup] ON([Application].[ApplicationGroupId]= [ApplicationGroup].[Id]) where [ApplicationGroup].[Name]=@Name and [Application].[Status]=1;
				OPEN crsApp;     
				FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;  
				WHILE @@FETCH_STATUS=0   
					BEGIN 
						if ((@TagNameApp is null) or (@TagNameApp = ''))
							BEGIN
								set @TagNameApp='Empty00';
							END
						if ((@TagNameApp2 is null) or (@TagNameApp2 = ''))
							BEGIN
								set @TagNameApp2='Empty02';
							END
						if ((@TagNameApp3 is null) or (@TagNameApp3 = ''))
							BEGIN
								set @TagNameApp3='Empty03';
							END
						if ((@TagNameApp4 is null) or (@TagNameApp4 = ''))
							BEGIN
								set @TagNameApp4='Empty04';
							END


						DECLARE crsBlt CURSOR FOR SELECT [Bulletin].[Id],[Bulletin].[Code], [Bulletin].[Duration],[Bulletin].[Type],[Bulletin].[BeginTime],[Bulletin].[EndTime] from [Bulletin] 
						where 
							(([Detail] like '%'+@NameApp+'%') or ([Effect] like '%'+@NameApp+'%') 
							or ([Detail] like '%'+@TagNameApp+'%') or ([Effect] like '%'+@TagNameApp+'%') 
							or ([Detail] like '%'+@TagNameApp2+'%') or ([Effect] like '%'+@TagNameApp2+'%') 
							or ([Detail] like '%'+@TagNameApp3+'%') or ([Effect] like '%'+@TagNameApp3+'%')
							or ([Detail] like '%'+@TagNameApp4+'%') or ([Effect] like '%'+@TagNameApp4+'%')) 
							and [BulletinStateId]=11 and [Status]=1 and [Id]=@InsertedId;

						OPEN crsBlt;     
						FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						WHILE @@FETCH_STATUS=0   
						BEGIN 
							insert into [GrouppedBulletinView] (BulletinId,Code,Duration,[Type],[GroupId],[ApplicationId],[BeginTime],[EndTime]) values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@IdApp,@BeginTimeBlt,@EndTimeBlt);
						
							FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						END
						CLOSE crsBlt;  
						DEALLOCATE crsBlt;

					FETCH NEXT FROM crsApp INTO @IdApp,@NameApp,@TagNameApp,@TagNameApp2,@TagNameApp3,@TagNameApp4;   
				END
				CLOSE crsApp;  
				DEALLOCATE crsApp;
						
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

end
GO





-------------------------------------------------------------------------------------


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
	
	DECLARE crs CURSOR FOR SELECT [Id],[Name] FROM [ApplicationGroup] where [Status]=1 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name;  
	WHILE @@FETCH_STATUS=0   
		BEGIN 
			   	
			Select  @msum=isnull(sum(cast([Duration] as int)),0),@mcount=Count(Id) from [Bulletin] where  ([Type]='Planned Maintenance' or [Type]='Urgent Maintenance') and [Id] in (Select Id from dbo.GetGrouppedBulletins(@startdate,@enddate,@Name)); 
			Select  @osum=isnull(sum(cast([Duration] as int)),0),@ocount=Count(Id) from [Bulletin] where  [Type]='Outage' and [Id] in (Select Id from dbo.GetGrouppedBulletins(@startdate,@enddate,@Name)); 
						
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
	Declare @TagName nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	Declare @TagName4 nvarchar(250);

	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName],[TagName2],[TagName3],[TagName4] FROM [Application] where [Status]=1 and [ShowOnReport]=1 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			set @msum=0;
			set @osum=0;
			set @mcount=0;
			set @ocount=0;

			if ((@TagName is null) or (@TagName = ''))
				BEGIN
					set @TagName='Empty00';
				END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagName3 = ''))
				BEGIN
					set @TagName3='Empty03';
				END
			if ((@TagName4 is null) or (@TagName4 = ''))
				BEGIN
					set @TagName4='Empty04';
				END


				Select @msum=isnull(sum(cast([Duration] as int)),0), @mcount=Count(Id) from [Bulletin] 
					 where (([Detail] like '%'+@Name+'%') or ([Effect] like '%'+@Name+'%') 
					 or ([Detail] like '%'+@TagName+'%') or ([Effect] like '%'+@TagName+'%') 
					 or ([Detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%') 
					 or ([Detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%') 
					 or ([Detail] like '%'+@TagName4+'%') or ([Effect] like '%'+@TagName4+'%')) 
					 and [BulletinStateId]=11 and [Type]='Planned Maintenance' and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@enddate));
				
				Select @osum=isnull(sum(cast([Duration] as int)),0), @ocount=Count(Id)  from [Bulletin]
					 where (([Detail] like '%'+@Name+'%') or ([Effect] like '%'+@Name+'%') 
					 or ([Detail] like '%'+@TagName+'%') or ([Effect] like '%'+@TagName+'%') 
					 or ([Detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%') 
					 or ([Detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%') 
					 or ([Detail] like '%'+@TagName4+'%') or ([Effect] like '%'+@TagName4+'%')) 
					 and [BulletinStateId]=11 and [Type]='Outage' and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@enddate));					

			set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
			insert into @typetable (Name,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Name,@TagName,@TagName2,@TagName3,@TagName4;    
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

	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;

	DECLARE crs CURSOR FOR SELECT [Id],[Name] FROM [Contact] where [Type]='Group' and [Status]=1 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			set @msum=0;
			set @osum=0;	
			set @mcount=0;
			set @ocount=0;		
			
			
				Select @msum=isnull(sum(cast([Duration] as int)),0),@mcount=Count(Id) from [Bulletin] where [ResponsibleGroupId]=@Id and [BulletinStateId]=11 and ([Type]='Planned Maintenance' or [Type]='Urgent Maintenance') and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@enddate));
				Select @osum=isnull(sum(cast([Duration] as int)),0),@ocount=Count(Id) from [Bulletin] where [ResponsibleGroupId]=@Id and [BulletinStateId]=11 and [Type]='Outage' and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@enddate));								

				
			set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
			insert into @typetable (Name,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Name;   
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END
GO


CREATE FUNCTION [dbo].[get_type_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	CreatedTime Datetime null,
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

	set @totaldate= DATEDIFF(day,@startdate,@enddate)+1;

	while(@startdate <= @enddate)
	Begin
		Select @msum=isnull(sum(cast([Duration] as int)),0),@mcount=Count(Id) from [Bulletin] where ([Type]='Planned Maintenance' or [Type]='Urgent Maintenance') and [BulletinStateId]=11 and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@startdate));
		Select @osum=isnull(sum(cast([Duration] as int)),0),@ocount=Count(Id)  from [Bulletin] where [Type]='Outage' and [BulletinStateId]=11 and [Status]=1 and ([BeginTime] >= @startdate and [BeginTime] < DATEADD(day,1,@startdate));
		
		set @availability=(((@totaldate*24)-(@osum/60.0))/(@totaldate*24))*100;
		insert into @typetable (CreatedTime,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@startdate,@msum,@osum,@mcount,@ocount,@availability);
		
		set @startdate =DATEADD(day,1,@startdate);
	end

	return;
END
GO


CREATE FUNCTION [dbo].[get_group_bulletins](@startdate datetime, @enddate datetime,@appgrp nvarchar(250))
returns table
AS	
	return( 
			Select * from [Bulletin] where [BulletinStateId]=11 and [Status]=1 and [Id] in 
			(Select Distinct(BulletinId) from [GrouppedBulletinView] 
				Left JOIN [ApplicationGroup] ON([GrouppedBulletinView].[GroupId]=[ApplicationGroup].[Id]) 
				Left JOIN [Application] ON([GrouppedBulletinView].[ApplicationId]=[Application].[Id]) 
				where ([GrouppedBulletinView].[BeginTime] >= @startdate and [GrouppedBulletinView].[BeginTime] < DATEADD(day,1,@enddate) 
					and (
						([ApplicationGroup].[Name] like '%'+@appgrp+'%') or
						([ApplicationGroup].[TagName] like '%'+@appgrp+'%') or
						([ApplicationGroup].[TagName2] like '%'+@appgrp+'%') or
						([ApplicationGroup].[TagName3] like '%'+@appgrp+'%') or
						([ApplicationGroup].[TagName4] like '%'+@appgrp+'%')
						)
					)
			)
		)
GO

