@echo off
title Restarting SAP services for NetWeaver Java AS 7.31 %SID% J%NR1%......
if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST

rem stop and start services of netweaver java application server
net stop SAP%SID%_%NR1%
net stop SAP%SID%_%NR2%
net stop SAPHostControl

net start SAP%SID%_%NR1%
net start SAP%SID%_%NR2%
net start SAPHostControl