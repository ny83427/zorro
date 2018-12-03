IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AMU_ME_INT')
DROP LOGIN [AMU_ME_INT]
GO

IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AMU_ME_ODS')
DROP LOGIN [AMU_ME_ODS]
GO

IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'AMU_ME_WIP')
DROP LOGIN [AMU_ME_WIP]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'AMU_ME_INT')
DROP DATABASE [AMU_ME_INT]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'AMU_ME_ODS')
DROP DATABASE [AMU_ME_ODS]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'AMU_ME_WIP')
DROP DATABASE [AMU_ME_WIP]
GO