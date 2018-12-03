@echo off
title Install JDK......
if not defined INST_CASE set /p INST_CASE=Choose MII or ME: || set INST_CASE=ME
cd /d C:\Users\%username%\Downloads\
rem install jdk, simply check existence by check javac.exe in default directory
if not exist "C:\Program Files (x86)\Java\jdk1.6.0_45\bin\javac.exe" (
	if exist jdk-6u45-windows-i586.exe (
		start /wait jdk-6u45-windows-i586.exe /s
		echo JDK 1.6.0.45 32bit installed at "C:\Program Files (x86)\Java\jdk1.6.0_45".
	)
) else (
	echo JDK 1.6.0.45 32bit installed at "C:\Program Files (x86)\Java\jdk1.6.0_45" already before.
)

if not exist "C:\Program Files\Java\jdk1.6.0_45\bin\javac.exe" (
	if exist jdk-6u45-windows-x64.exe (
		start /wait jdk-6u45-windows-x64.exe /s
		echo JDK 1.6.0.45 64bit installed at "C:\Program Files\Java\jdk1.6.0_45".
	) 
) else (
	echo JDK 1.6.0.45 64bit installed at "C:\Program Files\Java\jdk1.6.0_45" already before.
)

if %INST_CASE% NEQ ME goto ending_inst_jdk

rem install jdk7 for ME also
if not exist "C:\Program Files (x86)\Java\jdk1.7.0_55\bin\javac.exe" (
	if exist jdk-7u55-windows-i586.exe (
		start /wait jdk-7u55-windows-i586.exe /s
		echo JDK 1.7.0.55 32bit installed at "C:\Program Files (x86)\Java\jdk1.7.0_55".
	) 
) else (
	echo JDK 1.7.0.55 32bit installed at "C:\Program Files (x86)\Java\jdk1.7.0_55" already before.
)

if not exist "C:\Program Files\Java\jdk1.7.0_60\bin\javac.exe" (
	if exist jdk-7u60-windows-x64.exe (
		start /wait jdk-7u60-windows-x64.exe /s
		echo JDK 1.7.0.60 64bit installed at "C:\Program Files\Java\jdk1.7.0_60".
	) 
) else (
	echo JDK 1.7.0.60 64bit installed at "C:\Program Files\Java\jdk1.7.0_60" already before.
)

:ending_inst_jdk