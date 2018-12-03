@echo off
title MFG Development Enviroment Set Up Script is running for you......
:: Run this script like MFG_INST.bat DEV to switch to Development mode
if [%1] == [] (set RUNNING_MODE=PRD) else (set RUNNING_MODE=%1%)

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
call %MFG_TMP_DIR%\Set_Parameters.bat INST

echo We start at : %date% %time%, Tech Info: %SID%, %NR1%, %NR2%, %PASSWORD%, %DATABASE_TYPE%
if exist C:\TMP\SWPM rd C:\TMP\SWPM /s /q
call %MFG_DIR%\NWInst\utils\Copy_Extract_Files.bat

rem install oracle if user choose database type ORA (after JDK installation finished and response file adjusted)
if %DATABASE_TYPE% == ORA call %MFG_DIR%\NWInst\utils\Inst_Oracle.bat

rem install sqlserver if user choose database type MSS
if %DATABASE_TYPE% == MSS call %MFG_DIR%\NWInst\utils\Inst_SqlServer.bat

rem install sqlserver/oracle if needed, create database, logins and user mappings for ME
if %INST_CASE% == ME (
	if %DATABASE_TYPE% == ORA (call %MFG_DIR%\NWInst\utils\ME_ASSIS_ORA.bat) else (call %MFG_DIR%\NWInst\utils\ME_ASSIS_MSS.bat)
)

rem start netweaver installation in unattended mode, in case it's installed already(via checking whether service exists or not), simply skip it
sc query | findstr SAP%SID%_%NR1%
if %ERRORLEVEL% GTR 0 (
	title Installing NetWeaver Java AS 7.31 in unattended installation mode......
	echo We start to install NetWeaver For Java 7.31 at : %date% %time%
	start /wait /d "%MFG_DIR%\SWPM\" sapinst.exe SAPINST_PARAMETER_CONTAINER_URL=%MFG_DIR%\NWInst\custom_inst\inifile.xml SAPINST_CWD=%MFG_DIR%\NWInst\dir_inst SAPINST_EXECUTE_PRODUCT_ID=NW_Java_OneHost:NW731.%DATABASE_TYPE%.PD SAPINST_SKIP_DIALOGS=true -nogui -noguiserver
	if %ERRORLEVEL% GTR 0 if not exist %MFG_DIR%\NWInst\dir_inst\installationSuccesfullyFinished.dat (
		echo NW Server Instance %SID% J%NR1% failed to install, please check "%MFG_DIR%\NWInst\dir_ins\LogAnalyzer.html" for detail
		pause
		exit
	) else (
		if %GENERATE_OPER_SCRIPTS% == Y (
			java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper BAT,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
		)
		cd /d %MFG_DIR%\NWInst
		rename custom_inst custom_inst_%SID%
		rename dir_inst dir_inst_%SID%
		echo NW Server Instance %SID% J%NR1% installed successfully at %date% %time%.
	)		
) else (
	echo NW Server Instance %SID% J%NR1% installed already.
)
if %RUNNING_MODE% == DEV goto ending

if %DATABASE_TYPE% == ADA (
	rem activate log overwritten mode for MAXDB
	if exist %DRIVER%:\sapdb\%SID%\db\pgm\dbmcli.exe (
		cd /d %DRIVER%:\sapdb\%SID%\db\pgm
		dbmcli -u SUPERDBA,%PASSWORD% -d %SID% -c db_execute SET LOG AUTO OVERWRITE ON
		echo MAXDB log overwritten mode activated successfully.
	)
	rem install maxdb studio
	if not exist %DEV_DIR%\MAXDB_STUDIO\dbstudio.exe (
		winrar x -o-- %MFG_DIR%\rawfiles\maxdb-studio-desktop-win-64bit-x86_64-7_9_08_09.zip *.* %MFG_DIR%\rawfiles
		cd /d %MFG_DIR%\rawfiles\maxdb-studio-desktop-win-64bit-x86_64-7_9_08_09
		winrar x -o-- DBSTUDIO.TGZ *.* %DEV_DIR%\MAXDB_STUDIO\
		echo MAXDB Studio installed successfully at "%DEV_DIR%\MAXDB_STUDIO"
	) else (
		echo MAXDB Studio installed already at "%DEV_DIR%\MAXDB_STUDIO"
	)
)

if not exist %DRIVER%:\usr\sap\%SID%\KERNEL_LOG.txt (
	goto update_nw_kernel
) else (
	echo NW %SID%,%NR1% Kernel Updated already before.
	goto update_host_agent
)

:update_nw_kernel
call %MFG_DIR%\NWInst\utils\Update_Kernel.bat

:update_host_agent
if exist %DRIVER%:\usr\sap\HOSTAGENT_LOG.txt (
	echo NW HostAgent Upgraded already before.
	goto jspm_sp06
)
call %MFG_DIR%\NWInst\utils\Upgrade_HostAgent.bat

