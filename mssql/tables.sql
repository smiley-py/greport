CREATE TABLE [dbo].[bulletin](
	[bulletin_id] [int] IDENTITY(1,1) NOT NULL,
	
	id integer NOT NULL,

    smtp [nvarchar](250) NOT NULL,
    port [nvarchar](250) NOT NULL,
    username [nvarchar](250) NOT NULL,
    password [nvarchar](250) NOT NULL,
    tolist [nvarchar](250),
    cclist [nvarchar](250),
    bcclist [nvarchar](250),
    
    btype [nvarchar](250) NOT NULL, 
    priority [nvarchar](250),
    state [nvarchar](250) NOT NULL,
    color [nvarchar](250),

    created_by [nvarchar](250) NOT NULL,
    code [nvarchar](250) NOT NULL,
    title [nvarchar](250) NOT NULL,
    detail [text] NOT NULL,
    effect [text] NOT NULL,
    contact [nvarchar](250),
    
    begin_time datetime,
    end_time datetime,
    duration integer DEFAULT 0,

    ticket_case_url text DEFAULT '#',
    ticket_case_id text,

    resolved_time datetime DEFAULT CURRENT_TIMESTAMP, 
    is_resolved integer DEFAULT 0,
    resolved_by [nvarchar](250),
    temporary_solution [nvarchar](250),
    permanent_solution [nvarchar](250),
    root_cause [nvarchar](250),
    
    insert_time datetime, 
    modify_time datetime,  
    is_deleted integer DEFAULT 0,
	PRIMARY KEY ([bulletin_id])
	);

CREATE TABLE [dbo].[Group](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	Is_Deleted integer DEFAULT 0,
	PRIMARY KEY (Id),
	);

CREATE TABLE [dbo].[Item](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[GroupId] [int] NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	Is_Deleted integer DEFAULT 0,
	PRIMARY KEY (Id),
	CONSTRAINT FK_ItemGroup FOREIGN KEY (GroupId) REFERENCES [Group](Id)
	);


CREATE TABLE [dbo].[Contact](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[GroupId] [int] NULL,
	[TagName1] [nvarchar](250) NULL,
	[TagName2] [nvarchar](250) NULL,
	[TagName3] [nvarchar](250) NULL,
	Is_Deleted integer DEFAULT 0,
	PRIMARY KEY (Id)
	);

CREATE TABLE [dbo].[CategorizedView](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BulletinId] [int] NOT NULL,
	[Code] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](500) NULL,
	[Duration] [nvarchar](250) NULL,
	[GroupId] [int] NULL,
	[ItemId] [int] NULL,
	[ContactId] [int] NULL,
	[BeginTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	PRIMARY KEY (Id),
	CONSTRAINT FK_CGroup FOREIGN KEY (GroupId) REFERENCES [Group](Id),
	CONSTRAINT FK_CItem FOREIGN KEY (ItemId) REFERENCES [Item](Id),
	CONSTRAINT FK_CContact FOREIGN KEY (ContactId) REFERENCES [Contact](Id)
	);

