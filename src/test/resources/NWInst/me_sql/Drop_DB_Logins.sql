IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'SAPMEINT')
DROP LOGIN [SAPMEINT]
GO

IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'SAPMEODS')
DROP LOGIN [SAPMEODS]
GO

IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'SAPMEWIP')
DROP LOGIN [SAPMEWIP]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'SAPMEINT')
DROP DATABASE [SAPMEINT]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'SAPMEODS')
DROP DATABASE [SAPMEODS]
GO

USE [master]
GO

IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'SAPMEWIP')
DROP DATABASE [SAPMEWIP]
GO