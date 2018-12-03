@echo off

set SID=AMU
set NR1=02
set NR2=03
set DRIVER=D
set KERNEL=%DRIVER%:\usr\sap\%SID%\SYS\exe\uc\NTAMD64
set PATH=%PATH%;C:\Program Files\WinRAR;C:\WINDOWS;%KERNEL%;C:\Program Files (x86)\Java\jdk1.6.0_45\bin;

cd /d C:\Windows\System32

stopsap name=%SID% nr=%NR1% SAPDIAHOST=%computername%
stopsap name=%SID% nr=%NR2% SAPDIAHOST=%computername%