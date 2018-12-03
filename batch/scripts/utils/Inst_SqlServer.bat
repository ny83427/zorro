@echo off
title Installing SqlServer 2008R2......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

sc query | findstr MSSQLSERVER
if %ERRORLEVEL% GTR 0 (
	if not exist %MFG_DIR%\Sqlserver2008\51044827\SQL4SAP.vbs (
		echo SqlServer 2008R2 installation files not found, please check and correct it first!
		pause
		exit
	)
	
	echo We start to install SQL Server 2008 R2 at : %date% %time%
	cd /d %MFG_DIR%\Sqlserver2008\51044827
	xcopy %MFG_DIR%\NWInst\Template\utils\SILENT_SQL4SAP.vbs %MFG_DIR%\Sqlserver2008\51044827 /d /y
	rem we will use customized vbscript instead of standard to avoid 3 clicks on OK button
	if exist SILENT_SQL4SAP.vbs (
		start /wait C:\Windows\System32\cscript.exe SILENT_SQL4SAP.vbs
	) else (
		start /wait C:\Windows\System32\cscript.exe SQL4SAP.vbs
	)
) else (
	echo SQL Server 2008 R2 installed already before.
)