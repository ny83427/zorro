@echo off
title Setting enviroment parameters......
if not defined MFG_TMP_DIR set MFG_TMP_DIR=C:\Users\%username%\Downloads\MFGScripts
if not defined ROOT_SHARE set ROOT_SHARE=\\cnpvgl000.pvgl.sap.corp\Restricted
if not defined MFG_SHARE set MFG_SHARE=%ROOT_SHARE%\I2D\MFG\50_Software
rem SCENARIO can be INST, UNINST and SINGLETEST(for sub module scripts test purpose)
if [%1] == [] (set SCENARIO=SINGLETEST) else (set SCENARIO=%1%)
set WAIT_TIME=12
if %SCENARIO% == INST (	
	echo If you input nothing within %WAIT_TIME% seconds, we will choose to set up enviroment for MII only.
	choice /C YN /M "Choose installation scenario(Y:MII, N:ME)" /t:%WAIT_TIME% /d:Y
	if ERRORLEVEL 1 set INST_CASE=MII
	if ERRORLEVEL 2 set INST_CASE=ME
) else (
	set INST_CASE=ME
)

echo If you input nothing within %WAIT_TIME% seconds, we will set parameters by default as below:
echo SID=MFG, NR1=00, NR2=01, PASSWORD=MFG123456, DATABASE_TYPE=ADA	
choice /C YN /M "Do you want to use default enviroment settings without input?" /t:%WAIT_TIME% /d:Y
if ERRORLEVEL 1 set INPUT=Y
if ERRORLEVEL 2 set INPUT=N
if %INPUT% == N (
	set /p SID=Enter SID: || set SID=MFG
	set /p NR1=Enter NR1: || set NR1=00
	set /p NR2=Enter NR2: || set NR2=01
	set /p PASSWORD=Enter Password: || set PASSWORD=MFG123456
	if %SCENARIO% == INST (	
		choice /C YN /M "Do you want to generate scripts at desktop so that you can start/restart/stop NW without password input?"  /t:%WAIT_TIME% /d:Y
		if ERRORLEVEL 1 set GENERATE_OPER_SCRIPTS=Y
		if ERRORLEVEL 2 set GENERATE_OPER_SCRIPTS=N
	)	
	choice /C AMO /M "Choose database for NetWeaver installation:(A: MAXDB, M: SqlServer, O: Oracle)"
	if ERRORLEVEL 1 set DATABASE_TYPE=ADA
	if ERRORLEVEL 2 set DATABASE_TYPE=MSS
	if ERRORLEVEL 3 set DATABASE_TYPE=ORA
) else (
	rem == Customizing part begin, you can change value of these parameters according to your requirement ==
	set SID=MFG
	set NR1=00
	set NR2=01
	set PASSWORD=MFG123456
	rem currently we support MaxDB(ADA), SqlServer(MSS) and Oracle(ORA), however GUI mode would be more stable for MSS
	set DATABASE_TYPE=ADA
	rem by default we will generate Start/Stop/Restart_${SID}.bat in your desktop so that you can start/restart/stop NW without password input
	set GENERATE_OPER_SCRIPTS=Y
	rem == Customizing part end(if you are using a different share folder, pay attention to Copy_Extract_Files.bat) ==
)

rem we need to install jdk before running java code
xcopy %MFG_SHARE%\Java\*.exe C:\Users\%username%\Downloads\ /d /y >> %MFG_TMP_DIR%\HideCmd.log
cd /d %MFG_TMP_DIR%
call Inst_JDK.bat
rem determine root driver first, since user(for example: MFG SH Team Member who have T540P laptop) might have more than 2 hard disks
set DRIVER=C
set CLASSPATH=%MFG_TMP_DIR%\mfginst.jar
java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper DETERMINE_DRIVER
if %ERRORLEVEL% == 4 set DRIVER=D
if %ERRORLEVEL% == 8 set DRIVER=E
if %ERRORLEVEL% == 16 set DRIVER=F
if %ERRORLEVEL% == 32 set DRIVER=G
if %ERRORLEVEL% == 64 set DRIVER=H
if %ERRORLEVEL% == 128 set DRIVER=I
if %ERRORLEVEL% == 256 set /p DRIVER=Enter Disk Driver:

