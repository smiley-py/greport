USE [master]
GO
/****** Object:  Database [test]    Script Date: 4/26/2020 2:16:10 PM ******/
CREATE DATABASE [test]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'test', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\test.mdf' , SIZE = 5120KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'test_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\test_log.ldf' , SIZE = 2048KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [test] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [test].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [test] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [test] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [test] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [test] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [test] SET ARITHABORT OFF 
GO
ALTER DATABASE [test] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [test] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [test] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [test] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [test] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [test] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [test] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [test] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [test] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [test] SET  DISABLE_BROKER 
GO
ALTER DATABASE [test] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [test] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [test] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [test] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [test] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [test] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [test] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [test] SET RECOVERY FULL 
GO
ALTER DATABASE [test] SET  MULTI_USER 
GO
ALTER DATABASE [test] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [test] SET DB_CHAINING OFF 
GO
ALTER DATABASE [test] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [test] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [test] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'test', N'ON'
GO
USE [test]
GO
/****** Object:  User [lib]    Script Date: 4/26/2020 2:16:11 PM ******/
CREATE USER [lib] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [grafana_user]    Script Date: 4/26/2020 2:16:11 PM ******/
CREATE USER [grafana_user] FOR LOGIN [grafana_user] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [grafana_user]
GO
/****** Object:  UserDefinedFunction [dbo].[get_contact_sla]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[get_contact_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	Name nvarchar(250) null,
	SumTotal int null,
	SumMaintenance int null,
	SumOutage int null,
	CountMaintenance int null,
	CountOutage int null,
	[Availability] float null
)
AS
BEGIN
	Declare @msum int;
	Declare @osum float;
	Declare @mcount int;
	Declare @ocount int;

	Declare @sumtotal float;
	Declare @availability float;

	Declare @Id int;
	Declare @Name nvarchar(250);
	Declare @TagName1 nvarchar(250);	
	Declare @TagName2 nvarchar(250);
	Declare @TagName3 nvarchar(250);
	
	set @sumtotal = DATEDIFF(MINUTE,@startdate,@enddate);

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
				where [state]='Done' and ([btype]='Planned Maintenance' or [btype]='Urgent Maintenance') and ([begin_time] >= @startdate and [begin_time] < @enddate)
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_contacts(@startdate,@enddate,@Name));
				
				Select @osum=isnull(sum(cast([duration] as int)),0), @ocount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Outage') and ([begin_time] >= @startdate and [begin_time] < @enddate)
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_contacts(@startdate,@enddate,@Name));							

			set @availability= 100 - ((@osum/@sumtotal) * 100);	

			insert into @typetable (Name,SumTotal,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@sumtotal,@msum,@osum,@mcount,@ocount,@availability);
			
			FETCH NEXT FROM crs INTO @Id,@Name,@TagName1,@TagName2,@TagName3;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END

GO
/****** Object:  UserDefinedFunction [dbo].[get_group_sla]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[get_group_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	Name nvarchar(250) null,
	SumTotal int null,
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
	Declare @sumtotal float;

	Declare @msum float;
	Declare @osum float;
	Declare @mcount int;
	Declare @ocount int;
	Declare @availability float;
	
	set @sumtotal = DATEDIFF(MINUTE,@startdate,@enddate);
	
	DECLARE crs CURSOR FOR SELECT [Id],[Name] FROM [Group] where [Is_Deleted]=0 order by [Name];     
	OPEN crs;     
	FETCH NEXT FROM crs INTO @Id,@Name;  
	WHILE @@FETCH_STATUS=0   
		BEGIN 
			   	
			Select  @msum=isnull(sum(cast([duration] as int)),0),@mcount=Count(bulletin_id) from [bulletin] where  ([btype]='Planned Maintenance' or [btype]='Urgent Maintenance') and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_groups(@startdate,@enddate,@Name)); 
			Select  @osum=isnull(sum(cast([duration] as int)),0),@ocount=Count(bulletin_id) from [bulletin] where  [btype]='Outage' and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_groups(@startdate,@enddate,@Name)); 
			
			set @availability= 100 - ((@osum/@sumtotal) * 100);					
			
			insert into @typetable (Name,SumTotal,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Name,@sumtotal,@msum,@osum,@mcount,@ocount,@availability);
				
			FETCH NEXT FROM crs INTO @Id,@Name;   
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END

GO
/****** Object:  UserDefinedFunction [dbo].[get_item_sla]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[get_item_sla](@startdate datetime, @enddate datetime)
returns @typetable table	(
	[Group] nvarchar(250) null,
	Name nvarchar(250) null,
	SumTotal int null,
	SumMaintenance int null,
	SumOutage int null,
	CountMaintenance int null,
	CountOutage int null,
	[Availability] float null
)
AS
BEGIN
	Declare @msum int;
	Declare @osum float;
	Declare @mcount int;
	Declare @ocount int;
	Declare @sumtotal float;
	Declare @availability float;	

	Declare @Id int;
	Declare @Group nvarchar(250);
	Declare @Name nvarchar(250);

	set @sumtotal = DATEDIFF(MINUTE,@startdate,@enddate);

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
				
				Select @osum=isnull(sum(cast([duration] as int)),0), @ocount=Count(bulletin_id) from [bulletin] 
				where [state]='Done' and ([btype]='Outage') and ([begin_time] >= @startdate and [begin_time] < DATEADD(day,1,@enddate))
				and [bulletin_id] in (Select bulletin_id from dbo.get_bulletins_with_items(@startdate,@enddate,@Name));
				
				set @availability= 100 - ((@osum/@sumtotal) * 100);		

			insert into @typetable ([Group],Name,SumTotal,SumMaintenance,SumOutage,CountMaintenance,CountOutage,[Availability]) values(@Group,@Name,@sumtotal,@msum,@osum,@mcount,@ocount,@availability);

			FETCH NEXT FROM crs INTO @Id,@Group,@Name;    
		END  
	CLOSE crs;  
	DEALLOCATE crs;

	return;
END

GO
/****** Object:  UserDefinedFunction [dbo].[info_bulletin_status]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[info_bulletin_status]()
returns @typetable table	(
	[Name] nvarchar(250) null,
	[Count] int
)
AS	
BEGIN
	declare @done int;
	declare @started int;
	declare @scheduled int;
	declare @cancel int;
	declare @rollback int;
	
	select @done=count(*) from bulletin where [state]='Done' and is_deleted=0;
	select @started=count(*) from bulletin where [state]='Started' and is_deleted=0;
	select @scheduled=count(*) from bulletin where [state]='Scheduled' and is_deleted=0;
	select @cancel=count(*) from bulletin where [state]='Cancel' and is_deleted=0;
	select @rollback=count(*) from bulletin where [state]='Rollback' and is_deleted=0;
	
	insert into @typetable ([Name],[Count]) VALUES('Started',@started);
	insert into @typetable ([Name],[Count]) VALUES('Sheduled',@scheduled);
	insert into @typetable ([Name],[Count]) VALUES('Rollback',@rollback);
	insert into @typetable ([Name],[Count]) VALUES('Cancel',@cancel);
	insert into @typetable ([Name],[Count]) VALUES('Done',@done);
	return;		
END
		

GO
/****** Object:  Table [dbo].[bulletin]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bulletin](
	[bulletin_id] [int] IDENTITY(1,1) NOT NULL,
	[id] [int] NOT NULL,
	[smtp] [nvarchar](250) NOT NULL,
	[port] [nvarchar](250) NOT NULL,
	[username] [nvarchar](250) NOT NULL,
	[password] [nvarchar](250) NOT NULL,
	[tolist] [nvarchar](250) NULL,
	[cclist] [nvarchar](250) NULL,
	[bcclist] [nvarchar](250) NULL,
	[btype] [nvarchar](250) NOT NULL,
	[priority] [nvarchar](250) NULL,
	[state] [nvarchar](250) NOT NULL,
	[color] [nvarchar](250) NULL,
	[created_by] [nvarchar](250) NOT NULL,
	[code] [nvarchar](250) NOT NULL,
	[title] [nvarchar](250) NOT NULL,
	[detail] [nvarchar](4000) NOT NULL,
	[effect] [nvarchar](4000) NOT NULL,
	[contact] [nvarchar](250) NULL,
	[begin_time] [datetime] NULL,
	[end_time] [datetime] NULL,
	[duration] [int] NULL CONSTRAINT [DF__bulletin__durati__38996AB5]  DEFAULT ((0)),
	[ticket_case_url] [text] NULL CONSTRAINT [DF__bulletin__ticket__398D8EEE]  DEFAULT ('#'),
	[ticket_case_id] [text] NULL,
	[resolved_time] [datetime] NULL CONSTRAINT [DF__bulletin__resolv__3A81B327]  DEFAULT (getdate()),
	[is_resolved] [int] NULL CONSTRAINT [DF__bulletin__is_res__3B75D760]  DEFAULT ((0)),
	[resolved_by] [nvarchar](250) NULL,
	[temporary_solution] [nvarchar](250) NULL,
	[permanent_solution] [nvarchar](250) NULL,
	[root_cause] [nvarchar](250) NULL,
	[insert_time] [datetime] NULL,
	[modify_time] [datetime] NULL,
	[is_automated] [int] NULL CONSTRAINT [DF_bulletin_is_automated]  DEFAULT ((0)),
	[is_deleted] [int] NULL CONSTRAINT [DF__bulletin__is_del__3C69FB99]  DEFAULT ((0)),
 CONSTRAINT [PK__bulletin__61677C0422C1ED5C] PRIMARY KEY CLUSTERED 
(
	[bulletin_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CategorizedView]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CategorizedView](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BulletinId] [int] NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](500) NULL,
	[Duration] [int] NULL,
	[GroupId] [int] NULL,
	[ItemId] [int] NULL,
	[ContactId] [int] NULL,
	[BeginTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
 CONSTRAINT [PK__Categori__3214EC0751B790C6] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Contact]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contact](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[GroupId] [int] NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	[Is_Deleted] [int] NULL DEFAULT ((0)),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Group]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Group](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	[Is_Deleted] [int] NULL DEFAULT ((0)),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Item]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Item](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[GroupId] [int] NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	[Is_Deleted] [int] NULL DEFAULT ((0)),
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [dbo].[get_bulletins_with_contacts]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[get_bulletins_with_contacts](@startdate datetime, @enddate datetime,@cont nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(Select Distinct(BulletinId) from [CategorizedView]
				Left JOIN [Contact] ON([CategorizedView].[ContactId]=[Contact].[Id]) 
				where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < @enddate) 
					and (
						([Contact].[Name] like '%'+@cont+'%') or
						([Contact].[TagName1] like '%'+@cont+'%') or
						([Contact].[TagName2] like '%'+@cont+'%') or
						([Contact].[TagName3] like '%'+@cont+'%')
						)
					)
			)
		

GO
/****** Object:  UserDefinedFunction [dbo].[get_bulletins_with_groups]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_bulletins_with_groups](@startdate datetime, @enddate datetime,@grp nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(
				select Distinct(BulletinId) from [CategorizedView] where BulletinId in (

					Select BulletinId from [CategorizedView] 
						Left JOIN [Group] ON([CategorizedView].[GroupId]=[Group].[Id]) 				
						where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < @enddate) 
							and (
								([Group].[Name] like '%'+@grp+'%') or
								([Group].[TagName1] like '%'+@grp+'%') or
								([Group].[TagName2] like '%'+@grp+'%') or
								([Group].[TagName3] like '%'+@grp+'%')
								)	
						
						UNION ALL					
				
						Select BulletinId from [CategorizedView] 
							Left JOIN [Group] ON([CategorizedView].[GroupId]=[Group].[Id])
							Left JOIN [Item] ON([CategorizedView].[ItemId]=[Item].[Id]) 			
							where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < @enddate) 					
								and [Group].[Name] = @grp
				)
			)
		)
GO
/****** Object:  UserDefinedFunction [dbo].[get_bulletins_with_items]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[get_bulletins_with_items](@startdate datetime, @enddate datetime,@item nvarchar(250))
returns table
AS	
	return( 
			Select * from [bulletin] where [state]='Done' and [is_deleted]=0 and [bulletin_id] in 
			(Select Distinct(BulletinId) from [CategorizedView] 
				Left JOIN [Group] ON([CategorizedView].[GroupId]=[Group].[Id]) 
				Left JOIN [Item] ON([CategorizedView].[ItemId]=[Item].[Id]) 
				where ([CategorizedView].[BeginTime] >= @startdate and [CategorizedView].[BeginTime] < @enddate) 
					and (
						([Item].[Name] like '%'+@item+'%') or
						([Item].[TagName1] like '%'+@item+'%') or
						([Item].[TagName2] like '%'+@item+'%') or
						([Item].[TagName3] like '%'+@item+'%')
						)
					)
			)
		

GO
/****** Object:  UserDefinedFunction [dbo].[info_bulletin_table]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[info_bulletin_table]()
returns table
AS	
	return( 
			Select * from [bulletin] 
			where ([state]='Started' or [state]='Scheduled') and [is_deleted]=0
			)
GO
/****** Object:  UserDefinedFunction [dbo].[info_bulletin_time_series]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[info_bulletin_time_series]()
returns table
AS	
	return(
		select begin_time as time, (code + ' - ' + title) as metric, duration as value from bulletin where is_deleted=0 
	)
			
		
GO
/****** Object:  UserDefinedFunction [dbo].[info_group_sla_this_week]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[info_group_sla_this_week]()
returns table
AS	
	return(
		select * from dbo.get_group_sla(dateadd(day,-7,getdate()),getdate())
	)
			
		

GO
SET IDENTITY_INSERT [dbo].[bulletin] ON 

INSERT [dbo].[bulletin] ([bulletin_id], [id], [smtp], [port], [username], [password], [tolist], [cclist], [bcclist], [btype], [priority], [state], [color], [created_by], [code], [title], [detail], [effect], [contact], [begin_time], [end_time], [duration], [ticket_case_url], [ticket_case_id], [resolved_time], [is_resolved], [resolved_by], [temporary_solution], [permanent_solution], [root_cause], [insert_time], [modify_time], [is_automated], [is_deleted]) VALUES (1, 1, N'smtp.gmail.com', N'587', N'itmonitoringcommunity@gmail.com', N'MonitoringCommunity18', N'oguzkaragoz@gmail.com', N'itmonitoringcommunity@gmail.com', NULL, N'Planned Maintenance', N'Medium', N'Done', N'#000000', N'admin', N'BLT20023', N'test3', N'test', N'test,  GROUP B ITEM 1', N'CONTACT B', CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 17:04:48.000' AS DateTime), 60, N'#', N'IR202002', CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, N'admin', N'', N'', N'', CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, 0)
INSERT [dbo].[bulletin] ([bulletin_id], [id], [smtp], [port], [username], [password], [tolist], [cclist], [bcclist], [btype], [priority], [state], [color], [created_by], [code], [title], [detail], [effect], [contact], [begin_time], [end_time], [duration], [ticket_case_url], [ticket_case_id], [resolved_time], [is_resolved], [resolved_by], [temporary_solution], [permanent_solution], [root_cause], [insert_time], [modify_time], [is_automated], [is_deleted]) VALUES (2, 2, N'smtp.gmail.com', N'587', N'itmonitoringcommunity@gmail.com', N'MonitoringCommunity18', N'oguzkaragoz@gmail.com', N'itmonitoringcommunity@gmail.com', NULL, N'Outage', N'Medium', N'Done', N'#000000', N'admin', N'BLT20024', N'test4', N'test', N'test,  GROUP B ITEM 2', N'CONTACT B', CAST(N'2020-04-09 17:04:48.000' AS DateTime), CAST(N'2020-04-09 18:04:48.000' AS DateTime), 60, N'#', N'IR202002', CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, N'admin', N'', N'', N'', CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, 0)
INSERT [dbo].[bulletin] ([bulletin_id], [id], [smtp], [port], [username], [password], [tolist], [cclist], [bcclist], [btype], [priority], [state], [color], [created_by], [code], [title], [detail], [effect], [contact], [begin_time], [end_time], [duration], [ticket_case_url], [ticket_case_id], [resolved_time], [is_resolved], [resolved_by], [temporary_solution], [permanent_solution], [root_cause], [insert_time], [modify_time], [is_automated], [is_deleted]) VALUES (3, 3, N'smtp.gmail.com', N'587', N'itmonitoringcommunity@gmail.com', N'MonitoringCommunity18', N'oguzkaragoz@gmail.com', N'itmonitoringcommunity@gmail.com', NULL, N'Outage', N'Medium', N'Started', N'#000000', N'admin', N'BLT20025', N'test5', N'test', N'test,  GROUP A ITEM 2', N'CONTACT A', CAST(N'2020-04-09 18:04:48.000' AS DateTime), CAST(N'2020-04-09 19:04:48.000' AS DateTime), 60, N'#', N'IR202002', CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, N'admin', N'', N'', N'', CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, 0)
INSERT [dbo].[bulletin] ([bulletin_id], [id], [smtp], [port], [username], [password], [tolist], [cclist], [bcclist], [btype], [priority], [state], [color], [created_by], [code], [title], [detail], [effect], [contact], [begin_time], [end_time], [duration], [ticket_case_url], [ticket_case_id], [resolved_time], [is_resolved], [resolved_by], [temporary_solution], [permanent_solution], [root_cause], [insert_time], [modify_time], [is_automated], [is_deleted]) VALUES (4, 4, N'smtp.gmail.com', N'587', N'itmonitoringcommunity@gmail.com', N'MonitoringCommunity18', N'oguzkaragoz@gmail.com', N'itmonitoringcommunity@gmail.com', NULL, N'Urgent Maintenance', N'Medium', N'Scheduled', N'#000000', N'admin', N'BLT20026', N'test6', N'test', N'test,  GROUP A ITEM 2', N'CONTACT A', CAST(N'2020-04-09 22:04:48.000' AS DateTime), CAST(N'2020-04-09 23:04:48.000' AS DateTime), 60, N'#', N'IR202002', CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, N'admin', N'', N'', N'', CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 16:04:48.000' AS DateTime), 0, 0)
SET IDENTITY_INSERT [dbo].[bulletin] OFF
SET IDENTITY_INSERT [dbo].[CategorizedView] ON 

INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (1, 1, N'BLT20023', N'Planned Maintenance', 60, NULL, NULL, 2, CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 17:04:48.000' AS DateTime))
INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (2, 2, N'BLT20024', N'Outage', 60, NULL, NULL, 2, CAST(N'2020-04-09 17:04:48.000' AS DateTime), CAST(N'2020-04-09 18:04:48.000' AS DateTime))
INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (3, 1, N'BLT20023', N'Planned Maintenance', 60, 2, NULL, NULL, CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 17:04:48.000' AS DateTime))
INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (4, 2, N'BLT20024', N'Outage', 60, 2, NULL, NULL, CAST(N'2020-04-09 17:04:48.000' AS DateTime), CAST(N'2020-04-09 18:04:48.000' AS DateTime))
INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (5, 1, N'BLT20023', N'Planned Maintenance', 60, NULL, 4, NULL, CAST(N'2020-04-09 16:04:48.000' AS DateTime), CAST(N'2020-04-09 17:04:48.000' AS DateTime))
INSERT [dbo].[CategorizedView] ([Id], [BulletinId], [Code], [Type], [Duration], [GroupId], [ItemId], [ContactId], [BeginTime], [EndTime]) VALUES (6, 2, N'BLT20024', N'Outage', 60, NULL, 2, NULL, CAST(N'2020-04-09 17:04:48.000' AS DateTime), CAST(N'2020-04-09 18:04:48.000' AS DateTime))
SET IDENTITY_INSERT [dbo].[CategorizedView] OFF
SET IDENTITY_INSERT [dbo].[Contact] ON 

INSERT [dbo].[Contact] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (1, N'CONTACT A', NULL, NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[Contact] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (2, N'CONTACT B', NULL, NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[Contact] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (3, N'CONTACT C', NULL, NULL, NULL, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[Contact] OFF
SET IDENTITY_INSERT [dbo].[Group] ON 

INSERT [dbo].[Group] ([Id], [Name], [Description], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (1, N'GROUP A', NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[Group] ([Id], [Name], [Description], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (2, N'GROUP B', NULL, NULL, NULL, NULL, 0)
INSERT [dbo].[Group] ([Id], [Name], [Description], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (3, N'GROUP C', NULL, NULL, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[Group] OFF
SET IDENTITY_INSERT [dbo].[Item] ON 

INSERT [dbo].[Item] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (1, N'GROUP A ITEM 2', NULL, 1, N'TAG A2', NULL, NULL, 0)
INSERT [dbo].[Item] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (2, N'GROUP B ITEM 2', NULL, 2, NULL, N'TAG B2', NULL, 0)
INSERT [dbo].[Item] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (3, N'GROUP C ITEM 2', NULL, 3, NULL, NULL, N'TAG C2', 0)
INSERT [dbo].[Item] ([Id], [Name], [Description], [GroupId], [TagName1], [TagName2], [TagName3], [Is_Deleted]) VALUES (4, N'GROUP B ITEM 1', NULL, 2, NULL, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[Item] OFF
ALTER TABLE [dbo].[CategorizedView]  WITH CHECK ADD  CONSTRAINT [FK_CContact] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contact] ([Id])
GO
ALTER TABLE [dbo].[CategorizedView] CHECK CONSTRAINT [FK_CContact]
GO
ALTER TABLE [dbo].[CategorizedView]  WITH CHECK ADD  CONSTRAINT [FK_CGroup] FOREIGN KEY([GroupId])
REFERENCES [dbo].[Group] ([Id])
GO
ALTER TABLE [dbo].[CategorizedView] CHECK CONSTRAINT [FK_CGroup]
GO
ALTER TABLE [dbo].[CategorizedView]  WITH CHECK ADD  CONSTRAINT [FK_CItem] FOREIGN KEY([ItemId])
REFERENCES [dbo].[Item] ([Id])
GO
ALTER TABLE [dbo].[CategorizedView] CHECK CONSTRAINT [FK_CItem]
GO
ALTER TABLE [dbo].[Item]  WITH CHECK ADD  CONSTRAINT [FK_ItemGroup] FOREIGN KEY([GroupId])
REFERENCES [dbo].[Group] ([Id])
GO
ALTER TABLE [dbo].[Item] CHECK CONSTRAINT [FK_ItemGroup]
GO
/****** Object:  StoredProcedure [dbo].[sp_export_csv]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_export_csv](@startdate AS datetime, @enddate AS datetime)
AS
BEGIN
	--EXEC sp_configure 'show advanced options', 1
	--GO
	--RECONFIGURE
	--GO
	--EXEC sp_configure 'xp_cmdshell', 1
	--GO
	--RECONFIGURE
	--GO

	--declare @startdate as datetime = '2020-04-09 13:04:48';
	--declare @enddate as datetime = dateadd(day,1,@startdate);

	declare @sql varchar(8000);
	DECLARE @dir VARCHAR(50);
	declare @name VARCHAR(50);

	set @name = CONVERT(VARCHAR(20), format(@startdate,'yyyyMMddHHmmssffff'), 113);

	SET @dir = 'D:\itemsla_"'+@name+'".csv';

	set @sql =
	'bcp "select * from test.dbo.get_item_sla(''' + cast(@startdate as nvarchar(20)) + ''', ''' + cast(@enddate as nvarchar(20)) + ''' ) " queryout "'+@dir+'" -c -t, -T -S ' + @@SERVERNAME;

	print @sql

	exec master..xp_cmdshell @sql
	--------------------------------------------

	SET @dir = 'D:\groupsla_"'+@name+'".csv';

	set @sql =
	'bcp "select * from test.dbo.get_group_sla(''' + cast(@startdate as nvarchar(20)) + ''', ''' + cast(@enddate as nvarchar(20)) + ''' ) " queryout "'+@dir+'" -c -t, -T -S ' + @@SERVERNAME;

	print @sql

	exec master..xp_cmdshell @sql

	---------------------------------------------

	SET @dir = 'D:\contactsla_"'+@name+'".csv';

	set @sql =
	'bcp "select * from test.dbo.get_contact_sla(''' + cast(@startdate as nvarchar(20)) + ''', ''' + cast(@enddate as nvarchar(20)) + ''' ) " queryout "'+@dir+'" -c -t, -T -S ' + @@SERVERNAME;

	print @sql

	exec master..xp_cmdshell @sql
	---------------------------------------------
END
GO
/****** Object:  StoredProcedure [dbo].[sp_get_data]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Proc [dbo].[sp_get_data]
AS
BEGIN
	truncate table bulletin;
	truncate table CategorizedView;

	insert into bulletin 
		select * from django_db.dbo.bulletins_bulletin WHERE 
		--( begin_time <= GETDATE() AND begin_time >= DATEADD(DAY, -21, GETDATE()))
		is_deleted=0 AND id not in (select BulletinId from CategorizedView);
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_send_mail]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_send_mail](@dir1 AS varchar(50), @dir2 AS varchar(50), @dir3 AS varchar(50))
AS
BEGIN
	--EXEC sp_configure 'show advanced options', 1
	--GO
	--RECONFIGURE
	--GO
	--EXEC sp_configure 'Database Mail XPs', 1
	--GO
	--RECONFIGURE
	--GO

	--EXECUTE msdb.dbo.sysmail_add_account_sp
	--	@account_name = 'TestMailAccount',
	--	@description = 'Mail account for Database Mail',
	--	@email_address = 'itmonitoringcommunity@gmail.com',
	--	@display_name = 'MyAccount',
	--	@username='itmonitoringcommunity@gmail.com',
	--	@password='MonitoringCommunity18',
	--	@mailserver_name = 'smtp.gmail.com',
	--	@port = 587;
	
	--EXECUTE msdb.dbo.sysmail_add_profile_sp
	--	@profile_name = 'TestMailProfile',
	--	@description = 'Profile needed for database mail'


	--EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
	--	@profile_name = 'TestMailProfile',
	--	@account_name = 'TestMailAccount',
	--	@sequence_number = 1

	--EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
	--	@profile_name = 'TestMailProfile',
	--	@principal_name = 'public',
	--	@is_default = 1 ;

	declare @body1 varchar(250);

	------------------------------------------------------------
	
	set @body1 = 'Server :'+@@servername+ ' Test Email Report Group SLA'
	EXEC msdb.dbo.sp_send_dbmail @recipients='oguzkaragoz@gmail.com',
		@subject = 'Test',
		@body = @body1,
		@body_format = 'HTML' ,
		@file_attachments=@dir1;

	------------------------------------------------------------

	set @body1 = 'Server :'+@@servername+ ' Test Email Report Item SLA'
	EXEC msdb.dbo.sp_send_dbmail @recipients='oguzkaragoz@gmail.com',
		@subject = 'Test',
		@body = @body1,
		@body_format = 'HTML' ,
		@file_attachments=@dir2;

	------------------------------------------------------------

	set @body1 = 'Server :'+@@servername+ ' Test Email Report Contact SLA'
	EXEC msdb.dbo.sp_send_dbmail @recipients='oguzkaragoz@gmail.com',
		@subject = 'Test',
		@body = @body1,
		@body_format = 'HTML' ,
		@file_attachments=@dir3;


	------------------------------------------------------------

	SELECT * FROM msdb.dbo.sysmail_event_log
	--delete FROM msdb.dbo.sysmail_event_log	
END
GO
/****** Object:  Trigger [dbo].[CategorizeBulletinDelete]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create trigger [dbo].[CategorizeBulletinDelete] on [dbo].[bulletin]
for delete 
as
 begin

	declare @InsertedId int;
	select @InsertedId=[bulletin_id] from deleted;

	Delete from [CategorizeBulletinView] where bulletin_id = @InsertedId;

end

GO
/****** Object:  Trigger [dbo].[CategorizeBulletinInsert]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @DetailBlt nvarchar(4000);
	Declare @EffectBlt nvarchar(4000);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;
	
DECLARE crsContact CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Contact] where [Is_deleted]=0 order by [Name];
OPEN crsContact;     
FETCH NEXT FROM crsContact INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
where 
	(([contact] like '%'+@Name+'%')
	or ([contact] like '%'+@TagName1+'%')
	or ([contact] like '%'+@TagName2+'%')
	or ([contact] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,null,null,@Id,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsContact INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsContact;  
	DEALLOCATE crsContact;

	DECLARE crsGroup CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Group] where [Is_deleted]=0 order by [Name];
OPEN crsGroup;     
FETCH NEXT FROM crsGroup INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
	where 
	(([detail] like '%'+@Name+'%') or ([effect] like '%'+@Name+'%') 
	or ([detail] like '%'+@TagName1+'%') or ([Effect] like '%'+@TagName1+'%')
	or ([detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
	or ([detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,null,null,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsGroup INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsGroup;  
	DEALLOCATE crsGroup;

	DECLARE crsItem CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Item] where [Is_deleted]=0 order by [Name];
OPEN crsItem;     
FETCH NEXT FROM crsItem INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
	where 
	(([detail] like '%'+@Name+'%') or ([effect] like '%'+@Name+'%') 
	or ([detail] like '%'+@TagName1+'%') or ([Effect] like '%'+@TagName1+'%')
	or ([detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
	or ([detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,null,@Id,null,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsItem INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsItem;  
	DEALLOCATE crsItem;

end

GO
/****** Object:  Trigger [dbo].[CategorizeBulletinUpdate]    Script Date: 4/26/2020 2:16:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

	Declare @IdBlt int;
	Declare @CodeBlt nvarchar(250);
	Declare @DurationBlt nvarchar(250);
	Declare @DetailBlt nvarchar(4000);
	Declare @EffectBlt nvarchar(4000);
	Declare @TypeBlt nvarchar(250);
	Declare @BeginTimeBlt datetime;
	Declare @EndTimeBlt datetime;
	
DECLARE crsContact CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Contact] where [Is_deleted]=0 order by [Name];
OPEN crsContact;     
FETCH NEXT FROM crsContact INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
where 
	(([contact] like '%'+@Name+'%')
	or ([contact] like '%'+@TagName1+'%')
	or ([contact] like '%'+@TagName2+'%')
	or ([contact] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,null,null,@Id,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsContact INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsContact;  
	DEALLOCATE crsContact;

	DECLARE crsGroup CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Group] where [Is_deleted]=0 order by [Name];
OPEN crsGroup;     
FETCH NEXT FROM crsGroup INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
	where 
	(([detail] like '%'+@Name+'%') or ([effect] like '%'+@Name+'%') 
	or ([detail] like '%'+@TagName1+'%') or ([Effect] like '%'+@TagName1+'%')
	or ([detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
	or ([detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@Id,null,null,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsGroup INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsGroup;  
	DEALLOCATE crsGroup;

	DECLARE crsItem CURSOR FOR SELECT [Id] ,[Name] ,[TagName1],[TagName2] ,[TagName3] FROM [Item] where [Is_deleted]=0 order by [Name];
OPEN crsItem;     
FETCH NEXT FROM crsItem INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
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


	----------------------------------------------------------		
	DECLARE crsBlt CURSOR FOR SELECT [bulletin_id],[code], [duration], [btype],[begin_time],[end_time] from [bulletin] 
	where 
	(([detail] like '%'+@Name+'%') or ([effect] like '%'+@Name+'%') 
	or ([detail] like '%'+@TagName1+'%') or ([Effect] like '%'+@TagName1+'%')
	or ([detail] like '%'+@TagName2+'%') or ([Effect] like '%'+@TagName2+'%')
	or ([detail] like '%'+@TagName3+'%') or ([Effect] like '%'+@TagName3+'%')) 
	and [state]='Done' and [is_deleted]=0;

			OPEN crsBlt;     
			FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;  
			WHILE @@FETCH_STATUS=0   
			BEGIN 											
				insert into [CategorizedView] (BulletinId,Code,Duration,[Type],[GroupId],[ItemId],[ContactId],[BeginTime],[EndTime])  values(@IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,null,@Id,null,@BeginTimeBlt,@EndTimeBlt);
								
				FETCH NEXT FROM crsBlt INTO @IdBlt,@CodeBlt,@DurationBlt,@TypeBlt,@BeginTimeBlt,@EndTimeBlt;   
			END
			CLOSE crsBlt;  
			DEALLOCATE crsBlt;								
	---------------------------------------------------------------------------------
	
		FETCH NEXT FROM crsItem INTO @Id,@Name,@TagName1,@TagName2,@TagName3;  
	END
	CLOSE crsItem;  
	DEALLOCATE crsItem;
   
end

GO
USE [master]
GO
ALTER DATABASE [test] SET  READ_WRITE 
GO
