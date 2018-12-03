@echo off
title Upgrading Host Agent......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

echo We start to upgrade NetWeaver Java AS 7.31 Host Agent at : %date% %time%
cd /d %MFG_DIR%\KernelPatch
if not exist %MFG_DIR%\HostAgent\saphostexec.exe (SAPCAR -xvf SAPHOSTAGENT186_186-20005735.SAR -R %MFG_DIR%\HostAgent)
rem update hostagent(system should be running while apply upgrade)
cd /d %MFG_DIR%\HostAgent
saphostexec.exe -upgrade
"C:\Program Files\SAP\hostctrl\exe\saphostexec.exe" -version
call %MFG_DIR%\NWInst\utils\restart_sap_service.bat
call %MFG_DIR%\NWInst\utils\restart_nw.bat Restart
echo NetWeaver Java AS 7.31 Host Agent upgraded at %date% %time% > %DRIVER%:\usr\sap\HOSTAGENT_LOG.txt
echo NetWeaver Java AS 7.31 Host Agent upgraded successfully at %date% %time%