set MFG_DIR=%DRIVER%:\MFG_INST
set DEV_DIR=%DRIVER%:\MFG_DEV
if %SCENARIO% == INST (
	echo %MFG_DIR% will be used to download all the raw files needed.
	echo %DEV_DIR% will be used to set up development enviroment.
)
set SQL_DIR=%MFG_DIR%\NWInst\me_sql
set MSSBIN=C:\Program Files\Microsoft SQL Server\100\Tools\Binn
set XAPATH=C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
set PATH=%PATH%;C:\WINDOWS;C:\Program Files (x86)\Java\jdk1.6.0_45\bin;C:\Program Files\WinRAR;%MSSBIN%;

rem clear previous installation xml and directory
if exist %MFG_DIR%\NWInst\dir_%SCENARIO% rd %MFG_DIR%\NWInst\dir_%SCENARIO% /s /q
if exist %MFG_DIR%\NWInst\custom_%SCENARIO% rd %MFG_DIR%\NWInst\custom_%SCENARIO% /s /q

rem copy unattended installation configuration files
xcopy %MFG_SHARE%\Zorro\Scripts\* %MFG_DIR%\NWInst\Template\ /d /y /e >> %MFG_TMP_DIR%\HideCmd.log
xcopy %MFG_DIR%\NWInst\Template\* %MFG_DIR%\NWInst\ /d /y /e >> %MFG_TMP_DIR%\HideCmd.log

if %SCENARIO% == INST (goto set_params4instonly) else (goto adjust_nw_inifiles)

:set_params4instonly
echo User has input SID=%SID%, NR1=%NR1%, NR2=%NR2% for validation.
java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper DETERMINE_SYSINFO,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%
set RC=%ERRORLEVEL%
set /a RC2=RC+1
if %RC% == 256 (
	echo Your input of sys info SID=%SID%, NR1=%NR1%, NR2=%NR2% is invalid, please run this script again and give correct information.
	pause
	exit
)
if %RC% GTR 9 (set RINST_NO=%RC%) else (set RINST_NO=0%RC%)
if %RC2% GTR 9 (set RINST_NO2=%RC2%) else (set RINST_NO2=0%RC2%)
if %RC% NEQ 0 if %RINST_NO% == %NR1%  set SID=Z%RINST_NO%
if %RC% NEQ 0 if %RINST_NO% NEQ %NR1% set NR1=%RINST_NO%
if %RC% NEQ 0 if %RINST_NO2% NEQ %NR2% set NR2=%RINST_NO2%
if %RC% NEQ 0 ( echo We will finally use SID=%SID%, NR1=%NR1%, NR2=%NR2% for installation. )

set TRANS_DIR=%DRIVER%:\usr\sap\trans\EPS\in
set KERNEL=%DRIVER%:\usr\sap\%SID%\SYS\exe\uc\NTAMD64
set SAPJVM=%DRIVER%:\usr\sap\%SID%\SYS\exe\jvm\NTAMD64\sapjvm_6.1.037
set JSPM=%DRIVER%:\usr\sap\%SID%\J%NR1%\j2ee\JSPM
set AUTH=2@@Administrator@@%PASSWORD%@@J2EE
set INBOX=%DRIVER%:\\usr\\sap\\trans\\EPS\\in
set ORACLE_HOME=%DRIVER%:\oracle\%SID%\11203
set PATH=%PATH%;%ORACLE_HOME%\OPatch;%KERNEL%;

:adjust_nw_inifiles
if %SCENARIO% NEQ INST if %SCENARIO% NEQ UNINST goto set_parameters_end
copy %MFG_DIR%\NWInst\custom_%SCENARIO%\inifile_%DATABASE_TYPE%.xml %MFG_DIR%\NWInst\custom_%SCENARIO%\inifile.xml /y
if %SCENARIO% == INST copy %MFG_DIR%\NWInst\dir_inst\start_dir_%DATABASE_TYPE%.cd %MFG_DIR%\NWInst\dir_inst\start_dir.cd /y
rem replace parameter values in inifile.xml for (un)installation scenario
java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper %SCENARIO%,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%MFG_DIR%,%DATABASE_TYPE%

:set_parameters_end