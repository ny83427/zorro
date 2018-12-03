@echo off
title Installing Oracle 11g......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST
if not defined ORACLE_HOME set /p ORACLE_HOME=Enter Oracle Home Directory: || set ORACLE_HOME=%DRIVER%:\oracle\%SID%\11203
sc query | findstr OracleMTSRecoveryService
if %ERRORLEVEL% == 0 if exist %ORACLE_HOME%\BIN\oracle.exe (
	echo Oracle Instance %SID% has been installed already before.
	goto oracle_inst_end
)

if not exist %MFG_DIR%\Oracle11g\51042334\database\setup.exe (
	echo Oracle 11g installation files not found, please check and correct it first!
	pause
	exit
)

echo We start to install oracle 11g at : %date% %time%.
cd /d %MFG_DIR%\Oracle11g\51042334\database
setup.exe -silent -waitforcompletion -showProgress -responseFile %MFG_DIR%\NWInst\custom_inst\SILENT_ORACLE.rsp

rem apply oracle 11.2.0.3 patches via OPatch: rename orignal OPatch first, then copy latest OPatch, then apply bundle patches
cd /d %ORACLE_HOME%
if not exist OPatch_%SID% rename OPatch OPatch_%SID%
xcopy %MFG_DIR%\Oracle11g\Patches\OPatch\* %ORACLE_HOME%\OPatch\ /d /y /e

cd /d %MFG_DIR%\Oracle11g\Patches\18940194
call opatch.bat apply

echo Oracle Instance %SID% installed and patches applied successfully at %date% %time%.

:oracle_inst_end