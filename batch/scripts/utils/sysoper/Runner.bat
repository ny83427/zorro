@echo off
if not defined SID set /p SID=Enter SID: || set SID=MFG
if not defined TYPE set /p TYPE=Enter Type(INST or UNINST): || set TYPE=INST
if not defined INST_CASE set /p INST_CASE=Enter Inst Case(MII or ME): || set INST_CASE=ME

call C:\Users\%username%\Desktop\ScriptTest\MFG_%TYPE%.bat > C:\Users\%username%\Desktop\ScriptTest\%INST_CASE%_%SID%_%TYPE%.txt 2>&1

pause

call C:\Users\%username%\Desktop\Stop_%SID%.bat