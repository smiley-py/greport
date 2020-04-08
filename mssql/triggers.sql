
create trigger [dbo].[CategorizeBulletinDelete] on [dbo].[bulletin]
for delete 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[bulletin_id] from deleted;

	Delete from [CategorizeBulletinView] where bulletin_id = @InsertedId;

end
GO

CREATE trigger [dbo].[CategorizeBulletinInsert] on [dbo].[bulletin]
for insert 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[bulletin_id] from inserted;

    Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName1 nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);

	Declare @IdItem int;
	Declare @NameItem nvarchar(250);
	Declare @TagNameItem1 nvarchar(250);
	Declare @TagNameItem2 nvarchar(250);
	Declare @TagNameItem3 nvarchar(250);
	
	Declare @IdContact int;
	Declare @NameContact nvarchar(250);
	Declare @TagNameContact1 nvarchar(250);
	Declare @TagNameContact2 nvarchar(250);
	Declare @TagNameContact3 nvarchar(250);
	
	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;

	Declare @code nvarchar(250);
	Declare @btype nvarchar(250);
	Declare @duration nvarchar(250);
	Declare @grp nvarchar(250);
	Declare @app nvarchar(250);

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName1],[TagName2],[TagName3] FROM [Group] where [Is_deleted]=0 order by [Name];
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			if ((@TagName1 is null) or (@TagName1 = ''))
			BEGIN
				set @TagName1='Empty01';
			END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagName3 = ''))
				BEGIN
					set @TagName3='Empty03';
				END


				DECLARE crsItem CURSOR FOR SELECT [Item].[Id] as IdItem,[Item].[Name] as ItemName,[Item].[TagName1] as TagNameItem1,[Item].[TagName2] as TagNameItem2,[Item].[TagName3] as TagNameItem3 from [Item] INNER JOIN [Group] 
					ON([Item].[GroupId]= [Group].[Id]) where [Group].[Name]=@Name and [Item].[Is_deleted]=0;
				OPEN crsItem;     
				FETCH NEXT FROM crsItem INTO @IdItem,@NameItem,@TagName1,@TagNameItem2,@TagNameItem3;  
				WHILE @@FETCH_STATUS=0   
					BEGIN 
						if ((@TagNameItem1 is null) or (@TagNameItem1 = ''))
							BEGIN
								set @TagNameItem1='Empty01';
							END
						if ((@TagNameItem2 is null) or (@TagNameItem2 = ''))
							BEGIN
								set @TagNameItem2='Empty02';
							END
						if ((@TagNameItem3 is null) or (@TagNameItem3 = ''))
							BEGIN
								set @TagNameItem3='Empty03';
							END


						DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
						where 
							(([detail] like '%'+@NameItem+'%') or ([effect] like '%'+@NameItem+'%') 
							or ([detail] like '%'+@TagNameItem1+'%') or ([Effect] like '%'+@TagNameItem1+'%')
							or ([detail] like '%'+@TagNameItem2+'%') or ([Effect] like '%'+@TagName2+'%')
							or ([detail] like '%'+@TagNameItem3+'%') or ([Effect] like '%'+@TagNameItem3+'%')) 
							and [state]='Done' and [is_deleted]=0 and [bulletin_id]=@InsertedId;

						OPEN crsBlt;     
						FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
						WHILE @@FETCH_STATUS=0   
						BEGIN 
							----------------------------------------------------------
							DECLARE crsContact CURSOR FOR SELECT [Id] as [IdContact],[Name] as [NameContact],[TagName1] as TagNameContact1,[TagName2] as TagNameContact2,[TagName3] as TagNameContact3 FROM [Contact] where [Is_deleted]=0 order by [Name];
							OPEN crsContact;     
							FETCH NEXT FROM crsContact INTO @IdContact,@NameContact,@TagNameContact1,@TagNameContact2,@TagNameContact3;  
							WHILE @@FETCH_STATUS=0   
								BEGIN    
									if ((@TagNameContact1 is null) or (@TagNameContact1 = ''))
									BEGIN
										set @TagNameContact1='Empty01';
									END
									if ((@TagNameContact2 is null) or (@TagNameContact2 = ''))
										BEGIN
											set @TagNameContact2='Empty02';
										END
									if ((@TagNameContact3 is null) or (@TagNameContact3 = ''))
										BEGIN
											set @TagNameContact3='Empty03';
										END
										
										
									insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@IdItem,@IdContact,@BeginTimeBlt,@EndTimeBlt);
							
							
									FETCH NEXT FROM crsContact INTO @IdContact,@NameContact,@TagNameContact1,@TagNameContact2,@TagNameContact3;  
								END
								CLOSE crsContact;  
								DEALLOCATE crsContact;
							---------------------------------------------------------------------------------
								
							FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						END
						CLOSE crsBlt;  
						DEALLOCATE crsBlt;
						
						

					FETCH NEXT FROM crsApp INTO @IdItem,@NameItem,@TagNameItem1,@TagNameItem2,@TagNameItem3;   
				END
				CLOSE crsItem;  
				DEALLOCATE crsItem;
						
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

end
GO