:jspm_sp06
if exist %DRIVER%:\usr\sap\%SID%\JSPM_LOG.txt (
	echo JSPM SP06 patched already before.
	goto nwbasis_sp06
)
title Applying JSPM support package......
rem update JSPM, we will clean previous sca or sar files first
if exist %TRANS_DIR%\*.SCA del %TRANS_DIR%\*.SCA
if exist %TRANS_DIR%\*.SAR del %TRANS_DIR%\*.SAR
echo We start to apply JSPM SP06 at : %date% %time%
xcopy %MFG_DIR%\NWPatch06\JSPM06_0-10009492.SCA %TRANS_DIR% /d /y
call %JSPM%\jspm_cmd.bat inbox -locationpath=%INBOX% -credentials=%AUTH% -install=true -patch=true -upgrade=false -errorOnMultiple=false
@echo off

if ERRORLEVEL 8 ( 
	echo Failed to update JSPM to SP06, please check logs at "%DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\JSPM\log" and fix the issue first.
	pause
	exit
)
echo NW %SID%,%NR1%,%PASSWORD%,%DATABASE_TYPE% JSPM SP06 patched at %date% %time% > %DRIVER%:\usr\sap\%SID%\JSPM_LOG.txt
echo We finished applying JSPM SP06 at : %date% %time%

:nwbasis_sp06
if exist %DRIVER%:\usr\sap\%SID%\NWBASIS_LOG.txt (
	echo NW Basis SP06 patched, XMII and MII_ADMIN 15.0 deployed already before.
	goto me_meint_15
)
title Applying NW Basis Components support packages......
echo We start to apply NW BASIS SP06, XMII and MII_ADMIN 15.0 at : %date% %time%
rem update NW BASIS, deploy XMII and MII_ADMIN 15.0
xcopy %MFG_DIR%\NWPatch06\*.SCA %TRANS_DIR% /d /y
xcopy %MFG_DIR%\NWPatch06\*.SAR %TRANS_DIR% /d /y
rem do not deploy Adobe Service SP06 for ME
if %INST_CASE% == ME (
	if exist %TRANS_DIR%\ADSSAP06P_3-10009589.SCA del %TRANS_DIR%\ADSSAP06P_3-10009589.SCA
	xcopy %MFG_DIR%\MFG_SCAS\XMII01_0-10013502.SCA %TRANS_DIR% /d /y
	xcopy %MFG_DIR%\MFG_SCAS\MIIADMIN01_0-10013501.SCA %TRANS_DIR% /d /y
) else (
	xcopy %MFG_DIR%\MFG_SCAS\XMII03_0.sca %TRANS_DIR% /d /y
	xcopy %MFG_DIR%\MFG_SCAS\MIIADMIN03_0.sca %TRANS_DIR% /d /y
)
xcopy %MFG_DIR%\MFG_SCAS\ASSIGN_XMII_ROLE*.sca %TRANS_DIR% /d /y
call %JSPM%\jspm_cmd.bat inbox -locationpath=%INBOX% -credentials=%AUTH% -install=true -patch=true -upgrade=false -errorOnMultiple=false
@echo off

if %ERRORLEVEL% == 0 (
	echo NW SP06 Patched, XMII and MII_ADMIN deployed successfully.
	del %TRANS_DIR%\*.SCA
	del %TRANS_DIR%\*.SAR
) else (
	call %JSPM%\jspm_cmd.bat inbox -locationpath=%INBOX% -credentials=%AUTH% -install=true -patch=true -upgrade=false -errorOnMultiple=false
)
@echo off
if ERRORLEVEL 8 (
	echo Failed to update NW BASIS SP06 and deploy XMII/MII_ADMIN, please check logs at "%DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\JSPM\log" and fix the issue first.
	pause
	exit
)
echo NW %SID%,%NR1%,%PASSWORD%,%DATABASE_TYPE% NW BASIS SP06 patched, XMII and MII_ADMIN 15.0 deployed at %date% %time% > %DRIVER%:\usr\sap\%SID%\NWBASIS_LOG.txt
echo We finished applying NW BASIS SP06, XMII and MII_ADMIN 15.0 at : %date% %time%

:me_meint_15
if exist %DRIVER%:\usr\sap\%SID%\ME15_LOG.txt (
	echo MECORE, MECTC, MEINT, MEINTCTC 15.0 and etc deployed already before.
	goto ending
)
title Assigning SAP_XMII_ADMINISTRATOR role to NWA Administrator......
java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper ASSIGN_XMII_ADMIN_ROLE,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
if ERRORLEVEL 8 (
	start http://%computername%:5%NR1%00/useradmin
	echo Please assign role SAP_XMII_ADMINISTRATOR to NWA administrator manually, or you cannot access XMII.
	pause
) else (
	start http://%computername%:5%NR1%00/XMII
)

