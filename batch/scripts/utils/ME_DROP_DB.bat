@echo off
title Dropping databases, logins......
if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

cd /d %SQL_DIR%
if exist %SQL_DIR%\Drop_DB_Logins_%SID%.sql if exist "%MSSBIN%\sqlcmd.exe" (
	sqlcmd -s localhost\ -i Drop_DB_Logins_%SID%.sql && echo Databases, logins of %SID%_ME_WIP, %SID%_ME_ODS, %SID%_ME_INT dropped.
	del %SQL_DIR%\Drop_DB_Logins_%SID%.sql
)