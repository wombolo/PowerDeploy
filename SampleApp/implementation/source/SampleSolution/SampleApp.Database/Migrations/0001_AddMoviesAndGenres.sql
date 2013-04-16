﻿/****** Object:  Table [dbo].[Movies]    Script Date: 15.04.2013 13:52:33 ******/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Movies')
BEGIN

	CREATE TABLE [dbo].[Movies](
		[Id] [int] NOT NULL,
		[Title] [nchar](10) NULL,
		[Abstract] [nchar](100) NULL,
		[Year] [nchar](10) NULL,
		[ImdbId] [nchar](10) NULL,
	PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]


END


/****** Object:  Table [dbo].[Genres]    Script Date: 15.04.2013 13:49:51 ******/
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Genres')
BEGIN
	CREATE TABLE [dbo].[Genres](
		[Id] [int] NOT NULL,
	PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END