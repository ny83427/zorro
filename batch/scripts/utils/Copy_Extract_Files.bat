@echo off
title Copying and extracting installation files from share folder......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

rem copy nw installation files, swpm, maxdb studio, NWDS
xcopy %MFG_SHARE%\NW7.3_7.31_Java\51044253_4.ZIP %MFG_DIR%\rawfiles\ /d /y
xcopy %MFG_SHARE%\NW7.3_7.31_Java\51044252_8.ZIP %MFG_DIR%\rawfiles\ /d /y  
xcopy %MFG_SHARE%\NW7.3_7.31_Java\51043228_JAVA_part*.* %MFG_DIR%\rawfiles\ /d /y
xcopy %MFG_SHARE%\NW7.3_7.31_Java\jce_policy-6.zip %MFG_DIR%\rawfiles\ /d /y
xcopy %MFG_SHARE%\SAP_SOFTWARE_PROVISIONING_MGR_1.0\SWPM10SP05_8-20009707.SAR %MFG_DIR%\rawfiles\ /d /y
xcopy %MFG_SHARE%\MaxDB_Studio\maxdb-studio-desktop-win-64bit-x86_64-7_9_08_09.zip %MFG_DIR%\rawfiles\ /d /y
xcopy %MFG_SHARE%\NWDS\nwds-extsoa-internal-7.3-EHP1-SP14-PAT0000-win32.zip %MFG_DIR%\rawfiles\ /d /y

rem copy kernel patches
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP KERNEL 7.20 EXT 64-BIT UC\#Database independent\SAPEXE_600-20006748.SAR" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP KERNEL 7.20 EXT 64-BIT UC\MaxDB\SAPEXEDB_600-20006745.SAR" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP KERNEL 7.20 EXT 64-BIT UC\Oracle\SAPEXEDB_600-20006746.SAR" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP KERNEL 7.20 EXT 64-BIT UC\SQL Server\SAPEXEDB_600-20006747.SAR" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP JVM 6.1\Windows on x64 64bit\SAPJVM6_67-10006998.SAR" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP IGS HELPER\igshelper_4-10010245.sar" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP IGS 7.20_EXT\Windows on x64 64bit\igsexe_7-20007794.sar" %MFG_DIR%\KernelPatch\ /d /y
xcopy "%MFG_SHARE%\NW7.31_Patch\Patch-06\SAP HOST AGENT 7.20\windows onx64 64bit\SAPHOSTAGENT186_186-20005735.SAR" %MFG_DIR%\KernelPatch\ /d /y

rem copy nw patch06, mfg scas(xmii, mii_admin 15sp03, me, mectc, meint, meintctc and etc...)
xcopy %MFG_SHARE%\NW7.31_Patch\Patch-06\*.* %MFG_DIR%\NWPatch06\ /d /y
rem copy adobe service SP06 sca, XMII 15 SP03 for MII team only
if %INST_CASE% == MII (
	echo We will copy Adobe Service SP06 and XMII 15 SP03 since you choose installation scenario MII
	xcopy "%ROOT_SHARE%\I2D\MFG\08_Projects\03_MII_CORE\11_Software\*.SCA" %MFG_DIR%\NWPatch06\ /d /y
	xcopy "%ROOT_SHARE%\I2D\MFG\08_Projects\03_MII_CORE\11_Software\MII 15.0 SP03\*03_0.sca" %MFG_DIR%\MFG_SCAS\ /d /y
)
rem this sca can be used to assign XMII admin/super admin role to NWA administrator
xcopy "%MFG_SHARE%\Zorro\ASSIGN_XMII_ROLE*.sca" %MFG_DIR%\MFG_SCAS\ /d /y
xcopy %MFG_SHARE%\ME_MII_MEINT_15.0\*.SCA %MFG_DIR%\MFG_SCAS\ /d /y

rem extract nw installation files
winrar x -o-- %MFG_DIR%\rawfiles\51044253_4.ZIP *.* %MFG_DIR%\NW731JAVA\51044253_4\
winrar x -o-- %MFG_DIR%\rawfiles\51044252_8.ZIP *.* %MFG_DIR%\NW731JAVA\51044252_8\
cd /d %MFG_DIR%\NW731JAVA
rar x -o-- %MFG_DIR%\rawfiles\51043228_JAVA_part1.exe

rem extract software provision manager, we will use this to install nw4java
cd /d %MFG_DIR%\rawfiles
if not exist %MFG_DIR%\SWPM\sapinst.exe (SAPCAR -xvf SWPM10SP05_8-20009707.SAR -R %MFG_DIR%\SWPM)

rem install NWDS and copy certficate file to it for further usage
if not exist %DEV_DIR%\NWDS\eclipse\SapNetweaverDeveloperStudio.exe (	
	winrar x -o-- %MFG_DIR%\rawfiles\nwds-extsoa-internal-7.3-EHP1-SP14-PAT0000-win32.zip *.* %DEV_DIR%\NWDS\
	xcopy %MFG_SHARE%\trusted.p7b %DEV_DIR%\NWDS\ /d /y	
	rem Add JAVA VM argument in NWDS inifile so that it can launch successfully without manual modification
	java -cp %CLASSPATH% com.ny83427.zorro.MFGInstHelper NWDS,%SID%,%NR1%,%NR2%,%PASSWORD%,%DRIVER%,%DEV_DIR%,%DATABASE_TYPE%
) else (
	echo Netweaver Development Studio installed at "%DEV_DIR%\NWDS\eclipse" already before.
)

rem copy and extract sqlserver installation files if needed
set NEED_MSS=0
if %INST_CASE% == ME if %DATABASE_TYPE% == ADA set NEED_MSS=1
if %DATABASE_TYPE% == MSS set NEED_MSS=1

if %NEED_MSS% == 1 (
	xcopy %MFG_SHARE%\SAP_MSSQL_SRV_2008\* %MFG_DIR%\rawfiles\ /d /y	
	if not exist %MFG_DIR%\Sqlserver2008 mkdir %MFG_DIR%\Sqlserver2008
	cd /d %MFG_DIR%\Sqlserver2008
	rar x -o-- %MFG_DIR%\rawfiles\51044827_part01.exe
) else (
	echo We won't copy SqlServer 2008R2 installation files since it's not necessary.
)

rem copy and extract oracle installation files if needed
if %DATABASE_TYPE% == ORA (
	xcopy %MFG_SHARE%\Oracle11.2.0.3_WIN_X64\* %MFG_DIR%\rawfiles\ /d /y /e	
	if not exist %MFG_DIR%\Oracle11g mkdir %MFG_DIR%\Oracle11g
	cd /d %MFG_DIR%\Oracle11g
	rar x -o-- %MFG_DIR%\rawfiles\51042334_part1.exe
	winrar x -o-- %MFG_DIR%\rawfiles\51047747.ZIP *.* %MFG_DIR%\Oracle11g\51047747\
	winrar x -o-- %MFG_DIR%\rawfiles\Oracle11.2.0.3Patch\*.ZIP *.* %MFG_DIR%\Oracle11g\Patches\
) else (
	echo We won't copy Oracle 11g installation files since it's not necessary.
)