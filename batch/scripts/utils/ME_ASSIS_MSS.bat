@echo off
title Preparing SqlServer database enviroment for ME......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

call %MFG_DIR%\NWInst\utils\Inst_SqlServer.bat

echo We start to install XA, enable XaTransaction, create databases, logins and usermappings at %date% %time%
if exist "%XAPATH%\sqljdbc_xa.dll" (
	echo XA Transaction, Mixed Authentication mode enabled already before.
	goto create_db_logins
)
rem copy sqljdbc_xa.dll and enable XaTransactions
xcopy %MFG_SHARE%\sqljdbc_2.0.1803.100_enu.exe %MFG_DIR%\rawfiles\ /d /y
cd /d %MFG_DIR%\rawfiles
winrar x -o-- sqljdbc_2.0.1803.100_enu.exe *.*
xcopy %MFG_DIR%\rawfiles\sqljdbc_2.0\enu\xa\x64\sqljdbc_xa.dll "%XAPATH%" /d /y
powershell Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name XaTransactions -Value 1

rem install xa via executing sql statements
sqlcmd -s localhost\ -i %SQL_DIR%\xa_install.sql
rem change authentication mode to 'mixed'
sqlcmd -s localhost\ -i %SQL_DIR%\Change_To_Mixed_Mode.sql

rem restart sqlserver
net stop SQLSERVERAGENT
net stop MSSQLSERVER

net start MSSQLSERVER
net start SQLSERVERAGENT

:create_db_logins
rem create database via execute sql statements
if not exist %DRIVER%:\SAP_MFG_DB mkdir %DRIVER%:\SAP_MFG_DB
if not exist %DRIVER%:\SAP_MFG_DB\%SID%_ME_WIP.mdf (
	java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper SQL,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
	sqlcmd -s localhost\ -i %SQL_DIR%\Create_DB_Logins_%SID%.sql && echo database creation and settings finished successfully at %date% %time%!
) else (
	echo database creation and settings finished already.
) 
echo We finished all things on database level at : %date% %time%