CREATE trigger [dbo].[CategorizeBulletinUpdate] on [dbo].[bulletin]
for update 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[bulletin_id] from deleted;

	Delete from [CategorizedView] where BulletinId = @InsertedId;

    Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName1 nvarchar(250);
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);

	Declare @IdItem int;
	Declare @NameItem nvarchar(250);
	Declare @TagNameItem1 nvarchar(250);
	Declare @TagNameItem2 nvarchar(250);
	Declare @TagNameItem3 nvarchar(250);
	
	Declare @IdContact int;
	Declare @NameContact nvarchar(250);
	Declare @TagNameContact1 nvarchar(250);
	Declare @TagNameContact2 nvarchar(250);
	Declare @TagNameContact3 nvarchar(250);
	
	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;

	Declare @code nvarchar(250);
	Declare @btype nvarchar(250);
	Declare @duration nvarchar(250);
	Declare @grp nvarchar(250);
	Declare @app nvarchar(250);

	DECLARE crs CURSOR FOR SELECT [Id],[Name],[TagName1],[TagName2],[TagName3] FROM [Group] where [Is_deleted]=0 order by [Name];
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	WHILE @@FETCH_STATUS=0   
		BEGIN    
			if ((@TagName1 is null) or (@TagName1 = ''))
			BEGIN
				set @TagName1='Empty01';
			END
			if ((@TagName2 is null) or (@TagName2 = ''))
				BEGIN
					set @TagName2='Empty02';
				END
			if ((@TagName3 is null) or (@TagName3 = ''))
				BEGIN
					set @TagName3='Empty03';
				END


				DECLARE crsItem CURSOR FOR SELECT [Item].[Id] as IdItem,[Item].[Name] as ItemName,[Item].[TagName1] as TagNameItem1,[Item].[TagName2] as TagNameItem2,[Item].[TagName3] as TagNameItem3 from [Item] INNER JOIN [Group] 
					ON([Item].[GroupId]= [Group].[Id]) where [Group].[Name]=@Name and [Item].[Is_deleted]=0;
				OPEN crsItem;     
				FETCH NEXT FROM crsItem INTO @IdItem,@NameItem,@TagName1,@TagNameItem2,@TagNameItem3;  
				WHILE @@FETCH_STATUS=0   
					BEGIN 
						if ((@TagNameItem1 is null) or (@TagNameItem1 = ''))
							BEGIN
								set @TagNameItem1='Empty01';
							END
						if ((@TagNameItem2 is null) or (@TagNameItem2 = ''))
							BEGIN
								set @TagNameItem2='Empty02';
							END
						if ((@TagNameItem3 is null) or (@TagNameItem3 = ''))
							BEGIN
								set @TagNameItem3='Empty03';
							END


						DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
						where 
							(([detail] like '%'+@NameItem+'%') or ([effect] like '%'+@NameItem+'%') 
							or ([detail] like '%'+@TagNameItem1+'%') or ([Effect] like '%'+@TagNameItem1+'%')
							or ([detail] like '%'+@TagNameItem2+'%') or ([Effect] like '%'+@TagName2+'%')
							or ([detail] like '%'+@TagNameItem3+'%') or ([Effect] like '%'+@TagNameItem3+'%'))
							and [state]='Done' and [is_deleted]=0 and [bulletin_id]=@InsertedId;

						OPEN crsBlt;     
						FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
						WHILE @@FETCH_STATUS=0   
						BEGIN 
							----------------------------------------------------------
							DECLARE crsContact CURSOR FOR SELECT [Id] as [IdContact],[Name] as [NameContact],[TagName1] as TagNameContact1,[TagName2] as TagNameContact2,[TagName3] as TagNameContact3 FROM [Contact] where [Is_deleted]=0 order by [Name];
							OPEN crsContact;     
							FETCH NEXT FROM crsContact INTO @IdContact,@NameContact,@TagNameContact1,@TagNameContact2,@TagNameContact3;  
							WHILE @@FETCH_STATUS=0   
								BEGIN    
									if ((@TagNameContact1 is null) or (@TagNameContact1 = ''))
									BEGIN
										set @TagNameContact1='Empty01';
									END
									if ((@TagNameContact2 is null) or (@TagNameContact2 = ''))
										BEGIN
											set @TagNameContact2='Empty02';
										END
									if ((@TagNameContact3 is null) or (@TagNameContact3 = ''))
										BEGIN
											set @TagNameContact3='Empty03';
										END
										
										
									insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,@IdItem,@IdContact,@BeginTimeBlt,@EndTimeBlt);
							
							
									FETCH NEXT FROM crsContact INTO @IdContact,@NameContact,@TagNameContact1,@TagNameContact2,@TagNameContact3;  
								END
							CLOSE crsContact;  
							DEALLOCATE crsContact;
							---------------------------------------------------------------------------------
								
							FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
						END
						CLOSE crsBlt;  
						DEALLOCATE crsBlt;
						
						

					FETCH NEXT FROM crsItem INTO @IdItem,@NameItem,@TagNameItem1,@TagNameItem2,@TagNameItem3;   
				END
				CLOSE crsItem;  
				DEALLOCATE crsItem;
						
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

end
GO


