@echo off

set SID=MFG
set NR1=00
set NR2=01
set DRIVER=C
set KERNEL=%DRIVER%:\usr\sap\%SID%\SYS\exe\uc\NTAMD64
set PATH=%PATH%;C:\Program Files\WinRAR;C:\WINDOWS;%KERNEL%;C:\Program Files (x86)\Java\jdk1.6.0_45\bin;

cd /d C:\Windows\System32

stopsap name=%SID% nr=%NR1% SAPDIAHOST=%computername%
stopsap name=%SID% nr=%NR2% SAPDIAHOST=%computername%

cd /d C:\Users\%username%\Desktop