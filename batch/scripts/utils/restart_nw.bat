@echo off
rem change to this directory so that logs will be created only here
cd /d C:\Windows\System32

set CASE=%1%
title %CASE% NetWeaver Java AS 7.31 %SID% J%NR1%......
if %CASE% == Start goto startsap

:stopsap
stopsap name=%SID% nr=%NR1% SAPDIAHOST=%computername%
stopsap name=%SID% nr=%NR2% SAPDIAHOST=%computername%

if %CASE% == Stop goto end

:startsap
startsap name=%SID% nr=%NR2% SAPDIAHOST=%computername% pf=%DRIVER%:\usr\sap\%SID%\SYS\profile\%SID%_J%NR1%_%computername%
startsap name=%SID% nr=%NR1% SAPDIAHOST=%computername% pf=%DRIVER%:\usr\sap\%SID%\SYS\profile\%SID%_J%NR1%_%computername%

:end