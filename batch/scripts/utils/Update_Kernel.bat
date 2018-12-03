@echo off
if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

echo We start to apply NetWeaver Java AS 7.31 Kernel Patches at : %date% %time%
rem stop netweaver and apply kernel patches
call %MFG_DIR%\NWInst\utils\restart_nw.bat Stop

title Applying Kernel Patches of NetWeaver 731......
rem backup kernel files first
xcopy %KERNEL%\* %KERNEL%_BAK\ /y /e > %KERNEL%\KernelBak.log 2>&1
xcopy %SAPJVM%\* %SAPJVM%_BAK\ /y /e > %KERNEL%\SAPJVMBak.log 2>&1

cd /d %MFG_DIR%\KernelPatch
SAPCAR -xvf SAPEXE_600-20006748.SAR -R %KERNEL%
if %DATABASE_TYPE% == ADA (SAPCAR -xvf SAPEXEDB_600-20006745.SAR -R %KERNEL%)
if %DATABASE_TYPE% == ORA (SAPCAR -xvf SAPEXEDB_600-20006746.SAR -R %KERNEL%)
if %DATABASE_TYPE% == MSS (SAPCAR -xvf SAPEXEDB_600-20006747.SAR -R %KERNEL%) 
SAPCAR -xvf igshelper_4-10010245.sar -R %KERNEL%
SAPCAR -xvf igsexe_7-20007794.sar -R %KERNEL%
SAPCAR -xvf SAPJVM6_67-10006998.SAR -R %SAPJVM%

rem change profile "service/protectedwebmethods = SDEFAULT" to DEFAULT, or JSPM will fail to start then
java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper PROFILE,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%DRIVER%:\usr\sap\%SID%\SYS\profile
rem copy changed icm filter rules text file to prevent possible access issues
xcopy %MFG_DIR%\NWInst\utils\icm_filter_rules.txt %DRIVER%:\usr\sap\%SID%\SYS\global\security\data\ /y

call %MFG_DIR%\NWInst\utils\restart_sap_service.bat
call %MFG_DIR%\NWInst\utils\restart_nw.bat Start
echo NetWeaver Java AS 7.31 %SID%,%NR1%,%PASSWORD%,%DATABASE_TYPE% Kernel Updated at %date% %time% > %DRIVER%:\usr\sap\%SID%\KERNEL_LOG.txt
echo NetWeaver Java AS 7.31 Kernel Patches applied successfully at : %date% %time%