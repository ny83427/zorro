@echo off
set MFG_SHARE=\\cnpvgl000.pvgl.sap.corp\Restricted\I2D\MFG\50_Software

rem if you NEVER install NW on you computer before, you will need to give some inputs and then LOG OFF ONECE for all
start %MFG_SHARE%\Zorro\Documents\Readme.docx
xcopy %MFG_SHARE%\SAP_SOFTWARE_PROVISIONING_MGR_1.0\SWPM10SP05_8-20009707.SAR C:\TMP\SWPM\ /d /y
cd /d C:\TMP\SWPM
if not exist C:\TMP\SWPM\sapinst.exe (SAPCAR -xvf SWPM10SP05_8-20009707.SAR -R C:\TMP\SWPM)
start sapinst.exe
