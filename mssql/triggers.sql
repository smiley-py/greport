
create trigger [dbo].[CategorizeBulletinDelete] on [dbo].[Bulletin]
for delete 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[Id] from deleted;

	Delete from [CategorizeBulletinView] where BulletinId = @InsertedId;

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



