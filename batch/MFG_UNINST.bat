@echo off
title MFG Development Enviroment Set Up Script is running for you......
set MFG_TMP_DIR=C:\Users\%username%\Downloads\MFGScripts
:: replace share folder address(cannot access share folder below), FQDN(not in APJ) if necessary
set ROOT_SHARE=\\cnpvgl000.pvgl.sap.corp\Restricted
set MFG_SHARE=%ROOT_SHARE%\I2D\MFG\50_Software
set FQDN=apj.global.corp.sap

rem check network first: can we access this share folder?
if not exist %MFG_TMP_DIR% mkdir %MFG_TMP_DIR%
if exist %MFG_TMP_DIR%\HideCmd.log del %MFG_TMP_DIR%\HideCmd.log
dir %ROOT_SHARE%\I2D >> %MFG_TMP_DIR%\HideCmd.log
if %ERRORLEVEL% NEQ 0 (
	echo Please check and ensure you can access share folder: %MFG_SHARE%.
	pause
	exit
)

xcopy %MFG_SHARE%\Zorro\Scripts\utils\* %MFG_TMP_DIR%\ /d /y /e  >> %MFG_TMP_DIR%\HideCmd.log
call %MFG_TMP_DIR%\Set_Parameters.bat UNINST

echo We start to uninstall NW Java Server Instance %SID%, %NR1%, %DATABASE_TYPE% at %date% %time%

sc query | findstr SAP%SID%_%NR1%
if %ERRORLEVEL% == 0 (
	title Uninstalling NetWeaver Java AS 7.31 in unattended mode......
	start /wait /d "%MFG_DIR%\SWPM\" sapinst.exe SAPINST_PARAMETER_CONTAINER_URL=%MFG_DIR%\NWInst\custom_uninst\inifile.xml SAPINST_CWD=%MFG_DIR%\NWInst\dir_uninst SAPINST_EXECUTE_PRODUCT_ID=NW_Uninstall:GENERIC.IND.PD SAPINST_SKIP_DIALOGS=true -nogui -noguiserver
	if %ERRORLEVEL% GTR 0 if not exist %MFG_DIR%\NWInst\dir_uninst\installationSuccesfullyFinished.dat (
		echo NW Server Instance %SID% J%NR1% failed to uninstall, please check "%MFG_DIR%\NWInst\dir_uninst\LogAnalyzer.html" for detail
		pause
		exit
	) 
	cd /d %MFG_DIR%\NWInst
	rename custom_uninst custom_uninst_%SID%
	rename dir_uninst dir_uninst_%SID%
	
	call %MFG_DIR%\NWInst\utils\ME_DROP_DB.bat
	if exist C:\Users\%username%\Desktop\*_%SID%.bat del C:\Users\%username%\Desktop\*_%SID%.bat
	if exist %DRIVER%:\sap*.tmp del %DRIVER%:\sap*.tmp
	if exist C:\sap*.tmp del C:\sap*.tmp
) else (
	echo NW Java Server Instance %SID%,%NR1% doesn't exist, it seems had been uninstalled already before.
)

title MFG Development Enviroment Set Up Script has completed its mission, THANK YOU FOR USING IT!
echo We finished uninstalling NW Java Server Instance %SID%, %NR1%, %DATABASE_TYPE% at : %date% %time%
pause