if %INST_CASE% == MII (
	echo CONGRATULATIONS! All things needed for XMII are ready.
	echo We end at : %date% %time%
	pause
	exit
)

rem Switch On this flag if we finally succeed in CTC Auto Execution in the future...
set EXECUTE_CTC=N
title Deploying MECORE, MECTC, MEINT, MEINTCTC and etc......
echo We start to apply MECORE, MECTC, MEINT, MEINTCTC and etc at : %date% %time%
rem deploy MECORE, MECTC, MEINT, MEINTCTC and etc
if %EXECUTE_CTC% == Y (	
	xcopy %MFG_DIR%\MFG_SCAS\SAPMECORE00_1-20011936.SCA %TRANS_DIR% /d /y
	xcopy %MFG_DIR%\MFG_SCAS\SAPMEINT00_0-20011938.SCA  %TRANS_DIR% /d /y
	rem copy slightly hacked CTC SCAs for dark mode execution
	xcopy %MFG_DIR%\MFG_SCAS\SAPMECTC_HACK*.SCA  %TRANS_DIR% /d /y
	xcopy %MFG_DIR%\MFG_SCAS\SAPMEINTCTC_HACK*.SCA  %TRANS_DIR% /d /y
	xcopy %MFG_DIR%\rawfiles\sqljdbc_2.0\enu\sqljdbc4.jar %DRIVER%:\usr\sap\%SID%\SYS\global\ctc\uploadedFiles\com\sap\me\ctc\drivers\ /d /y
	xcopy %MFG_DIR%\rawfiles\sqljdbc_2.0\enu\sqljdbc4.jar %DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\cluster\server0\.\temp\dbpool\_VMJDBC\ /d /y
	xcopy %MFG_DIR%\rawfiles\sqljdbc_2.0\enu\sqljdbc4.jar %DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\cluster\bin\ext\VMJDBC\ /d /y
) else (
	xcopy %MFG_DIR%\MFG_SCAS\SAPME*.SCA %TRANS_DIR% /d /y
)
xcopy %MFG_DIR%\MFG_SCAS\OEEMII*.SCA %TRANS_DIR% /d /y
xcopy %MFG_DIR%\MFG_SCAS\MIIBUILDT*.SCA %TRANS_DIR% /d /y
xcopy %MFG_DIR%\MFG_SCAS\XMIIMIGRATION*.SCA %TRANS_DIR% /d /y

call %JSPM%\jspm_cmd.bat inbox -locationpath=%INBOX% -credentials=%AUTH% -install=true -patch=true -upgrade=false -errorOnMultiple=false
@echo off

if %ERRORLEVEL% == 0 (
	echo MECORE, MECTC, MEINT, MEINTCTC and ect deployed successfully.	
) else (
	call %JSPM%\jspm_cmd.bat inbox -locationpath=%INBOX% -credentials=%AUTH% -install=true -patch=true -upgrade=false -errorOnMultiple=false
)
@echo off
if ERRORLEVEL 8 (
	echo Failed to deploy ME/MEINT and etc, please check logs at "%DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\JSPM\log" and fix the issue first.
	pause
	exit
)
echo NW %SID%,%NR1%,%PASSWORD%,%DATABASE_TYPE% MECORE, MECTC, MEINT, MEINTCTC 15.0 and etc deployed at %date% %time% > %DRIVER%:\usr\sap\%SID%\ME15_LOG.txt
echo We finished applying MECORE, MECTC, MEINT, MEINTCTC and etc at : %date% %time%

if %EXECUTE_CTC% == Y (
	title Executing CTC Tasks......
	java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper MECTC1,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
	call %MFG_DIR%\NWInst\utils\restart_nw.bat Restart
	java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper MECTC2,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
	if %ERRORLEVEL% NEQ 0 (
		call %MFG_DIR%\NWInst\utils\restart_nw.bat Restart
		goto ctc_tasks
	) else (
		echo CONGRATULATIONS! All I can do is done for you - 4 CTC tasks have been executed also.
		"C:\Program Files\Internet Explorer\iexplore.exe" http://%computername%:5%NR1%00/manufacturing
		goto ending
	)
) else (
	goto ctc_tasks
)

:ctc_tasks
rem start NWA home page and CTC document for reference
echo CONGRATULATIONS! All I can do is done for you. Now you only need to execute 4 CTC tasks for ME and MEINT.
start http://%computername%:5%NR1%00/nwa
start %MFG_DIR%\NWInst\utils\CTC.docx

:ending
title MFG Development Enviroment Set Up Script has completed its mission, THANK YOU FOR USING IT!
if exist del %TRANS_DIR%\*.SCA del %TRANS_DIR%\*.SCA
echo We end at : %date% %time%, have a nice day~
pause