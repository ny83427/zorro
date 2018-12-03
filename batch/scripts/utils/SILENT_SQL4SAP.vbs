' v3.5.12   August 2011: SQL 2008 R2 SP1 CU1
'=============================================================================
' customized installation of SQL Server 2005 and 2008 for SAP
' design and implementation: C5000758, C5137087
' see SAP notes 896566 and 1144459 for known issues
'=============================================================================

' required folder structure:
'   .\SQL4SAP.VBS
'   .\<label_file>                       
'           <label_file> := v_<major_vers>.<minor_vers>.<hotfix_build>_<edition>_<sp_build>_<rtm_build>_<platform>
'           <edition> := "ENT" for Enterprise Edition | "DEV" for Developer Edition | "STD" for Standard Edition
'           <platform> := "_x86" for 32-bit | "_x64" for 64-bit | "IA64" for Itanium 64-bit                                
'           e.g.: "v_09.00.3042_DEV_3042_1399__x64"


' folder structure SQL 2005:
'   .\x86\DeveloperEdition\Servers\
'   .\x86\DeveloperEdition\Tools\
'   .\x86\EnterpriseEdition\Servers\
'   .\x86\EnterpriseEdition\Tools\
'   .\x86\ServicePack\SP1\
'   .\x64\DeveloperEdition\Servers\
'   .\x64\DeveloperEdition\Tools\
'   .\x64\EnterpriseEdition\Servers\
'   .\x64\EnterpriseEdition\Tools\
'   .\x64\ServicePack\SP1\
'   .\IA64\DeveloperEdition\Servers\
'   .\IA64\DeveloperEdition\Tools\
'   .\IA64\EnterpriseEdition\Servers\
'   .\IA64\EnterpriseEdition\Tools\
'   .\IA64\ServicePack\SP1\
'   .\x86\SqlCmd\<starter_script>


' folder structure SQL 2008:
'   .\x86-x64-IA64\EnterpriseEdition\
'  (.\x86-x64-IA64\DeveloperEdition\)
'   .\x86-x64-IA64\SqlNativeClient\
'   .\x86-x64-IA64\CumulativeUpdates\CU1-10.00.1763\x86\
'   .\x86-x64-IA64\CumulativeUpdates\CU1-10.00.1763\x64\
'   .\x86-x64-IA64\CumulativeUpdates\CU1-10.00.1763\ia64\
'  (.\x86-x64-IA64\SAP\<starter_script>)

' folder structure SQL 2008R2:
'   .\x86-x64-IA64\EnterpriseEdition\
'   .\x86-x64-IA64\SqlNativeClient\
'   .\x86-x64-IA64\ServicePacks\SP1-10.50.2500\ia64
'   .\x86-x64-IA64\ServicePacks\SP1-10.50.2500\x64
'   .\x86-x64-IA64\ServicePacks\SP1-10.50.2500\x86


option Explicit
dim WshShell, objArgs, Param, ParamIndex, fso, rc
dim i, j, k, msg, sql, cmd, temp, found

dim OnErrorResume, ErrorOccured
OnErrorResume = False
ErrorOccured  = False
if OnErrorResume then on error resume next

set WshShell  = CreateObject("WScript.Shell")
set fso       = CreateObject("Scripting.FileSystemObject")
Set objArgs   = WScript.Arguments

'----- ADD
'----- add new label here
'----- product features
const Label2005 = "v_09.00"
const Label2008 = "v_10.00"
const Label2008R2 = "v_10.50"
const ProductLabel2005 = "2005"
const ProductLabel2008 = "2008"
const ProductLabel2008R2 = "2008R2"

dim   LabelProduct, Product, SapNote
Product = ""
const SapNote2005 = "896566"
const SapNote2008 = "1144459"
const SapNote2008R2 = "1144459"
SapNote = ""

'----- constants
const NetStop      = 0
const NetStart     = 1
const NetQuery     = 2
const NetAutoStart = 3
const HKCR = &H80000000 
const HKCU = &H80000001 
const HKLM = &H80000002 
const HKUS = &H80000003 
const HKCC = &H80000005
const KDEL = &H00010000 
dim   InstallType, InstallLogFile
const InstallDotNet = 0
const InstallRTM    = 1
const InstallSP     = 2
const InstallHF     = 3



'========================================================
'=  restart as CSCRIPT (if started with WSCRIPT)
'========================================================

call GetParam
if  InStr(1, WScript.FullName, "wscript.exe", 1) <> 0 then
	rc = WshShell.Run("cscript //NoLogo " & chr(34) & WScript.ScriptFullName & chr(34) & Param, 1)
	WScript.Quit(rc)
end if



'========================================================
'=  check if Windows version >= 6
'========================================================

dim OSFamily6
OSFamily6 = True

dim objUAC
dim versionDigitOne
dim versionDigitTwo

on error resume next
	Err.Clear
	For Each objUAC in GetObject("winmgmts:").InstancesOf ("Win32_OperatingSystem")
		if objUAC.OSType = 18 then                     '----- OSFamily = "WINNT"
			i = 6

			versionDigitOne = CInt(Left(objUAC.Version, 1))     '----- OsVersion 6.1.0.0 -> 6
                                                                '----- OsVersion 16.1.0.0 -> 1
            versionDigitTwo = Cint(mid(objUAC.Version, 2, 1))   '----- OsVersion 6.1.0.0 -> .
                                                                '----- OsVersion 16.1.0.0 -> 6
            if (versionDigitTwo <> Empty) then
                i = (versionDigitOne * 10) + versionDigitTwo
            elseif (versionDigitOne <> Empty) then
                i = versionDigitOne
                '--- Clear the error that happended when the second digit was parsed
                Err.Clear
            end if

			if i < 6 then OSFamily6 = False
			exit for
		end if
	next
	if Err.Number <> 0 then 
		'----- WMI not installed
		msg =       "WMI is not running properly:" & VbCrLf & VbCrLf
		msg = msg & "Make sure that the following service is running:" & VbCrLf
		msg = msg & chr(34) & "Windows Management Instrumentation" & chr(34) & VbCrLf
		rc = MsgBox(msg, vbOKOnly + vbCritical, "WMI not running")
		WScript.Quit(1)
	end if
if Not OnErrorResume then on error goto 0



'========================================================
'=  figure out product version (2005/2008) from label
'========================================================
'----- ADD
'----- Add detection of new version here
'----- overwrite script settings (version, edition) with label file
'      if no label file found at all, then allow all editions (to be compatible with SQL 2005)
LabelProduct = ""

'----- <label_file> := v_<major_vers>.<minor_vers>.<hotfix_build>_<edition>_<sp_build>_<rtm_build>_<platform> with exact 31 character length
'      e.g. "v_09.00.3042_DEV_3042_1399__x64"
dim fsoMyFolder, fsoMyFiles, fsoFile
on error resume next
		set fsoMyFolder = fso.GetFolder(fso.GetParentFolderName(WScript.ScriptFullName))
		set fsoMyFiles = fsoMyFolder.Files
		for each fsoFile in fsoMyFiles
			temp = LCase(fsoFile.Name)
			if len(temp) = 31 then
				if left(temp,2) = "v_" then
					temp = left(temp,7)
					if temp = Label2005 then
						LabelProduct = Label2005
						Product = ProductLabel2005
						SapNote = SapNote2005
						exit for
					elseif temp = Label2008 then
						LabelProduct = Label2008
						Product = ProductLabel2008
						SapNote = SapNote2008
						exit for
					elseif temp = Label2008R2 then
						LabelProduct = Label2008R2
						Product = ProductLabel2008R2
						SapNote = SapNote2008R2
						exit for

					end if
				end if				
			end if
		next
if Not OnErrorResume then on error goto 0
' Default to SQL 2008 R2
if LabelProduct = "" then 
	Product = ProductLabel2008R2
	SapNote = SapNote2008R2
end if



'========================================================
'=  script already restarted as elevated administrator (with parameter "Uac")
'========================================================

if CheckParamUac() Then
	'----- remove parameter "Uac" and continue
	call PullParamUac
else

'========================================================
'=  check if elevation necessary
'========================================================

	dim UacElevationNeeded
	UacElevationNeeded = OSFamily6
	
	'----- check if already elevated (delete permission on registry)
	Dim objRegUAC, isElevatedAdmin
	isElevatedAdmin = False 
	on error resume next
		if UacElevationNeeded then
			Set objRegUAC = GetObject("winmgmts:\\.\root\default:StdRegProv") 
			objRegUAC.CheckAccess HKLM, "SYSTEM\CurrentControlSet\Services", KDEL, isElevatedAdmin			
			if isElevatedAdmin then UacElevationNeeded = False
		end if
	if Not OnErrorResume then on error goto 0

'========================================================
'=  restart as elevated administrator (with parameter "Uac")
'========================================================

	dim dirUAC, batUAC, uncUAC, fsoUAC, objShellUAC, objFolderUAC, objFolderItemUAC
	if UacElevationNeeded then
		'----- add parameter "Uac"
		call PushParamUac
		
		on error resume Next
			'----- create file sql4sap_startup.bat in user home directory
			dirUAC = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
			batUAC = "sql4sap_startup.bat"
			uncUAC = dirUAC & "\" & batUAC
			
			'----- sql4sap_startup.bat:
			'----- cscript.exe sql4sap.vbs "<parameter list>" 
			set fsoUAC = fso.OpenTextFile(uncUAC, 2, True, 0) 'FileName, 2=ForWriting , True=Create, 0=ASCII
			fsoUAC.WriteLine "cls & cmd /C " & chr(34) & "cscript.exe //NoLogo " & chr(34) & FileGetUNC(WScript.ScriptFullName) & chr(34) & Param & chr(34)
			fsoUAC.Close
			
			'----- "runas" "sql4sap_startup.bat" results in UAC elevation
			'----- batch file starts new, elevated instance of SQL4SAP.VBS
			Set objShellUAC = CreateObject("Shell.Application")
			Set objFolderUAC = objShellUAC.Namespace(dirUAC)
			Set objFolderItemUAC = objFolderUAC.ParseName(batUAC)
			objFolderItemUAC.InvokeVerb "runas"
		if Not OnErrorResume then on error goto 0
		
		'----- terminate non-elevated instance of SQL4SAP.VBS
		wscript.quit(0)
	end if
	
	
end if



'========================================================
'=  parameter functions
'========================================================

'----- get parameter
sub GetParam
	Param = ""
	for ParamIndex = 0 to objArgs.Count - 1
	   Param = Param & " " & chr(34) & objArgs(ParamIndex) & chr(34)
	next
end sub

'----- add "Uac" to the first parameter 
sub PushParamUac
	if len(Param) <= 3 then
		Param = " " & chr(34) & "Uac" & chr(34)
	else
		Param = left(Param,2) & "Uac" & right(Param, len(Param)-2)
	end if
end sub

'----- remove "Uac" from the first parameter 
sub PullParamUac
	if len(Param) <= 6 then
		Param = ""
	else 
		Param = left(Param,2) & right(Param, len(Param)-5)
	end if
end sub

'----- check if started with parameter "Uac"
function CheckParamUac()
	dim TempParam
	if len(Param) < 6 then 
		TempParam = "      "
	else
		TempParam = right(Param, len(Param)-2) & "      "
	end if
	if left(TempParam, 3) = "Uac" then
		CheckParamUac = True
	else
		CheckParamUac = False	
	end if
end function



'========================================================
'=  script variables
'========================================================

'----- SQL version variables
' installed and target SQL Server version: i=integer, s=string
dim iVersion, iVersionTarget
dim sVersion, sVersionTarget
' SQL Server versions: RTM (Ready To Manufacture), SP (Service Pack), HF (Hotfix)
dim iVersionRTM, iVersionSP, iVersionHF
dim sVersionRTM, sVersionSP, sVersionHF
' SQL Server versions per platform: 32BIT, IA64 (Itanium), AMD (x64)
dim iVersionRTM_32BIT, iVersionSP_32BIT, iVersionHF_32BIT
dim iVersionRTM_IA64,  iVersionSP_IA64,  iVersionHF_IA64
dim iVersionRTM_AMD,   iVersionSP_AMD,   iVersionHF_AMD
' global variables for CalcVersions
dim VersionStr, VersionMajor, VersionMinor, VersionBuild, VersionSub

' install directory + file name of installation program per platform
dim PathInst
dim PathSE,       PathEE,       PathDE,       PathCL,       PathSP,       PathHF       
dim PathSE_32BIT, PathEE_32BIT, PathDE_32BIT, PathCL_32BIT, PathSP_32BIT, PathHF_32BIT  
dim PathSE_IA64,  PathEE_IA64,  PathDE_IA64,  PathCL_IA64,  PathSP_IA64,  PathHF_IA64   
dim PathSE_AMD,   PathEE_AMD,   PathDE_AMD,   PathCL_AMD,   PathSP_AMD,   PathHF_AMD
dim DotNet20_IA64_Setup, DotNet351_Setup    

' default install path
dim NetworkPath
' current install path + directory
dim myDir, myDirUNC, myRoot, myDriveName, myShareName

'----- installed SQL Server and Windows attributes
dim myInstance, myService, myAgentService, myCollation, myPassword, myComputer, InstanceText
dim OSVersion, OSServicePack, OSFamily, OSEdition, OSSystemType, OSSystemBit, OSProductSuite
dim OSMsiVersion, OSMdacVersion, OSLanguage, OSLanguageID, OSLogicalProcessors, OSTime, OSBootTime
dim rootDrive, rootDir, tmpDir, userDir, prgDir, prgDirX86

'----- file names and file system objects (fso)
dim LogFile
dim ExecStr, oExec
dim fsoLog, fsoTmp, ShareList, Share

'----- registry keys
dim RegValueName(3), RegValueData(3), RegKeyName(3), RegSummary
RegSummary = ""

'-----  SQL Server Editions
dim SQLEditionInst, SQLEditionEE, SQLEditionCL, SQLEditionDE, SQLEditionSE, EditionByKey, SQLEditionDC
SQLEditionInst = ""
SQLEditionDC = Product & " Datacenter Edition"
SQLEditionEE = Product & " Enterprise Edition"
SQLEditionCL = Product & " Client Tools"
SQLEditionDE = Product & " Developer Edition"
SQLEditionSE = Product & " Standard Edition"

'----- ADD
'----- check if new version need to be handled different
'----- add case for new version
'----- SQL SERVER 2005 -----
if Product = ProductLabel2005 then
	EditionByKey = False
'----- SQL SERVER 2008 -----
else
	EditionByKey = False
end if
'----- SQL SERVER -----


'========================================================
'=  script options
'========================================================

dim Sql4SapOption
	Sql4SapOption     = ""
dim FullInstall, SqlAuthInstall, SilentInstall, SilentRtmSetup, SqlDataInstall
	FullInstall       = False
	SqlAuthInstall    = False
	SilentInstall     = False
	SilentRtmSetup    = True
    SqlDataInstall    = False
' choosen options
dim ClientToolsOnly, IgnoreFreeSpace, IgnoreDotNet
	ClientToolsOnly   = False
	IgnoreFreeSpace   = False
	IgnoreDotNet      = False
' Configuration
dim SnacInstalled, ToolsInstalled, ExpressInstalled, SqlDoesExist
	SnacInstalled     = False
	ToolsInstalled    = False
	ExpressInstalled  = False
	SqlDoesExist      = False
' Status
dim RebootRequired, RebootIgnored, AlterSaFailed
	RebootRequired    = False
	RebootIgnored     = False
	AlterSaFailed     = False



'========================================================
'=  product specific constants
'========================================================

'----- SQL collation
dim SqlCollation
const sCollationCI   = "SQL_Latin1_General_CP1_CI_AS"
const sCollationBIN2 = "SQL_Latin1_General_CP850_BIN2"
SqlCollation = sCollationBIN2


'----- ADD
'----- add space requirements for new version
'----- Free Space needed for installation, RTM includes space for SP
dim SpaceNeeded32bitRTM, SpaceNeeded64bitRTM, SpaceNeeded32bitSP, SpaceNeeded64bitSP
'----- SQL SERVER 2008 R2 -----
if Product = ProductLabel2008R2 then
	SpaceNeeded32bitRTM = 4000
	SpaceNeeded64bitRTM = 4000
	SpaceNeeded32bitSP  = 675
	SpaceNeeded64bitSP  = 675
'----- SQL SERVER 2008 -----
elseif Product = ProductLabel2008 then
	SpaceNeeded32bitRTM = 3500
	SpaceNeeded64bitRTM = 3500
	SpaceNeeded32bitSP  = 2000
	SpaceNeeded64bitSP  = 2000
'----- SQL SERVER 2005 -----	
elseif Product = ProductLabel2005 then
	SpaceNeeded32bitRTM = 2700
	SpaceNeeded64bitRTM = 3500
	SpaceNeeded32bitSP  = 1650
	SpaceNeeded64bitSP  = 1650
end if
'----- SQL SERVER -----

'----- license keys
'      KeyEE = KeyDefault    => ask for key       for SQLEditionEE installation
'      KeyEE = ""            => don't use any key for SQLEditionEE installation
'      KeyEE = "<OtherKey>"  => use <OtherKey>    for SQLEditionEE installation
dim KeyInstall, KeyEE, KeyDE, KeySE, KeyCL
KeyInstall = ""
const KeyDefault = "A111AB222BC333CD444DE555E"
'----- SQL SERVER 2008 -----
if Product = ProductLabel2008 then
	KeySE = ""
	KeyEE = ""
	KeyDE = ""
	KeyCL = ""
	
	if EditionByKey then
		KeyDE = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
		KeyEE = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
		KeyCL = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
	end if
'----- SQL SERVER 2005 -----	
elseif (Product = ProductLabel2005) then
	KeySE = ""
	KeyEE = ""
	KeyDE = ""
	KeyCL = ""
'----- SQL SERVER 2008 R2 -----	
elseif (Product = ProductLabel2008R2) then
    KeySE = ""
	KeyEE = ""
	KeyDE = ""
	KeyCL = ""    
end if
'----- SQL SERVER -----


'----- Windows account names
dim OSSystemAccount, OSLocalSrvAccount, OSNwSrvAccount, GetSidNameExe
OSSystemAccount   = ""
OSLocalSrvAccount = ""
OSNwSrvAccount    = ""

'----- ADD
'----- Add path for GetSidName.exe for new version here
'----- SQL SERVER 2005 -----
if Product = ProductLabel2005 then
	GetSidNameExe = myDir & "SqlCmd\GetSidName.exe"
'----- SQL SERVER 2008 -----
else
	GetSidNameExe = myDir & "GetSidName.exe"
end if
'----- SQL SERVER -----

dim AccountSID(2), AccountEnglish(2), AccountGerman(2), AccountFrench(2), AccountItalien(2), AccountSpanish(2)
AccountSID(0)     = "S-1-5-18"
AccountEnglish(0) = "NT AUTHORITY\SYSTEM"
AccountGerman(0)  = "NT-AUTORITÄT\SYSTEM"
AccountFrench(0)  = "AUTORITE NT\SYSTEM"
AccountItalien(0) = "NT AUTHORITY\SYSTEM"
AccountSpanish(0) = "NT AUTHORITY\SYSTEM"

AccountSID(1)     = "S-1-5-19"
AccountEnglish(1) = "NT AUTHORITY\LOCAL SERVICE"
AccountGerman(1)  = "NT-AUTORITÄT\LOKALER DIENST"
AccountFrench(1)  = "AUTORITE NT\SERVICE LOCAL"
AccountItalien(1) = "NT AUTHORITY\SERVIZIO LOCALE"
AccountSpanish(1) = "NT AUTHORITY\SERVICIO LOC"

AccountSID(2)     = "S-1-5-20"
AccountEnglish(2) = "NT AUTHORITY\NETWORK SERVICE"
AccountGerman(2)  = "NT-AUTORITÄT\NETZWERKDIENST"
AccountFrench(2)  = "AUTORITE NT\SERVICE RESEAU"
AccountItalien(2) = "NT AUTHORITY\SERVIZIO DI RETE"
AccountSpanish(2) = "NT AUTHORITY\SERVICIO DE RED"



'========================================================
'=  SQL Server version to install
'========================================================

dim iVersionMajor, iVersionMinor, sVersionMajor, sVersionMinor
iVersionRTM = 0
iVersionSP  = 0
iVersionHF  = 0
	
'----- ADD
'----- Add versionstrings for new version
'----- SQL SERVER 2008 R2 -----
if Product = ProductLabel2008R2 then
	iVersionMajor     = 10
	iVersionMinor     = 50
	sVersionMajor     = "10"
	sVersionMinor     = "50"
	
	iVersionRTM_32BIT = 1600
	iVersionRTM_IA64  = 1600
	iVersionRTM_AMD   = 1600		

	iVersionSP_32BIT  = 2500
	iVersionSP_IA64   = 2500
	iVersionSP_AMD    = 2500

	iVersionHF_32BIT  = 2769
	iVersionHF_IA64   = 2769
	iVersionHF_AMD    = 2769
	
'----- SQL SERVER 2008 -----
elseif Product = ProductLabel2008 then
	iVersionMajor     = 10
	iVersionMinor     = 0
	sVersionMajor     = "10"
	sVersionMinor     = "00"
	
	iVersionRTM_32BIT = 1600
	iVersionRTM_IA64  = 1600
	iVersionRTM_AMD   = 1600		

	iVersionSP_32BIT  = 2531
	iVersionSP_IA64   = 2531
	iVersionSP_AMD    = 2531

	iVersionHF_32BIT  = 2531
	iVersionHF_IA64   = 2531
	iVersionHF_AMD    = 2531
	
'----- SQL SERVER 2005 -----
elseif Product = ProductLabel2005 then
	iVersionMajor     = 9
	iVersionMinor     = 0
	sVersionMajor     = "9"
	sVersionMinor     = "00"
	
	iVersionRTM_32BIT = 1399
	iVersionRTM_IA64  = 1399
	iVersionRTM_AMD   = 1399		
	
	iVersionSP_32BIT  = 4035
	iVersionSP_IA64   = 4035
	iVersionSP_AMD    = 4035
			
	iVersionHF_32BIT  = 4035
	iVersionHF_IA64   = 4035
	iVersionHF_AMD    = 4035
end if
'----- SQL SERVER -----


'----- check for slipstream version
dim isSlipstreamedSP, isSlipstreamedCU
isSlipstreamedSP = True '-- default for this DVD in case SQL4SAP is not started from the DVD
isSlipstreamedCU = True '-- default for this DVD in case SQL4SAP is not started from the DVD

'----- override default version with labled version 
'      ("v_09.00.3042_DEV_3042_1399__x64" with exact 31 character length)
'        1234567890123456789012345678901
'      ignore <edition> when setting the default version
if LabelProduct <> "" then
	on error resume next
			set fsoMyFolder = fso.GetFolder(fso.GetParentFolderName(WScript.ScriptFullName))
			set fsoMyFiles = fsoMyFolder.Files
			for each fsoFile in fsoMyFiles
				temp = LCase(fsoFile.Name)
				
				if temp = "v_slipstreamed_sp" then
					isSlipstreamedSP = True
				elseif temp = "v_slipstreamed_cu" then
					isSlipstreamedCU = True
				end if
						
				if len(temp) = 31 then
					if left(temp,7) = LabelProduct then
						if right(temp,4)     = "_x86" then
							iVersionRTM_32BIT     = CInt(mid(temp,23,4))
							iVersionSP_32BIT      = CInt(mid(temp,18,4))
							iVersionHF_32BIT      = CInt(mid(temp, 9,4))
						elseif right(temp,4) = "_x64" then
							iVersionRTM_AMD       = CInt(mid(temp,23,4))
							iVersionSP_AMD        = CInt(mid(temp,18,4))
							iVersionHF_AMD        = CInt(mid(temp, 9,4))						
						elseif right(temp,4) = "ia64" then
							iVersionRTM_IA64      = CInt(mid(temp,23,4))
							iVersionSP_IA64       = CInt(mid(temp,18,4))
							iVersionHF_IA64       = CInt(mid(temp, 9,4))						
						end if
					end if
				end if
			next
	if Not OnErrorResume then on error goto 0
end if



'========================================================
'=  supported Windows versions
'========================================================
'----- ADD
' for future supported OS Families: set parameter OSFamily = "Windows4SQL"
dim OSFamilies(8), OsFamMinSP(8)
dim RequiredSP
RequiredSP = 0
'----- SQL SERVER 2008 -----
if Product = ProductLabel2008R2 then
	OSFamilies(0) = "Windows4SQL"
	OsFamMinSP(0) = 0
	OSFamilies(1) = "WindowsXP"
	OsFamMinSP(1) = 2
	OSFamilies(2) = "Windows2003"
	OsFamMinSP(2) = 2
	OSFamilies(3) = "Windows2008"
	OsFamMinSP(3) = 0
	OSFamilies(4) = "WindowsVista"
	OsFamMinSP(4) = 0
	OSFamilies(5) = "Windows2008R2"
	OsFamMinSP(5) = 0
	OSFamilies(6) = "Windows7"
	OsFamMinSP(6) = 0
	OSFamilies(7) = "Windows8"
	OsFamMinSP(7) = 0
	OSFamilies(8) = "Windows2012"
	OsFamMinSP(8) = 0
'----- SQL SERVER 2005 -----	
elseif Product = ProductLabel2008 then
	OSFamilies(0) = "Windows4SQL"
	OsFamMinSP(0) = 0
	OSFamilies(1) = "WindowsXP"
	OsFamMinSP(1) = 2
	OSFamilies(2) = "Windows2003"
	OsFamMinSP(2) = 2
	OSFamilies(3) = "Windows2008"
	OsFamMinSP(3) = 0
	OSFamilies(4) = "WindowsVista"
	OsFamMinSP(4) = 0
	OSFamilies(5) = "Windows2008R2"
	OsFamMinSP(5) = 0
	OSFamilies(6) = "Windows7"
	OsFamMinSP(6) = 0
	OSFamilies(7) = "Windows8"
	OsFamMinSP(7) = 0
	OSFamilies(8) = "Windows2012"
	OsFamMinSP(8) = 0
'----- SQL SERVER 2005 -----	
elseif Product = ProductLabel2005 then
	OSFamilies(0) = "Windows4SQL"
	OsFamMinSP(0) = 0
	OSFamilies(1) = "WindowsXP"
	OsFamMinSP(1) = 2
	OSFamilies(2) = "Windows2003"
	OsFamMinSP(2) = 1
	OSFamilies(3) = "Windows2008"
	OsFamMinSP(3) = 0
	OSFamilies(4) = "WindowsVista"
	OsFamMinSP(4) = 0
	OSFamilies(5) = "Windows2008R2"
	OsFamMinSP(5) = 0
	OSFamilies(6) = "Windows7"
	OsFamMinSP(6) = 0
	OSFamilies(7) = "Windows8"
	OsFamMinSP(7) = 0
	OSFamilies(8) = "Windows2012"
	OsFamMinSP(8) = 0
end if
'----- SQL SERVER -----



'========================================================
'=  START MAIN SCRIPT
'========================================================

'----- get script version
dim SQL4SAPVersion, SQL4SAPVerParam
SQL4SAPVersion = ""
SQL4SAPVerParam = "v0.0"
on error resume next
	FileOpen4Read(WScript.ScriptFullName)
	SQL4SAPVersion = FileReadLine()
	FileClose()
if Not OnErrorResume then on error goto 0

'----- get environment
userDir         = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
tmpDir          = WshShell.ExpandEnvironmentStrings("%temp%")
rootDir         = WshShell.ExpandEnvironmentStrings("%SystemRoot%")
prgDir          = WshShell.ExpandEnvironmentStrings("%ProgramFiles%")
prgDirX86       = WshShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%")
if prgDirX86 = "%ProgramFiles(x86)%" then prgDirX86 = ""
if right(userDir,1)   <> "\" then userDir   = userDir   & "\"
if right(tmpDir,1)    <> "\" then tmpDir    = tmpDir    & "\"
if right(rootDir,1)   <> "\" then rootDir   = rootDir   & "\"
if right(prgDir,1)    <> "\" then prgDir    = prgDir    & "\"
if right(prgDirX86,1) <> "\" then prgDirX86 = prgDirX86 & "\"
rootDrive       = WshShell.ExpandEnvironmentStrings("%SystemDrive%")
myComputer      = WshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")



'========================================================
'=  workaround for hanging SQL 2005 SP1 installation
'========================================================

' remove process environment variable "DIRCMD" 
on error resume next
	dim WshEnv
	Set WshEnv = WshShell.Environment("PROCESS")
	WshEnv.Remove "DIRCMD"
if Not OnErrorResume then on error goto 0



'========================================================
'=  Continuation Installation
'========================================================

dim IsContInstall, ContInstallRTM, ContInstallCU, ContInstance, ContTextRTM, ContTextCU
IsContInstall   = False
ContInstallRTM  = False
ContInstallCU   = False
ContInstance    = ""
ContTextRTM     = "Restart SQL4SAP.VBS to install instance: "
ContTextCU      = "Restart SQL4SAP.VBS to apply CU on instance: "

'----- ADD
'----- Add logic for continue
'----- SQL SERVER 2008 -----
if Product <> ProductLabel2005 then
	LogFile = rootDir & "SQL4SAP.log"
	if fso.FileExists(LogFile) then
		Set fsoTmp = fso.GetFile(LogFile)
		
		'----- SQL4SAP.log was closed within last 3 hours
		'if DateDiff("h", fsoTmp.DateLastModified, Now) < 3 then
			
			'----- read last line of SQL4SAP.log
			msg = ""
			on error resume next
				FileOpen4Read(LogFile)
				while not FileEOF()
					msg = FileReadLine()
				wend
				FileClose()
			if Not OnErrorResume then on error goto 0
			
			'----- check last line of SQL4SAP.log
			if len(msg) > len(ContTextRTM) then
				if left(msg, len(ContTextRTM)) = ContTextRTM then
					IsContInstall = True
					ContInstance = right(msg, len(msg) - len(ContTextRTM))
				end if
			end if
			if len(msg) > len(ContTextCU) then
				if left(msg, len(ContTextCU)) = ContTextCU then
					IsContInstall = True
					ContInstance = right(msg, len(msg) - len(ContTextCU))
				end if
			end if
		'end if
	end if
end if
'----- SQL SERVER -----



'========================================================
'=  open log file SQL4SAP.log 
'========================================================

LogFile = rootDir & "SQL4SAP.log"
call CopyOldLogFiles(LogFile)
on error resume next
	set fsoLog = fso.OpenTextFile(LogFile, 2, True, -1) 'FileName, 2=ForWriting , True=Create, -1=TristateTrue
	if Err.Number <> 0 then ErrorOccured = True	
if Not OnErrorResume then on error goto 0
if ErrorOccured then
	msg =       "=====================================================" & VbCrLf
	msg = msg & "Could not open log file: " & LogFile & VbCrLf
	msg = msg & "=====================================================" & VbCrLf & VbCrLf & VbCrLf & VbCrLf 
	msg = msg & "stopping in 5 seconds"
	Wscript.Echo msg
	Wscript.Sleep(5000)
	call QuitInstallation(32)
else
	msg =       "******************************************************" & VbCrLf
	msg = msg & "* Customized installation of SQL Server " & Product & " for SAP *" & VbCrLf
	msg = msg & "******************************************************" & VbCrLf & VbCrLf
	msg = msg & "Log File: " & LogFile & VbCrLf
	Wscript.Echo msg
end if 
fsoLog.WriteLine msg & VbCrLf & "Script started " & Now & " on " & myComputer



'========================================================
'=  get Windows version using WMI
'========================================================

'      OSFamily:     Windows2003 | Windows2000 | WindowsXP | WindowsVista | Windows2008 | Windows7 | Windows2008R2
'      OSEdition:    Server | Workstation | Cluster | Small Business Server
'      OSSystemType: X86 | Alpha | IA64 | X64
'      OSSystemBit:  32 | 64 
call CheckWindowsVersion



'========================================================
'=  check if .Net installation is required
'========================================================

'------ ADD
'------ Add logic for .NET prerequisite here 
dim DotNetNeeded
'----- SQL SERVER 2005 -----
if Product = ProductLabel2005 then
	DotNetNeeded = False

'----- SQL SERVER 2008 R2 -----
elseif ((Product = ProductLabel2008R2) and (OSFamily <> "Windows2012") and (OSFamily <> "Windows8"))then
    DotNetNeeded = False

'----- SQL SERVER 2008 or SQL2008R2 on Win2012/Win8 -----
else
'----- ADD
'----- Determine .NET version
	'if OSFamily = "WindowsXP" or OSFamily = "Windows2003" or OSFamily = "Windows2008" or OSFamily = "WindowsVista" then

        '----- This registry key is checked by the .NET 3.5 SP1 boostrap installer so we can use it too
    dim dotnetsp
    dotnetsp = RegRead("HKLM\Software\Microsoft\NET Framework Setup\NDP\v3.5\SP")
    if (dotnetsp = "1") then
        DotNetNeeded = False
    else
		DotNetNeeded = True
    end if

	'else
		'DotNetNeeded = False
	'endif
end if
'----- SQL SERVER -----



'========================================================
'=  check hostname consistency 
'========================================================

dim RegActiveComputername, RegComputername, RegHostname, ConsistentHostname
RegActiveComputername = RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername\Computername")
RegComputername       = RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Computername\Computername\Computername")
RegHostname           = RegRead("HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Hostname")

ConsistentHostname = 0
if RegHostname <> RegActiveComputername or RegHostname <> RegComputername then
	ConsistentHostname = 1
	if UCase(RegHostname) <> UCase(RegActiveComputername) or UCase(RegHostname) <> UCase(RegComputername) then
		ConsistentHostname = 2
	end if
end if



'========================================================
'=  calculate Windows Account names
'========================================================

if OSSystemAccount   = "" then OSSystemAccount   = CalcAccountName(0)
if OSLocalSrvAccount = "" then OSLocalSrvAccount = CalcAccountName(1)
if OSNwSrvAccount    = "" then OSNwSrvAccount    = CalcAccountName(2)
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Service Accounts:"
fsoLog.WriteLine "  OSSystemAccount   = " & OSSystemAccount
fsoLog.WriteLine "  OSLocalSrvAccount = " & OSLocalSrvAccount
fsoLog.WriteLine "  OSNwSrvAccount    = " & OSNwSrvAccount

function CalcAccountName(AccountIndex)
	dim myAccount
	myAccount = ""
	
	'----- 1. try: well known account names
	if myAccount = "" then
		Select case OSLanguageID
			case 1031  myAccount = AccountGerman(AccountIndex)
			case 1036  myAccount = AccountFrench(AccountIndex)
			case 1040  myAccount = AccountItalien(AccountIndex)
			case 1034  myAccount = AccountSpanish(AccountIndex)
			case 3082  myAccount = AccountSpanish(AccountIndex)
			case else  myAccount = ""
		end Select
	end if
	
	'----- 2. try: calculate account names
	if myAccount = "" then
		ExecStr = chr(34) & GetSidNameExe & chr(34) & " " & AccountSID(AccountIndex)
		on error resume next
			Set oExec = WshShell.Exec(ExecStr)
			myAccount = oExec.StdOut.ReadLine()
			oExec.Terminate
		if Not OnErrorResume then on error goto 0
	end if
	
	'----- 3. try: use English account names
	if myAccount = "" then 
		myAccount = AccountEnglish(AccountIndex)
	end if
	
	CalcAccountName = myAccount
end function



'========================================================
'=  get script parameters
'========================================================

'----- parse all parameters
ParamIndex = 0
call ParseParam(Sql4SapOption)
if len(Sql4SapOption) >= 3 then
	if left(Sql4SapOption,3) = "Uac" then
		Sql4SapOption = right(Sql4SapOption, len(Sql4SapOption)-3)
	end if
end if
call ParseParam(SQL4SAPVerParam)
if SQL4SAPVerParam = mid(SQL4SAPVersion,3,4) then
	call ParseParam(SqlCollation     )		' "SQL_Latin1_General_CP850_BIN2"
	call ParseParam(SQLEditionInst   )		' Product & " Enterprise Edition" | " Developer Edition" | " Standard Edition"
	call ParseParam(KeyInstall       )		'
	call ParseParam(DotNetNeeded     )		' True | False
	call ParseParam(EditionByKey     )		' True | False
	call ParseParam(OSFamily         )		' Windows2003 | Windows2000 | WindowsXP | WindowsVista | Windows2008 | Windows7 | Windows2008R2
	call ParseParam(OSEdition        )		' Server | Workstation | Cluster | Small Business Server
	call ParseParam(OSSystemType     )		' X86 | Alpha | IA64 | X64
	call ParseParam(OSSystemAccount  )		' "NT AUTHORITY\SYSTEM"	
	call ParseParam(iVersionRTM      )
	call ParseParam(iVersionSP       )
	call ParseParam(iVersionHF       )
end if

	'----- parse single parameter
	sub ParseParam(byref VarName)
		dim ParamValue
		if ParamIndex < objArgs.Count then
			ParamValue = objArgs(ParamIndex)
			if ParamValue <> "x" then
				if UCase(ParamValue) = "TRUE"  then ParamValue = True
				if UCase(ParamValue) = "FALSE" then ParamValue = False
				if IsNumeric(ParamValue) then ParamValue = CInt(ParamValue)
				VarName = ParamValue
			end if
		end if
		ParamIndex = ParamIndex + 1
	end sub

'----- set policies and editions
if Sql4SapOption     = "SAPINST" then
	SqlAuthInstall   = True
	SilentInstall	 = True
	DotNetNeeded     = False	
elseif Sql4SapOption = "SQLAUTH" then
	SqlAuthInstall   = True
elseif Sql4SapOption = "FULL" then
	SqlAuthInstall   = True
	FullInstall      = True
elseif Sql4SapOption = "DATA" then
    SqlDataInstall   = True
    SQLEditionEE = SQLEditionDC
end if



'========================================================
'=  overwrite version by parameter
'========================================================

if iVersionRTM <> 0 then
	iVersionRTM_32BIT = iVersionRTM
	iVersionRTM_IA64  = iVersionRTM
	iVersionRTM_AMD   = iVersionRTM
end if
if iVersionSP <> 0 then
	iVersionSP_32BIT = iVersionSP
	iVersionSP_IA64  = iVersionSP
	iVersionSP_AMD   = iVersionSP
end if
if iVersionHF <> 0 then
	iVersionHF_32BIT = iVersionHF
	iVersionHF_IA64  = iVersionHF
	iVersionHF_AMD   = iVersionHF
end if



'========================================================
'=  path to executables on DVD
'========================================================
NetworkPath = "D:\"

dim   FolderPlatform
const FolderX86  = "x86"
const FolderIA64 = "IA64"
const FolderAMD  = "x64"
const FolderALL  = "x86-x64-IA64"

dim FolderSE, FolderEE, FolderDE
FolderSE   = "StandardEdition"
FolderEE   = "EnterpriseEdition"
FolderDE   = "DeveloperEdition"
if EditionByKey then
	FolderSE = 	FolderEE
	FolderDE = 	FolderEE
end if

'----- ADD
'----- Add files for new version here
'----- SQL SERVER 2008 R2 -----
if Product = ProductLabel2008R2 then

	PathSE_32BIT = FolderSE & "\setup.exe"
	PathSE_IA64  = FolderSE & "\setup.exe"
	PathSE_AMD   = FolderSE & "\setup.exe"
		
	PathEE_32BIT = FolderEE & "\setup.exe"
	PathEE_IA64  = FolderEE & "\setup.exe"
	PathEE_AMD   = FolderEE & "\setup.exe"

	PathDE_32BIT = FolderDE & "\setup.exe"
	PathDE_IA64  = FolderDE & "\setup.exe"
	PathDE_AMD   = FolderDE & "\setup.exe"
		
    PathSP_32BIT = "" 
	PathSP_IA64  = ""
	PathSP_AMD   = ""
	'--- SP1
	if iVersionSP_32BIT     = 2500 then PathSP_32BIT = "ServicePacks\SP1-10.50.2500\x86\SQLServer2008R2SP1-KB2528583-x86-ENU.exe" 
	if iVersionSP_IA64      = 2500 then PathSP_IA64  = "ServicePacks\SP1-10.50.2500\ia64\SQLServer2008R2SP1-KB2528583-IA64-ENU.exe"
	if iVersionSP_AMD       = 2500 then PathSP_AMD   = "ServicePacks\SP1-10.50.2500\x64\SQLServer2008R2SP1-KB2528583-x64-ENU.exe"
    	
        
    PathHF_32BIT = ""
	PathHF_IA64  = ""
	PathHF_AMD   = ""
	'--- SP1 CU1
	if iVersionHF_32BIT     = 2769 then PathHF_32BIT = "CumulativeUpdates\CU1-10.50.2769\x86\SQLServer2008R2-KB2544793-x86.exe"
	if iVersionHF_IA64      = 2769 then PathHF_IA64  = "CumulativeUpdates\CU1-10.50.2769\ia64\SQLServer2008R2-KB2544793-IA64.exe"
	if iVersionHF_AMD       = 2769 then PathHF_AMD   = "CumulativeUpdates\CU1-10.50.2769\x64\SQLServer2008R2-KB2544793-x64.exe"
	'--- CU1
	if iVersionHF_32BIT     = 1702 then PathHF_32BIT = "CumulativeUpdates\CU1-10.50.1702\x86\SQLServer2008R2-KB981355-x86.exe"
	if iVersionHF_IA64      = 1702 then PathHF_IA64  = "CumulativeUpdates\CU1-10.50.1702\ia64\SQLServer2008R2-KB981355-ia64.exe"
	if iVersionHF_AMD       = 1702 then PathHF_AMD   = "CumulativeUpdates\CU1-10.50.1702\x64\SQLServer2008R2-KB981355-x64.exe"
	
'----- SQL SERVER 2008 -----	
elseif Product = ProductLabel2008 then

	PathSE_32BIT = FolderSE & "\setup.exe"
	PathSE_IA64  = FolderSE & "\setup.exe"
	PathSE_AMD   = FolderSE & "\setup.exe"
		
	PathEE_32BIT = FolderEE & "\setup.exe"
	PathEE_IA64  = FolderEE & "\setup.exe"
	PathEE_AMD   = FolderEE & "\setup.exe"

	PathDE_32BIT = FolderDE & "\setup.exe"
	PathDE_IA64  = FolderDE & "\setup.exe"
	PathDE_AMD   = FolderDE & "\setup.exe"
		
	PathSP_32BIT = "" 
	PathSP_IA64  = ""
	PathSP_AMD   = ""

	if iVersionSP_32BIT  = 2531 then PathSP_32BIT = "ServicePacks\SP1-10.00.2531\x86\SQLServer2008SP1-KB968369-x86-ENU.exe"
	if iVersionSP_IA64   = 2531 then PathSP_IA64  = "ServicePacks\SP1-10.00.2531\ia64\SQLServer2008SP1-KB968369-IA64-ENU.exe"  	
	if iVersionSP_AMD    = 2531 then PathSP_AMD   = "ServicePacks\SP1-10.00.2531\x64\SQLServer2008SP1-KB968369-x64-ENU.exe"
		 
	PathHF_32BIT = ""
	PathHF_IA64  = ""
	PathHF_AMD   = ""

	if iVersionHF_32BIT  = 1763 then PathHF_32BIT = "CumulativeUpdates\CU1-10.00.1763\x86\SQLServer2008-KB956717-x86.exe"
	if iVersionHF_IA64   = 1763 then PathHF_IA64  = "CumulativeUpdates\CU1-10.00.1763\ia64\SQLServer2008-KB956717-IA64.exe"  	
	if iVersionHF_AMD    = 1763 then PathHF_AMD   = "CumulativeUpdates\CU1-10.00.1763\x64\SQLServer2008-KB956717-x64.exe"

	if iVersionHF_32BIT  = 1779 then PathHF_32BIT = "CumulativeUpdates\CU2-10.00.1779\x86\SQLServer2008-KB958186-x86.exe"
	if iVersionHF_IA64   = 1779 then PathHF_IA64  = "CumulativeUpdates\CU2-10.00.1779\ia64\SQLServer2008-KB958186-IA64.exe"  	
	if iVersionHF_AMD    = 1779 then PathHF_AMD   = "CumulativeUpdates\CU2-10.00.1779\x64\SQLServer2008-KB958186-x64.exe"

	if iVersionHF_32BIT  = 1787 then PathHF_32BIT = "CumulativeUpdates\CU3-10.00.1787\x86\SQLServer2008-KB960484-x86.exe"
	if iVersionHF_IA64   = 1787 then PathHF_IA64  = "CumulativeUpdates\CU3-10.00.1787\ia64\SQLServer2008-KB960484-IA64.exe"  	
	if iVersionHF_AMD    = 1787 then PathHF_AMD   = "CumulativeUpdates\CU3-10.00.1787\x64\SQLServer2008-KB960484-x64.exe"
	
'----- SQL SERVER 2005 -----	
elseif Product = ProductLabel2005 then
	PathSE_32BIT = FolderSE & "\Servers\setup.exe"
	PathSE_IA64  = FolderSE & "\Servers\setup.exe"
	PathSE_AMD   = FolderSE & "\Servers\setup.exe"
		
	PathEE_32BIT = FolderEE & "\Servers\setup.exe"
	PathEE_IA64  = FolderEE & "\Servers\setup.exe"
	PathEE_AMD   = FolderEE & "\Servers\setup.exe"	
	
	PathDE_32BIT = FolderDE & "\Servers\setup.exe"
	PathDE_IA64  = FolderDE & "\Servers\setup.exe"
	PathDE_AMD   = FolderDE & "\Servers\setup.exe"		

	PathSP_32BIT = "" 
	PathSP_IA64  = ""
	PathSP_AMD   = ""
	
	if iVersionSP_32BIT  = 2047 then PathSP_32BIT = "ServicePack\SP1\SQLServer2005SP1-KB913090-x86-ENU.exe"
	if iVersionSP_IA64   = 2047 then PathSP_IA64  = "ServicePack\SP1\SQLServer2005SP1-KB913090-ia64-ENU"   	
	if iVersionSP_AMD    = 2047 then PathSP_AMD   = "ServicePack\SP1\SQLServer2005SP1-KB913090-x64-ENU.exe"		

	if iVersionSP_32BIT  = 3042 then PathSP_32BIT = "ServicePack\SP2\SQLServer2005SP2-KB921896-x86-ENU.exe" 
	if iVersionSP_IA64   = 3042 then PathSP_IA64  = "ServicePack\SP2\SQLServer2005SP2-KB921896-IA64-ENU.exe"
	if iVersionSP_AMD    = 3042 then PathSP_AMD   = "ServicePack\SP2\SQLServer2005SP2-KB921896-x64-ENU.exe"

	if iVersionSP_32BIT  = 4035 then PathSP_32BIT = "ServicePack\SP3\SQLServer2005SP3-KB955706-x86-ENU.exe" 
	if iVersionSP_IA64   = 4035 then PathSP_IA64  = "ServicePack\SP3\SQLServer2005SP3-KB955706-IA64-ENU.exe"
	if iVersionSP_AMD    = 4035 then PathSP_AMD   = "ServicePack\SP3\SQLServer2005SP3-KB955706-x64-ENU.exe"
	 
	PathHF_32BIT = ""
	PathHF_IA64  = ""
	PathHF_AMD   = ""
	
	if iVersionHF_32BIT  = 3228 then PathHF_32BIT = "ServicePack\SP2CU6\SQLServer2005-KB946608-x86-ENU.exe"
	if iVersionHF_IA64   = 3228 then PathHF_IA64  = "ServicePack\SP2CU6\SQLServer2005-KB946608-IA64-ENU.exe"
	if iVersionHF_AMD    = 3228 then PathHF_AMD   = "ServicePack\SP2CU6\SQLServer2005-KB946608-x64-ENU.exe"
		
	if iVersionHF_32BIT  = 3239 then PathHF_32BIT = "ServicePack\SP2CU7\SQLServer2005-KB949095-x86-ENU.exe"
	if iVersionHF_IA64   = 3239 then PathHF_IA64  = "ServicePack\SP2CU7\SQLServer2005-KB949095-IA64-ENU.exe"
	if iVersionHF_AMD    = 3239 then PathHF_AMD   = "ServicePack\SP2CU7\SQLServer2005-KB949095-x64-ENU.exe"

	if iVersionHF_32BIT  = 3257 then PathHF_32BIT = "ServicePack\SP2CU8\SQLServer2005-KB951217-x86-ENU.exe"
	if iVersionHF_IA64   = 3257 then PathHF_IA64  = "ServicePack\SP2CU8\SQLServer2005-KB951217-IA64-ENU.exe"
	if iVersionHF_AMD    = 3257 then PathHF_AMD   = "ServicePack\SP2CU8\SQLServer2005-KB951217-x64-ENU.exe"

	if iVersionHF_32BIT  = 3282 then PathHF_32BIT = "ServicePack\SP2CU9\SQLServer2005-KB953752-x86-ENU.exe"
	if iVersionHF_IA64   = 3282 then PathHF_IA64  = "ServicePack\SP2CU9\SQLServer2005-KB953752-IA64-ENU.exe"
	if iVersionHF_AMD    = 3282 then PathHF_AMD   = "ServicePack\SP2CU9\SQLServer2005-KB953752-x64-ENU.exe"		
		
	if iVersionHF_32BIT  = 3294 then PathHF_32BIT = "ServicePack\SP2CU10\SQLServer2005-KB956854-x86-ENU.exe"
	if iVersionHF_IA64   = 3294 then PathHF_IA64  = "ServicePack\SP2CU10\SQLServer2005-KB956854-IA64-ENU.exe"
	if iVersionHF_AMD    = 3294 then PathHF_AMD   = "ServicePack\SP2CU10\SQLServer2005-KB956854-x64-ENU.exe"			
	
end if
'----- SQL SERVER -----



'========================================================
'=  workaround for bug with Vista/Longhorn (prompt to stop SQL Agent)
'========================================================

if (Product = ProductLabel2005) and (OSFamily <> "Windows2003") and (OSFamily <> "WindowsXP") then
	SilentRtmSetup  = True	
end if



'========================================================
'=  write environment and script parameters into SQL4SAP.log 
'========================================================

'----- add to log file: silent installation
if SilentInstall then
	msg =       "               =======================" & VbCrLf
	msg = msg & "                     silent mode      " & VbCrLf
	msg = msg & "               =======================" & vbCrLf	
	fsoLog.WriteLine msg
	Wscript.Echo msg
end if

'----- add to log file: continuation installation
if IsContInstall then
	msg =       string(32 + len(ContInstance), "=") & VbCrLf
	msg = msg & "continuing to install instance: " & ContInstance & VbCrLf              
	msg = msg & string(32 + len(ContInstance), "=") & VbCrLf	
	fsoLog.WriteLine msg
	Wscript.Echo msg	
end if

'----- add to log file: system environment
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Computer name in Registry:"
fsoLog.WriteLine "  ActiveComputername= " & RegActiveComputername
fsoLog.WriteLine "  Computername      = " & RegComputername
fsoLog.WriteLine "  Hostname          = " & RegHostname
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Windows version:"
fsoLog.WriteLine "  OSVersion         = " & OSVersion
fsoLog.WriteLine "  OSFamily          = " & OSFamily
fsoLog.WriteLine "  OSServicePack     = " & OSServicePack
fsoLog.WriteLine "  OSEdition         = " & OSEdition
fsoLog.WriteLine "  OSSystemType      = " & OSSystemType
fsoLog.WriteLine "  OSProductSuite    = " & OSProductSuite
fsoLog.WriteLine "  OSMsiVersion      = " & OSMsiVersion
fsoLog.WriteLine "  OSMdacVersion     = " & OSMdacVersion
fsoLog.WriteLine "  OSLanguage        = " & OSLanguage
fsoLog.WriteLine "  OSLanguageID      = " & CStr(OSLanguageID)
fsoLog.WriteLine "  OSLogicalProcessors=" & OSLogicalProcessors
fsoLog.WriteLine "  OSTime            = " & CStr(OSTime)
fsoLog.WriteLine "  OSBootTime        = " & CStr(OSBootTime)
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Environment on "     & myComputer & ":"
fsoLog.WriteLine "  userDir           = " & userDir
fsoLog.WriteLine "  tmpDir            = " & tmpDir
fsoLog.WriteLine "  rootDir           = " & rootDir
fsoLog.WriteLine "  prgDir            = " & prgDir
fsoLog.WriteLine "  prgDirX86         = " & prgDirX86
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "SQL4SAP version:"
Set fsoTmp = fso.GetFile(WScript.ScriptFullName)
fsoLog.WriteLine "  version:          " & SQL4SAPVersion
fsoLog.WriteLine "  size:             " & fsoTmp.size
fsoLog.WriteLine "  created:          " & fsoTmp.DateCreated
fsoLog.WriteLine "  modified:         " & fsoTmp.DateLastModified
fsoLog.WriteLine "  exe:              " & WScript.FullName
fsoLog.WriteLine "  script:           " & fsoTmp.Path

'----- add to log file: UNC path of mapped network drive
myDriveName = left(fsoTmp.Path, 2)
myShareName = myDriveName
if right(myDriveName, 1) = ":" then
	on error resume next
		Set ShareList = GetObject("winmgmts:\\.\root\cimv2").ExecQuery _
			("select * from Win32_NetworkConnection where LocalName = " & chr(34) & myDriveName & chr(34))
		for each Share in ShareList
			myShareName = Share.RemoteName
		next
		fsoLog.WriteLine "  " & myDriveName & "                " & myShareName
	if Not OnErrorResume then on error goto 0
end if

'----- add to log file: script parameter
if Param <> "" then
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "parameters: " & Param
	fsoLog.WriteLine "  Sql4SapOption     = " & Sql4SapOption
	fsoLog.WriteLine "  SQL4SAPVerParam   = " & SQL4SAPVerParam
	fsoLog.WriteLine "  SqlCollation      = " & SqlCollation
	fsoLog.WriteLine "  SQLEditionInst    = " & SQLEditionInst
	fsoLog.WriteLine "  KeyInstall        = " & KeyInstall
	fsoLog.WriteLine "  DotNetNeeded      = " & DotNetNeeded
	fsoLog.WriteLine "  EditionByKey      = " & EditionByKey
	fsoLog.WriteLine "  OSFamily          = " & OSFamily
	fsoLog.WriteLine "  OSEdition         = " & OSEdition
	fsoLog.WriteLine "  OSSystemType      = " & OSSystemType
	fsoLog.WriteLine "  OSSystemAccount   = " & OSSystemAccount
	fsoLog.WriteLine "  iVersionRTM       = " & iVersionRTM
	fsoLog.WriteLine "  iVersionSP        = " & iVersionSP
	fsoLog.WriteLine "  iVersionHF        = " & iVersionHF	
end if



'========================================================
'=  end with ERROR: 32-bit emulation
'========================================================

if prgDirX86 = prgDir then
	msg =       "VB-Script was started in 32-bit emulation" & VbCrLf & VbCrLf
	msg = msg & "Restart SQL4SAP.VBS from Windows Explorer" & VbCrLf
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "32-bit VB-Script")
	call QuitInstallation(1)
end if



'========================================================
'=  end with ERROR: Windows version not supported
'========================================================

found = False
for i = 0 to ubound(OSFamilies)
	if OSFamilies(i) = OSFamily then
		found = True
		RequiredSP = OsFamMinSP(i)
		exit for
	end if
next
if Not found Then
	msg = "OS Family " & chr(34) & OSFamily & chr(34) & " is not supported by this script."
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Windows version error")
	call QuitInstallation(1)
end if



'========================================================
'=  end with ERROR: Alpha platform not supported
'========================================================

if OSSystemType = "Alpha" then
	msg =       "This Windows edition is not supported:" & VbCrLf & VbCrLf
	msg = msg & "OS Edition:     " & vbTab & OSEdition & VbCrLf
	msg = msg & "OS System Type: " & vbTab & OSSystemType & VbCrLf
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Windows edition not supported")
	call QuitInstallation(1)
end if



'========================================================
'=  end with ERROR: Windows cluster not supported
'========================================================

if OSEdition = "Cluster" then
	msg =       "This script does not support Microsoft Cluster Service." & VbCrLf
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Cluster Service not supported")
	call QuitInstallation(1)
end if



'========================================================
'=  WARNING: number of logical CPUs is not a power of 2
'========================================================

'----- SQL SERVER 2005 -----
if (Product = ProductLabel2005) then
		
	i = OSLogicalProcessors
	rc = 0
	while i \ 2 > 0
		rc = i mod 2
		if rc <> 0 then i = 1
		i = i \ 2
	wend
	
	if rc <> 0 then
		msg =       CStr(OSLogicalProcessors) & " logical processors detected." & VbCrLf & VbCrLf
		msg = msg & "SQL Server may not install when the number" & VbCrLf
		msg = msg & "of processors is not a power of 2." & VbCrLf & VbCrLf
		msg = msg & "Do you want to install SQL Server " & Product & " anyway?" & VbCrLf 
		rc = DoMessageBox(msg, vbYesNo + vbExclamation + vbDefaultButton2, "Number of CPUs")
		if rc = vbNo then call QuitInstallation(2)
	end if
	
end if
'----- SQL SERVER -----



'========================================================
'=  end with ERROR: IIS not installed
'========================================================

if FullInstall then
	if not WinService("W3SVC", NetQuery) then
		msg =       "SQL Reporting Services requires IIS Service." & VbCrLf
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "IIS Service not found")
		call QuitInstallation(1)
	end if
end if



'========================================================
'=  end with ERROR: Minimum Windows SP not applied
'========================================================

if CInt(OSServicePack) < RequiredSP then
	msg =       "This service pack of Windows is not supported:" & VbCrLf & VbCrLf
	msg = msg & "installed OS:     " & vbTab & OSFamily & " service pack " & OSServicePack & VbCrLf
	msg = msg & "minimum required: " & vbTab & OSFamily & " service pack " & CStr(RequiredSP) & VbCrLf
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Windows service pack not supported")
	call QuitInstallation(1)
end if



'========================================================
'=  check DVD pathes
'========================================================

'----- calculate pathes
if OSSystemType = "IA64" then
	iVersionRTM    = iVersionRTM_IA64
	iVersionSP     = iVersionSP_IA64
	iVersionHF     = iVersionHF_IA64
	FolderPlatform = FolderIA64
	PathSE         = PathSE_IA64
	PathEE         = PathEE_IA64
	PathDE         = PathDE_IA64
	PathSP         = PathSP_IA64
	PathHF         = PathHF_IA64
elseif OSSystemType = "X64" then
	iVersionRTM    = iVersionRTM_AMD
	iVersionSP     = iVersionSP_AMD
	iVersionHF     = iVersionHF_AMD
	FolderPlatform = FolderAMD
	PathSE         = PathSE_AMD
	PathEE         = PathEE_AMD
	PathDE         = PathDE_AMD
	PathSP         = PathSP_AMD
	PathHF         = PathHF_AMD
else
	iVersionRTM    = iVersionRTM_32BIT
	iVersionSP     = iVersionSP_32BIT
	iVersionHF     = iVersionHF_32BIT
	FolderPlatform = FolderX86
	PathSE         = PathSE_32BIT
	PathEE         = PathEE_32BIT
	PathDE         = PathDE_32BIT
	PathSP         = PathSP_32BIT
	PathHF         = PathHF_32BIT
end if
'----- SQL SERVER 2008 -----
if Product <> ProductLabel2005 then
	FolderPlatform = FolderALL
end if
'----- SQL SERVER -----
sVersionRTM         = sVersionMajor & "." & sVersionMinor & "." & CStr(iVersionRTM)
sVersionSP          = sVersionMajor & "." & sVersionMinor & "." & CStr(iVersionSP)
sVersionHF          = sVersionMajor & "." & sVersionMinor & "." & CStr(iVersionHF)

'----- Check Installation Path
dim newPath
newPath = fso.GetAbsolutePathName(left(WScript.ScriptFullName, InStr(1, WScript.ScriptFullName, WScript.ScriptName, 1) - 1))
if right(newPath,1) <> "\" then newPath = newPath & "\"
if Not fso.FolderExists(newPath & FolderPlatform) Then
	'----- used starter script from ".\x86\SqlCmd\"
	newPath = fso.GetAbsolutePathName(".\..\..\")
	if right(newPath,1) <> "\" then newPath = newPath & "\"	
end if

'----- check folder ".\<platform>\"
if Not fso.FolderExists(newPath & FolderPlatform) Then
	msg =       "SQL4SAP was not started from the original location." & VbCrLf & VbCrLf
	msg = msg & "Enter the installation directory containing the" & VbCrLf
	msg = msg & "original SQL4SAP.VBS and all other installation files."
	newPath = DoInputBox(msg, "Enter installation path", NetworkPath, True)
	if newPath = "" then call QuitInstallation(2)
	if right(newPath,1) <> "\" then newPath = newPath & "\"
	if Not fso.FolderExists(newPath & FolderPlatform) Then
        fsoLog.WriteLine "Could not find setup path in " + (newPath & FolderPlatform)
		rc = DoMessageBox("Installation path is invalid or not accessible.", vbOKOnly + vbCritical, "Invalid installation path")
		call QuitInstallation(1)
	elseif Not fso.FileExists(newPath & "v_10.50.2769_ENT_2500_1600__x64") Then
		fsoLog.WriteLine "Wrong DVD. Could not find v_10.50.2769_ENT_2500_1600__x64"
		rc = DoMessageBox("Installation DVD is invalid. Please use DVD with material #51041678.", vbOKOnly + vbCritical, "Invalid DVD")
		call QuitInstallation(1)
	end if
end if

myRoot = newPath
myDir  = newPath & FolderPlatform & "\"
myDirUNC = FileGetUNC(myDir)



'========================================================
'=  check installable editions
'========================================================

dim SeEditionPossible, EeEditionPossible, DeEditionPossible
SeEditionPossible = False
EeEditionPossible = False
DeEditionPossible = False

'----- check editions by key (FolderSE = FolderEE, FolderDE = FolderEE)
if EditionByKey then
	if fso.FolderExists(myDir & FolderSE) and (KeySE<>"" or KeyInstall<>"") then SeEditionPossible = True
	if fso.FolderExists(myDir & FolderEE) and (KeyEE<>"" or KeyInstall<>"") then EeEditionPossible = True
	if fso.FolderExists(myDir & FolderDE) and (KeyDE<>"" or KeyInstall<>"") then DeEditionPossible = True	

	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Editions by key:"
	fsoLog.WriteLine "  SeEditionPossible = " & SeEditionPossible
	fsoLog.WriteLine "  EeEditionPossible = " & EeEditionPossible
	fsoLog.WriteLine "  DeEditionPossible = " & DeEditionPossible			

'----- check editions by folder	
else
	if fso.FolderExists(myDir & FolderSE) then SeEditionPossible = True
	if fso.FolderExists(myDir & FolderEE) then EeEditionPossible = True
	if fso.FolderExists(myDir & FolderDE) then DeEditionPossible = True

	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Editions by folder:"
	fsoLog.WriteLine "  SeEditionPossible = " & SeEditionPossible
	fsoLog.WriteLine "  EeEditionPossible = " & EeEditionPossible
	fsoLog.WriteLine "  DeEditionPossible = " & DeEditionPossible
end if


'----- check allowed editions by label 
'      ("v_09.00.3042_DEV_3042_1399__x64" with exact 31 character length)
'        1234567890123456789012345678901
dim SeEditionLabel, EeEditionLabel, DeEditionLabel
SeEditionLabel = False
EeEditionLabel = False
DeEditionLabel = False
if LabelProduct <> "" then
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "DVD labels:"
	on error resume next
			set fsoMyFolder = fso.GetFolder(fso.GetParentFolderName(WScript.ScriptFullName))
			set fsoMyFiles = fsoMyFolder.Files
			for each fsoFile in fsoMyFiles
				temp = LCase(fsoFile.Name)
				if len(temp) = 31 then
					if left(temp,7) = LabelProduct then
						fsoLog.WriteLine "  " & temp
						if right(temp,4) = Lcase(right("____" & OSSystemType, 4)) then
							if mid(temp,14,3) = "std" then SeEditionLabel = True
							if mid(temp,14,3) = "ent" then EeEditionLabel = True
							if mid(temp,14,3) = "dev" then DeEditionLabel = True
						end if
					end if				
				end if
			next
	if Not OnErrorResume then on error goto 0

	SeEditionPossible = SeEditionPossible and SeEditionLabel
	EeEditionPossible = EeEditionPossible and EeEditionLabel
	DeEditionPossible = DeEditionPossible and DeEditionLabel
end if


'----- check if parameter SQLEditionInst is possible
if SQLEditionInst = SQLEditionEE then
	if not EeEditionPossible then SQLEditionInst = ""
elseif SQLEditionInst = SQLEditionSE then
	if not SeEditionPossible then SQLEditionInst = ""	
elseif SQLEditionInst = SQLEditionDE then
	if not DeEditionPossible then SQLEditionInst = ""	
else
	'----- ignore invalid parameter SQLEditionInst
	SQLEditionInst = ""
end if

'----- default edition
if SQLEditionInst = "" then
	'----- default edition on server
	if (OSEdition <> "Workstation") then 
		if EeEditionPossible then
			SQLEditionInst = SQLEditionEE
		elseif SeEditionPossible then 
			SQLEditionInst = SQLEditionSE
		else
			SQLEditionInst = SQLEditionDE
		end if
	'----- default edition on workstation
	else
		if DeEditionPossible then
			SQLEditionInst = SQLEditionDE
		elseif SeEditionPossible then 
			SQLEditionInst = SQLEditionSE
		else
			SQLEditionInst = SQLEditionEE
		end if	
	end if
end if

fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Possible editions:"
fsoLog.WriteLine "  SeEditionPossible = " & SeEditionPossible
fsoLog.WriteLine "  EeEditionPossible = " & EeEditionPossible
fsoLog.WriteLine "  DeEditionPossible = " & DeEditionPossible
fsoLog.WriteLine "  SQLEditionInst    = " & SQLEditionInst
fsoLog.WriteLine "----------------------------------------"




'========================================================
'=  end with ERROR: no Edition found
'========================================================

if not (SeEditionPossible or EeEditionPossible or DeEditionPossible) then
	msg =       "Installation files for platform" & OSSystemType & VbCrLf & VbCrLf
	msg = msg & "not found on DVD in directory " & myDir & VbCrLf
	rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Files not found")
	call QuitInstallation(1)
end if



'========================================================
'=  set authentication mode
'========================================================

dim PolicyAuth
if SqlAuthInstall then
	PolicyAuth = "SQL Server and Windows"
else
	PolicyAuth = "Windows only"
end if



'========================================================
'=  WARNING: 32-bit SQL Server 2008 (or newer) not supported by SAP
'========================================================

'----- SQL SERVER 2008 or newer -----
if (Product <> ProductLabel2005) and (not IsContInstall) then
	
	if (OSSystemType = "X86") and (OSEdition <> "Workstation") then
		msg =       "SAP only supports 64-bit SQL Server " & Product & VbCrLf & VbCrLf
		msg = msg & "Do you want to install 32-bit SQL Server " & Product & " anyway?" & VbCrLf 
		rc = DoMessageBox(msg, vbYesNo + vbExclamation + vbDefaultButton2, "32-bit SQL 2008")
		if rc = vbNo then call QuitInstallation(2)
	end if
	
end if
'----- SQL SERVER -----



'========================================================
'=  calculate path to redisrtibution folder
'========================================================

dim PathRedist
dim Setup_Root
'----- calculate path (currently only EnterpriseEdition Folder exists)
	PathRedist = myDir & FolderEE & "\" & LCase(OSSystemType) & "\redist\"
	Setup_Root = myDir & FolderEE & "\"
if not fso.FolderExists(PathRedist) then
	PathRedist = myDir & FolderDE & "\" & LCase(OSSystemType) & "\redist\"
	Setup_Root = myDir & FolderDE & "\"
end if
if not fso.FolderExists(PathRedist) then
	PathRedist = myDir & FolderSE & "\" & LCase(OSSystemType) & "\redist\"
	Setup_Root = myDir & FolderSE & "\"
end if
if not fso.FolderExists(PathRedist) then
	PathRedist = myDir
	Setup_Root = myDir
end if

'===========================================================
'= Calculate path to .Net installation folders
'===========================================================
if (Product = "2005") or (Product = "2008") then
	DotNet20_IA64_Setup = PathRedist & "2.0\NetFx20SP2_ia64.exe"
	DotNet351_Setup = PathRedist & "DotNetFrameworks\dotNetFx35setup.exe"
elseif (Product = "2008R2") then
	DotNet20_IA64_Setup = PathRedist & "2.0\NetFx20SP2_ia64.exe"
	DotNet351_Setup = Setup_Root & "redist\DotNetFrameworks\dotNetFX35\" & LCase(OSSystemType) & "\netfx35_" & LCase(OSSystemType) & "exe"
end if



'========================================================
'=  end with ERROR: Windows Installer needs update
'========================================================

dim iMsiVersion, MsiPath, MsiExe
if len(OSMsiVersion) < 3 then
	iMsiVersion = 0
else
	iMsiVersion = Cint(left(OSMsiVersion,1) & right(left(OSMsiVersion,3),1))
end if

if (Product =ProductLabel2008R2) then
    MsiPath = PathRedist & "Windows Installer"
else
    MsiPath = PathRedist & "Windows Installer\" & LCase(OSSystemType)
end if

'----- SQL SERVER 2008 or newer -----
if Product <> ProductLabel2005 then
	if iMsiVersion < 45 then
		
		'----- open redist folder with explorer
		on error resume next
			rc= WshShell.Run("explorer " & chr(34) & MsiPath & chr(34))
		if Not OnErrorResume then on error goto 0
		WScript.Sleep 1000

		'----- message box
		msg = "You need to update Microsoft Installer (MSI) first" & VbCrLf & VbCrLf _
			& "installed MSI version:" & vbtab & OSMsiVersion & VbCrLf _
			& "required MSI version:" & vbtab & "4.5" & VbCrLf & VbCrLf _
			& "You can install MSI "
		if OSFamily = "Windows2003" then
			msg = msg & "by starting INSTMSI45.EXE from:" & VbCrLf
		elseif OSFamily = "WindowsXP" and OSSystemType = "X86" then
			msg = msg & "by starting INSTMSI45XP.EXE from:" & VbCrLf
		elseif OSFamily6 then
			msg = msg & "by starting INSTMSI45.MSU from:" & VbCrLf
		else
			msg = msg & "manually from:" & VbCrLf
		end if
		msg = msg	& MsiPath & "\" & VbCrLf & VbCrLf _
				& "Use the executable (.EXE) for Windows 2003." & VbCrLf _
				& "Use the Microsoft update package (.MSU) for Windows 2008." & VbCrLf _
				& "After the MSI installation you probably need to reboot Windows."
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "MSI version too old")
		
		call QuitInstallation(1)	
	end if
end if
'----- SQL SERVER -----



'========================================================
'=  Warning: Supported Editions
'========================================================

if not IsContInstall then
	if SqlAuthInstall then
		msg = VbCrLf
		msg = msg & "========================================" & vbTab & VbCrLf
		msg = msg & "This script installs " & chr(34) & "SQL Server and Windows" & chr(34) & " authentication mode" & VbCrLf 
		msg = msg & "========================================" & vbTab & VbCrLf & VbCrLf
		msg = msg & "The most secure mode is " & chr(34) & "Windows Only" & chr(34) & " authentication." & VbCrLf & VbCrLf
		msg = msg & "To install " & chr(34) & "Windows Only" & chr(34) & " authentication, start SQL4SAP.VBS" & VbCrLf
		rc = DoMessageBox(msg, vbOKOnly + vbInformation, "SQL Server and Windows mode")
	end if
end if



'========================================================
'=  write script settings into SQL4SAP.log 
'========================================================

'----- add to log file: pathes and script settings
fsoLog.WriteLine VbCrLf & VbCrLf
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Script path:"
fsoLog.WriteLine "  myRoot            = " & myRoot
fsoLog.WriteLine "  myDir             = " & myDir
fsoLog.WriteLine "  myDirUNC          = " & myDirUNC
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine "Script settings:"
fsoLog.WriteLine "  SqlAuthInstall    = " & SqlAuthInstall
fsoLog.WriteLine "  SilentInstall     = " & SilentInstall
fsoLog.WriteLine "  SilentRtmSetup    = " & SilentRtmSetup
fsoLog.WriteLine "  FullInstall       = " & FullInstall
fsoLog.WriteLine "  isSlipstreamedCU  = " & isSlipstreamedCU
fsoLog.WriteLine "  isSlipstreamedSP  = " & isSlipstreamedSP
fsoLog.WriteLine "----------------------------------------"



'========================================================
'=  set registry keys to supress warnings
'========================================================

'----- Suppress the Appshelp Message in an Unattended Installation for SQL2005 and Lonhorn
'-- SQL RELEASE DEPENDENT --
'----- old
RegValueName(0) = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\{3d06c673-5e8a-41c0-b47f-3c3ca0a22e67}"
RegValueData(0) = RegRead(RegValueName(0))
call RegWrite(RegValueName(0), 4, "REG_DWORD")
'----- old
RegValueName(3) = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\{319b29ae-7427-4fbc-9355-22df056c27a4}"
RegValueData(3) = RegRead(RegValueName(3))
call RegWrite(RegValueName(3), 4, "REG_DWORD")
'----- ???
RegValueName(3) = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\{2a0da30d-846f-4680-89da-2dbc457d7b44}"
RegValueData(3) = RegRead(RegValueName(3))
call RegWrite(RegValueName(3), 4, "REG_DWORD")
'----- Windows 2008
RegValueName(3) = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\{2b9034f3-b661-4d36-a5ef-60ab5a711ace}"
RegValueData(3) = RegRead(RegValueName(3))
call RegWrite(RegValueName(3), 4, "REG_DWORD")
'-- SQL RELEASE DEPENDENT END --


'----- Suppress the warning when starting an executable from a network share
dim ServerNameArray, ServerName, DriveName
on error resume next
	DriveName = left(myDir, 2)
	if DriveName = "\\" then
		ServerNameArray = split(myDir, "\")
	elseif right(DriveName, 1) = ":" then
		Set ShareList = GetObject("winmgmts:\\.\root\cimv2").ExecQuery _
			("select * from Win32_NetworkConnection where LocalName = " & chr(34) & DriveName & chr(34))
		for each Share in ShareList
			ServerNameArray = split(Share.RemoteName, "\")
		next
	end if
if Not OnErrorResume then on error goto 0
if not IsEmpty(ServerNameArray) then
	ServerName = ServerNameArray(2)
	RegKeyName(1) = "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\"
	RegKeyName(2) = "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\"
	for i = 1 to 2
		RegValueName(i) = RegKeyName(i) & ServerName & "\*"
		RegValueData(i) = RegRead(RegValueName(i))
		call RegWrite(RegValueName(i), 1, "REG_DWORD")
	next
end if



'========================================================
'=  check for installed SQL products
'========================================================

'----- ADD 
'----- Add logic for installed products
'----- check Uninstall in registry, set ToolsInstalled, ExpressInstalled, SnacInstalled
dim oReg, sBaseKey, aSubKeys, sKey, sValue
on error resume next
	set oReg = GetObject("winmgmts:\\.\root\default:StdRegProv")
	sBaseKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
	oReg.EnumKey HKLM, sBaseKey, aSubKeys
	for each sKey in aSubKeys
		sValue = " "
		oReg.GetStringValue HKLM, sBaseKey & sKey, "DisplayName", sValue
		if not isnull(sValue) then
			if InStr(1, sValue, "SQL Server", 1) > 0 then
				RegSummary = RegSummary & "HKLM\" & sBaseKey & sKey & "\DisplayName" 
				RegSummary = RegSummary & VbCrLf & "READ: " & sValue & VbCrLf & VbCrLf
'----- SQL SERVER 2008 R2 --
                if Product = ProductLabel2008R2 then
					if left(sValue,31) = "SQL Server 2008 R2 Client Tools"                then ToolsInstalled   = true
					if left(sValue,39) = "Microsoft SQL Server 2008 R2 Native Client"        then SnacInstalled    = true	
					if left(sValue,46) = "Microsoft SQL Server Management Studio Express" then ExpressInstalled = true
'----- SQL SERVER 2008 -----
				elseif Product = ProductLabel2008 then
					if left(sValue,31) = "Microsoft SQL Server 2008 Tools"                then ToolsInstalled   = true
					if left(sValue,39) = "Microsoft SQL Server 2008 Native Client"        then SnacInstalled    = true	
					if left(sValue,46) = "Microsoft SQL Server Management Studio Express" then ExpressInstalled = true
'----- SQL SERVER 2005 -----
				elseif Product = ProductLabel2005 then
					if left(sValue,31) = "Microsoft SQL Server 2005 Tools"                then ToolsInstalled   = true
					if left(sValue,34) = "Microsoft SQL Server Native Client"             then SnacInstalled    = true	
					if left(sValue,46) = "Microsoft SQL Server Management Studio Express" then ExpressInstalled = true					
				end	if
'----- SQL SERVER -----
			end if	
		end if
	next


'----- check .Net version installed
fsoLog.WriteLine "Installed .NET Framework:"		
	sBaseKey = "Installer\Products\"
	oReg.EnumKey HKCR, sBaseKey, aSubKeys
	for each sKey in aSubKeys
		sValue = " "
		oReg.GetStringValue HKCR, sBaseKey & sKey, "ProductName", sValue
		if not isnull(sValue) then
			if InStr(1, sValue, "SQL Server", 1) > 0 then
				RegSummary = RegSummary & "HKCR\" & sBaseKey & sKey & "\ProductName" 
				RegSummary = RegSummary & VbCrLf & "READ: " & sValue & VbCrLf & VbCrLf			
			end if
			if InStr(1, sValue, ".NET Framework", 1) > 0 then
				RegSummary = RegSummary & "HKLM\" & sBaseKey & sKey & "\DisplayName" 
				RegSummary = RegSummary & VbCrLf & "READ: " & sValue & VbCrLf & VbCrLf	
fsoLog.WriteLine "  " & sValue
			end if	
		end if
	next
fsoLog.WriteLine "----------------------------------------"
if Not OnErrorResume then on error goto 0


'========================================================
'=  get list of installed SQL instances
'========================================================

'----- get list of installed SQL Server instances => sInstancesName()
dim sInstancesWow6432, sInstancesHKLM, sInstancesName(), sInstancesNameCnt, FoundSQL7
' e.g. "MSSQLSERVER", "PRD", "TST"
dim SQLRegBIT, sInstancesBIT()
' e.g. "32", "64"
dim SQLRegPrefix, sInstancesPrefix()
' e.g. "HKLM\SOFTWARE\Microsoft\MSSQLServer\"
'      "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\"
'      "HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\"
dim SQLRegName, sInstancesRegName()
' e.g. ""            for SQL 2000 default instance
'      "PRD"         for SQL 2000 named instance "PRD"
'      "MSSQL.1"     for SQL 2005 instance (any)
'      "MSSQL10.PRD" for SQL 2008 named instance "PRD"
dim SQLRegEXE, sInstancesEXE()
' e.g. "C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL"
'      "C:\Program Files (x86)\Microsoft SQL Server\MSSQL$SQL2000"
'      "C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL"
dim SQLRegLOG, sInstancesLOG()
' e.g. "C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\LOG\ERRORLOG"
'      "C:\Program Files (x86)\Microsoft SQL Server\MSSQL$SQL2000\LOG\ERRORLOG"
'      "C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG"
call DimInstanceList
call SetInstanceList
call SortInstanceList



'========================================================
'=  continue of Client Tools Installation
'========================================================

if IsContInstall and (ContInstance = "Client Tools") then
	ClientToolsOnly = True
end if



'========================================================
'=  workstation not supported for SQL 2005 Enterprise Edition
'========================================================

'-----ADD
if (Product = ProductLabel2005) and _
(SQLEditionInst = SQLEditionEE) and _
(OSEdition = "Workstation") and _
(not ClientToolsOnly) and _
(sInstancesNameCnt = 0) then
	'----- don't show this message box if there is already a SQL instance to allow applying an SP
	msg =       "SQL Server " & SQLEditionEE & VbCrLf
	msg = msg & "cannot be installed on a workstation" & VbCrLf & VbCrLf
	msg = msg & "Press OK to install Client Tools only" & VbCrLf
	rc = DoMessageBox(msg, vbOKCancel + vbExclamation, OSEdition & " not supported")
	if SilentInstall then call QuitInstallation(1)
	if rc = vbCancel then call QuitInstallation(2)
	ClientToolsOnly = True	
end if



'========================================================
'=  Choose SQL Instance dialog box
'========================================================

if not ClientToolsOnly Then
	dim ChooseInstance, DisplayClientVers, DisplayDefaultInstance
	
	if IsContInstall then
		ChooseInstance = ContInstance
		if ChooseInstance = "(default)" then ChooseInstance = "MSSQLSERVER"
	
	else
		DisplayDefaultInstance = "(default)"
		'----- repeat until valid input
		do
			'----- print Instances
			msg = "The following SQL Server instances were found:" & VbCrLf
			msg = msg & "======================================" & VbCrLf
			if (sInstancesNameCnt = 0) then
				msg = "No SQL Server instance was found." & VbCrLf
			else
				for i = 0 to ubound(sInstancesName)
					temp = sInstancesName(i)
					if temp = "MSSQLSERVER" then temp = "(default)"
					if len(temp) < 8 then temp = temp + space(8-len(temp))
					'----- hide SQL Server Embedded Edition
					if temp <> "MICROSOFT##SSEE" then
						msg = msg & sInstancesBIT(i) & "-bit Instance" & vbTab & temp & "     "
						msg = msg & vbTab & GetInstanceVersion(sInstancesName(i))  & VbCrLf
					end if
				next
			end if
			
			'----- print client Tools version
			msg = msg & "======================================" & VbCrLf
			dim myClientVer
            dim mySNACVer
			myClientVer = 0
            mySNACVer = 0
			
            DisplayClientVers = GetInstanceVersion("Client Tools 2008R2")
			if VersionBuild <> 0 then msg = msg & "SQL Server 2008 R2 Client Tools" & vbTab & DisplayClientVers & VbCrLf
			if Product = ProductLabel2008R2 then myClientVer = VersionBuild

			DisplayClientVers = GetInstanceVersion("Client Tools 2008")
			if VersionBuild <> 0 then msg = msg & "SQL Server 2008 Client Tools" & vbTab & DisplayClientVers & VbCrLf
			if Product = "2008" then myClientVer = VersionBuild
	
			DisplayClientVers = GetInstanceVersion("Client Tools 2005")
			if VersionBuild <> 0 then msg = msg & "SQL Server 2005 Client Tools" & vbTab & DisplayClientVers & VbCrLf
			if Product = "2005" then myClientVer = VersionBuild
	
            DisplayClientVers = GetInstanceVersion("Native Client 2008R2")
			if VersionBuild <> 0 then msg = msg & "SNAC 2008 R2 (SQL Native Client)" & vbTab & DisplayClientVers & VbCrLf
            if Product = ProductLabel2008R2 then mySNACVer = VersionBuild

			DisplayClientVers = GetInstanceVersion("Native Client 2008")
			if VersionBuild <> 0 then msg = msg & "SNAC 2008 (SQL Native Client)" & vbTab & DisplayClientVers & VbCrLf
            if Product = "2008" then mySNACVer = VersionBuild
	
			DisplayClientVers = GetInstanceVersion("Native Client 2005")
			if VersionBuild <> 0 then msg = msg & "SNAC 2005 (SQL Native Client)" & vbTab & DisplayClientVers & VbCrLf
            if Product = "2005" then mySNACVer = VersionBuild
	
			'----- print options
			msg = msg & VbCrLf & VbCrLf	& VbCrLf
			msg = msg & "Enter the new or existing name of a" & VbCrLf
			msg = msg & OSSystemBit & "-bit SQL Server " & Product & " instance:" & VbCrLf 
			msg = msg & " ++++++++++++++++++++++++++++++++++++" & VbCrLf
			msg = msg & " +  for a Default Instance, enter:" & vbTab & "(default)" & VbCrLf
			msg = msg & " +  for a Named Instance, enter:  " & vbTab & "<SID>" & VbCrLf
		
            dim updateClientToolsPossible
            updateClientToolsPossible = ((myClientVer < iVersionSP) or (mySNACVer < iVersionSP) or (mySNACVer < iVersionHF))

			'----- if client not installed 
			if (myClientVer = 0) then
				msg = msg & " +  to install SQL Client Tools only, press Cancel." & VbCrLf
            '------- if Client Tools can be updated
            elseif updateClientToolsPossible then
                msg = msg & " +  to update SQL Client Tools only, press Cancel." & VbCrLf
			end if
			msg = msg & " ++++++++++++++++++++++++++++++++++++" & VbCrLf
			
			'----- choose instance
			'----- COMPLETELY SILENT INSTALL WITHOUT ANY INFORMATION, BY JOKER
			'----- If SQLSERVER not installed, choose default, else cancel directly, BY JOKER
			if (sInstancesNameCnt = 0) then
				ChooseInstance = "(default)"
			else
				ChooseInstance = ""
			end if
			
			'----- ChooseInstance = Trim(DoInputBox(msg, "Select SQL Server " & Product & " instance", DisplayDefaultInstance, True))
			if ChooseInstance = "(default)" then ChooseInstance = "MSSQLSERVER"
			
			'----- pressed CANCEL (no option to install / update Client Tools) 
			if (ChooseInstance = "") and (myClientVer >= iVersionSP) and not (updateClientToolsPossible) then call QuitInstallation(2)
			
			'----- CLIENT TOOLS or DEFAULT INSTANCE
			if (ChooseInstance = "") or (ChooseInstance = "MSSQLSERVER")  then exit do
			
			'----- NAMED INSTANCE, which already exists
			if InstanceDoesExist(UCase(ChooseInstance)) then exit do
			
			'----- NAMED INSTANCE, but no DEFAULT INSTANCE exists
			if not InstanceDoesExist("MSSQLSERVER") then
				msg =       "SAP recommends that you install a Default Instance" & VbCrLf & VbCrLf
				msg = msg & "Do you want to install a Default Instance of SQL Server"
				rc = DoMessageBox(msg, vbYesNo + vbExclamation , "SAP recommendation")
				if rc = vbYes then
					ChooseInstance = "MSSQLSERVER"
					exit do
				end if
			end if
	
			'----- NAMED INSTANCE, with 3 byte length 
			if len(ChooseInstance) = 3 then exit do
	
			'----- warning: SAP naming convention
			msg =       "The instance name must conform to SAP naming conventions." & VbCrLf
			msg = msg & "You can only install an SAP system if the instance name" & VbCrLf
			msg = msg & "consists of 3 uppercase letters or numbers." & VbCrLf & VbCrLf & VbCrLf
			msg = msg & "Press Retry to enter a new instance name." & VbCrLf & VbCrLf
			msg = msg & "Press Ignore to install SQL Server not to be used for an SAP system."
			rc = DoMessageBox(msg, vbAbortRetryIgnore + vbExclamation + vbDefaultButton2, "SAP naming convention")
			if rc = vbAbort then call QuitInstallation(2)
			
			'----- NAMED INSTANCE, with NOT 3 byte length
			if rc = vbIgnore then exit do
			
			'----- rc = vbRetry
		Loop while True
	end if
	
	myInstance = UCase(ChooseInstance)
	if myInstance = "" then 
		ClientToolsOnly = True
	else 
		SqlDoesExist = InstanceDoesExist(myInstance)
		if SqlDoesExist then call GetInstanceList(myInstance)
	end if
end if



'========================================================
'=  workstation not supported for SQL 2005 Enterprise Edition
'========================================================

if (Product = ProductLabel2005) and _
(SQLEditionInst = SQLEditionEE) and _
(OSEdition = "Workstation") and _
(not ClientToolsOnly) then
	msg =       "SQL Server " & SQLEditionEE & VbCrLf
	msg = msg & "cannot be installed on a Workstation" & VbCrLf & VbCrLf
	msg = msg & "Press OK to install Client Tools only" & VbCrLf
	rc = DoMessageBox(msg, vbOKCancel + vbExclamation, OSEdition & " not supported")
	if SilentInstall then call QuitInstallation(1)
	if rc = vbCancel then call QuitInstallation(2)
	ClientToolsOnly = True	
end if



'========================================================
'=  warning for SQL 2005 on Windows Vista (SP0), workaround for bug in MS KB 932593
'========================================================

if (not ClientToolsOnly) and _
(Product = ProductLabel2005) and _
(OSFamily = "WindowsVista") and _
(CInt(OSServicePack) < 1) then
	msg =       "Warning: Windows Vista without Service Pack" & VbCrLf 
	msg = msg & "Check the following Microsoft KB article" & VbCrLf
	msg = msg & "if the installation of SQL Server on Vista fails:" & VbCrLf & VbCrLf
	msg = msg & "http://support.microsoft.com/default.aspx?scid=kb;en-us;932593" & VbCrLf
	rc = DoMessageBox(msg, vbOKCancel + vbExclamation + vbDefaultButton2, "Vista hotfix might be needed")
	if rc = vbCancel then call QuitInstallation(2)
end if



'========================================================
'=  warning for SQL 2005 on Windows 2008: hostname issue
'========================================================

if (not ClientToolsOnly) and _
(Product = ProductLabel2005) and _
(OSFamily = "Windows2008") and _
(ConsistentHostname <> 0) then
	msg =       "Warning: Inconsistent (case-sensitive) names:" & VbCrLf & VbCrLf
	msg = msg & vbTab & "Active name:"  & vbTab & RegActiveComputername & VbCrLf
	msg = msg & vbTab & "Computername:" & vbTab & RegComputername & VbCrLf
	msg = msg & vbTab & "IP hostname:"  & vbTab & RegHostname & VbCrLf	& VbCrLf
	msg = msg & "This might cause the SQL Server installation to fail." & VbCrLf
	msg = msg & "Do you really want to continue?" & VbCrLf
	rc = DoMessageBox(msg, vbYesNo + vbDefaultButton2 + vbExclamation, "Inconsistent names")
	if rc = vbNo then call QuitInstallation(2)
end if



'========================================================
'=  calculate path and target version for Client Tools
'========================================================

if ClientToolsOnly then
	
	'----- Client Edition
	myInstance = ""
	SQLEditionInst = SQLEditionCL
	InstanceText = "Client Tools"
	
	'----- calculate path
	if EeEditionPossible then
		PathInst = PathEE
	elseif SeEditionPossible then
		PathInst = PathSE
	else
		PathInst = PathDE
	end if
	
	'----- calculate version
	SqlDoesExist = ToolsInstalled
	if SqlDoesExist then
		GetInstanceVersion("Client Tools")
		iVersion = VersionBuild
		sVersion = VersionStr
		
        '---- HF Version should always be higher or equal than SP Version
		if iVersion < iVersionHF then
            iVersionTarget = iVersionHF
        elseif iVersion < iVersionSP then
			iVersionTarget = iVersionSP
        else
			iVersionTarget = iVersion
		end if
	else
		iVersion = 0
		iVersionTarget = iVersionHF			
	end if
	
end if



'========================================================
'=  calculate path, target version etc for a SQL Instance
'========================================================

if (not ClientToolsOnly) then
	
	'----- calculate path
	if (SQLEditionInst = SQLEditionEE) then
		PathInst = PathEE
	elseif (SQLEditionInst = SQLEditionSE) then
		PathInst = PathSE
	else
		PathInst = PathDE
	end if

	'----- calculate version
	if SqlDoesExist then
		call CalcVersions(GetInstanceVersion(myInstance))
		iVersion = VersionBuild
		sVersion = VersionStr
		
		if iVersion < iVersionHF then
			iVersionTarget = iVersionHF
		else
			iVersionTarget = iVersion
		end if
	else
		iVersion = 0
		iVersionTarget = iVersionHF
		
		myPassword = "RANDOM-password-" & int((99999999*rnd)+1) & int((99999999*rnd)+1)	
	end if
	
	'----- set Windows service names
	if myInstance = "MSSQLSERVER" then
		myService       = "MSSQLSERVER"
		myAgentService  = "SQLSERVERAGENT"
		InstanceText    = "(default)"
	else
		myService       = "MSSQL$" & myInstance
		myAgentService  = "SQLAgent$" & myInstance
		InstanceText    = myInstance	
	end if

end if



'========================================================
'=  ERROR: Cannot apply SP/HF to an older SQL Server (wrong major version)
'========================================================

if (not ClientToolsOnly) and SqlDoesExist then
	if (iVersionMajor <> VersionMajor) or (iVersionMinor <> VersionMinor) or (iVersion < iVersionRTM) then
		msg =       "This script installs new instances of SQL Server " & Product & "." & VbCrLf
		msg = msg & "It can apply a Service Pack or Hotfix to an existing" & VbCrLf
		msg = msg & "SQL Server " & Product &  " instance." & VbCrLf & VbCrLf
		msg = msg & "However, this script cannot upgrade the following instance" & VbCrLf
		msg = msg & "to SQL Server " & Product & ". Perform the version upgrade manually." & VbCrLf & VbCrLf
		msg = msg & "SQL Instance: " & vbTab & myInstance & VbCrLf
		msg = msg & "SQL Version:  " & vbTab & sVersion & VbCrLf
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Version error")
		call QuitInstallation(1)
	end if
end if



'========================================================
'=  ERROR: Cannot apply SP/HF to a 32-bit SQL Server on 64-bit Windows
'========================================================

if (not ClientToolsOnly) and SqlDoesExist then
	if (SQLRegBIT = 32) and (OSSystemBit = 64) then
		msg =       "SAP only supports 64-bit SQL Server " & Product & " instances" & VbCrLf
		msg = msg & "on a 64-bit Windows operating system." & VbCrLf & VbCrLf
		msg = msg & "Therefore the following instance is not supported:" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance: " & vbTab & myInstance & VbCrLf
		msg = msg & "SQL Version:  " & vbTab & sVersion & VbCrLf
		msg = msg & "SQL Server:   " & vbTab & SQLRegBIT & "-bit" & VbCrLf
		msg = msg & "Windows:      " & vbTab & OSSystemBit & "-bit" & VbCrLf
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "platform mismatch")
		call QuitInstallation(1)		
	end if			
end if
	


'========================================================
'=  choose product key
'========================================================

if not SqlDoesExist then	
	
	'----- default product key
	if KeyInstall = "" then
		if SQLEditionInst = SQLEditionSE then
			KeyInstall = KeySE
		elseif SQLEditionInst = SQLEditionEE then
			KeyInstall = KeyEE
		elseif SQLEditionInst = SQLEditionDE then
			KeyInstall = KeyDE
		elseif SQLEditionInst = SQLEditionCL then
			KeyInstall = KeyCL
		else
			KeyInstall = ""
		end if
	end if
	
	'----- choose product key
	if KeyInstall = KeyDefault then
		KeyInstall = ""
		do
			msg =       "Enter the 25 digit" & VbCrLf
			msg = msg & "SQL Server license key:" & VbCrLf
			KeyInstall = DoInputBox(msg, "Enter key", KeyInstall, True)
			KeyInstall = replace(KeyInstall, "-", "")
			KeyInstall = replace(KeyInstall, " ", "")
			
			rc = vbIgnore
			if len(KeyInstall) <> 25 then
				msg = "Invalid key"
				rc = DoMessageBox(msg, vbAbortRetryIgnore + vbExclamation, "Invalid key")
				if rc = vbAbort then call QuitInstallation(2)
			end if
		loop while (rc = vbRetry)

'----- SQL SERVER 2008 -----
		if Product <> ProductLabel2005 then
			KeyInstall = mid(KeyInstall, 1,5) & "-" _
					   & mid(KeyInstall, 6,5) & "-" _
					   & mid(KeyInstall,11,5) & "-" _
					   & mid(KeyInstall,16,5) & "-" _
					   & mid(KeyInstall,21,5)
		end if
'----- SQL SERVER -----
	end if

end if




sVersionTarget = sVersionMajor & "." & sVersionMinor & "." & CStr(iVersionTarget)
fsoLog.WriteLine VbCrLf & VbCrLf
fsoLog.WriteLine "Registry settings (1/2):"
fsoLog.WriteLine "----------------------------------------"
fsoLog.WriteLine RegSummary 
fsoLog.WriteLine "----------------------------------------" & VbCrLf
RegSummary = ""



'========================================================
'=  Confirm Input dialog box (Client Tools)
'========================================================

if ClientToolsOnly then
	
	'----- already newer client tools installed
	if (iVersion >= iVersionTarget) then
		msg =       "You have already installed the SQL Server Client Tools" & VbCrLf & VbCrLf
		msg = msg & "  Client Version:   " & vbTab & sVersion & VbCrLf & VbCrLf & VbCrLf
		msg = msg & "There is nothing to do."
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Finish")
		call QuitInstallation(0)
		
	'----- beta version of client tools installed
	elseif (iVersion > 0) and (iVersion < iVersionRTM) then
		msg =       "You have installed a beta version of SQL Server Client Tools" & VbCrLf & VbCrLf
		msg = msg & "  Client Version:   " & vbTab & sVersion & VbCrLf & VbCrLf & VbCrLf
		msg = msg & "This script does not update beta software."
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Finish")
		call QuitInstallation(1)
	
	'----- upgrade client tools (SP + HF)
	elseif SqlDoesExist then
		msg =       "You have chosen to upgrade the SQL Server Client Tools" & VbCrLf & VbCrLf
		msg = msg & "  Client Version:   " & vbTab & sVersion & VbCrLf & VbCrLf
		msg = msg & "to" & VbCrLf & VbCrLf
		msg = msg & "  Client Version:   " & vbTab & sVersionTarget & VbCrLf & VbCrLf & VbCrLf
		msg = msg & "Do you want to start the upgrade now?"
		
	'----- install client tools (RTM + SP + HF)
	else
		msg =       "You do not need to install the " & chr(34) & "SQL Server Client Tools" & chr(34) & VbCrLf
		msg = msg & "on an SAP Application Server. It is sufficient to install" & VbCrLf
		msg = msg & "the " & chr(34) & "SQL Server Native Client (SNAC)" & chr(34) & " instead." & VbCrLf & VbCrLf		
		msg = msg & "You can install or upgrade the appropriate SNAC manually from:"  & VbCrLf
'----- SQL SERVER 2005 -----
		if Product = ProductLabel2005 then
			msg = msg & myRoot & "x86\sqlncli.msi" & VbCrLf
			msg = msg & myRoot & "x64\sqlncli.msi" & VbCrLf
			msg = msg & myRoot & "IA64\sqlncli.msi" & VbCrLf & VbCrLf
        elseif Product = ProductLabel2008R2 then
			msg = msg & PathInst & "x86\Setup\x86\sqlncli.msi" & VbCrLf
			msg = msg & PathInst & "x64\Setup\x64\sqlncli.msi" & VbCrLf
			msg = msg & PathInst & "IA64\Setup\IA64\sqlncli.msi" & VbCrLf & VbCrLf
'----- SQL SERVER 2008 -----		
		else
			msg = msg & myRoot & "SqlNativeClient\x86\sqlncli.msi" & VbCrLf
			msg = msg & myRoot & "SqlNativeClient\x64\sqlncli.msi" & VbCrLf
			msg = msg & myRoot & "SqlNativeClient\ia64\sqlncli.msi" & VbCrLf & VbCrLf
		end if
'----- SQL SERVER -----
		msg = msg & "=======================================" & VbCrLf
		msg = msg & "Installing SQL Server Client Tools might take 15 minutes or longer" & VbCrLf		
		if not SilentRtmSetup then
			msg = msg & "In the event of an error you might have to press the " & chr(34) & "Next>>" & chr(34) & " button  " & VbCrLf
		end if
		msg = msg & "=======================================" & VbCrLf & VbCrLf				
		msg = msg & "Do you want to install the " & chr(34) & "SQL Server Client Tools" & chr(34) & " now?        "
	end if
	
	'----- message box
	rc = DoMessageBox(msg, vbOKCancel + vbQuestion, "Confirmation")
	if rc <> vbOK then call QuitInstallation(2)
end if



'========================================================
'=  Confirm Input dialog box (Instance Upgrade or Install)
'========================================================

if (not ClientToolsOnly) then
	
	'----- already newer SQL Server version installed
	if (iVersion >= iVersionTarget) then
		msg =       "You have already installed the following instance" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance:  " & vbTab & InstanceText & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersion & VbCrLf & VbCrLf & VbCrLf
		msg = msg & "=======================================" & vbTab & VbCrLf
		msg = msg & "There is nothing to do." & VbCrLf
		msg = msg & "=======================================" & vbTab
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Finish")
		call QuitInstallation(0)
		
	'----- beta version of SQL Server installed
	elseif (iVersion > 0) and (iVersion < iVersionRTM) then
		msg =       "You have installed a beta version of SQL Server" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance:  " & vbTab & InstanceText & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersion & VbCrLf & VbCrLf & VbCrLf
		msg = msg & "=======================================" & vbTab & VbCrLf
		msg = msg & "This script does not update beta software." & VbCrLf
		msg = msg & "=======================================" & vbTab
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Finish")
		call QuitInstallation(1)
		
	'----- upgrade SQL Server (SP + HF)
	elseif SqlDoesExist then
		msg =       "You have chosen to upgrade the existing instance" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance:  " & vbTab & InstanceText & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersion & VbCrLf & VbCrLf
		msg = msg & "to" & VbCrLf & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersionTarget & VbCrLf & VbCrLf & VbCrLf
		
	'----- install SQL Server (RTM + SP + HF)	
	else
		msg =       "You have chosen to install the new instance" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance:  " & vbTab & InstanceText & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersionTarget & VbCrLf
		msg = msg & "SQL Edition:   " & vbTab & SQLEditionInst & VbCrLf
		msg = msg & "SQL Collation: " & vbTab & SqlCollation & VbCrLf
		msg = msg & "Authentication:" & vbTab & PolicyAuth & VbCrLf
		msg = msg & "Login sa:      " & vbTab & "random password, login disabled" & VbCrLf & VbCrLf
	end if
	
	'----- message box
	msg = msg & "=====================================" & VbCrLf
	msg = msg & "The installation might take 15 minutes or longer" & VbCrLf		
	if not SilentRtmSetup then
		msg = msg & "In the event of an error you might have to press the " & chr(34) & "Next>>" & chr(34) & " button  " & VbCrLf
	end if
	msg = msg & "=====================================" & VbCrLf & VbCrLf & VbCrLf		
	msg = msg & "Do you want to start the installation now?"
	'----- COMPLETELY SILENT INSTALL WITHOUT ANY INFORMATION, BY JOKER
	'----- rc = DoMessageBox(msg, vbOKCancel + vbQuestion, "Confirmation")
	rc = vbOK
	if rc <> vbOK then call QuitInstallation(2)
end if



'========================================================
'=  Install Client Tools
'========================================================

if ClientToolsOnly then
	call InstallSQL
	ToolsInstalled = true
	SnacInstalled  = true

	'----- check version after installation
	GetInstanceVersion("Client Tools")
	iVersion = VersionBuild
	sVersion = VersionStr

    dim iSnacVersion
    dim sSnacVersion
    GetInstanceVersion("Native Client")
    iSnacVersion = VersionBuild
    sSnacVersion = VersionStr

	'-- we assume that the Client Tools do not neccessary be on the CU version but on SP version
	if (iVersion <> iVersionTarget) and (iSnacVersion <> iVersionTarget) and (iVersion <> iVersionSP) and (iSnacVersion <> iVersionSP) then
		msg =       "Installation finished successfully..." & VbCrLf & VbCrLf
		msg = msg & "but verification showed unexpected version:" & VbCrLf & VbCrLf
		msg = msg & "SQL Server Client Tools version " & sVersion
		rc = DoMessageBox(msg, vbOKOnly + vbExclamation, "Wrong SQL Server Client version")

	'----- version check passed		
	else
		msg =       "The SQL Server Client Tools installation finished successfully." & VbCrLf & VbCrLf
		msg = msg & "The verification after the installation showed:" & VbCrLf & VbCrLf
		msg = msg & "SQL Server Client Tools version " & sVersion & VbCrLf & VbCrLf
        msg = msg & "SQL Server Native Client version " & sSnacVersion
		rc = DoMessageBox(msg, vbOKOnly + vbInformation, "Installation finished successfully")	
	end if
end if



'========================================================
'=  Install/upgrade Instance
'========================================================

if not ClientToolsOnly then
	call InstallSQL
	
	'----- check version after installation
	call CalcVersions(ExecuteSQL("select serverproperty('ProductVersion')"))
	iVersion = VersionBuild
	sVersion = VersionStr
	if (iVersion <> iVersionTarget) then
		msg =       "Installation finished successfully..." & VbCrLf & VbCrLf
		msg = msg & "but verification showed unexpected version:" & VbCrLf & VbCrLf
		msg = msg & "SQL Instance:  " & vbTab & InstanceText  & VbCrLf
		msg = msg & "SQL Version:   " & vbTab & sVersion   & VbCrLf
		rc = DoMessageBox(msg, vbOKOnly + vbExclamation, "Wrong SQL Server version")
	else	
		'----- check collation after installation
		myCollation = Trim(ExecuteSQL("select left(cast(serverproperty('collation') as sysname), 50)"))
		if (myCollation <> sCollationBIN2) then
			msg =       "Installation finished successfully..." & VbCrLf & VbCrLf
			msg = msg & "but verification showed unexpected collation:" & VbCrLf & VbCrLf
			msg = msg & "SQL Instance:  " & vbTab & InstanceText  & VbCrLf
			msg = msg & "SQL Version:   " & vbTab & sVersion   & VbCrLf
			msg = msg & "SQL Collation: " & vbTab & myCollation & VbCrLf & VbCrLf
			rc = DoMessageBox(msg, vbOKOnly + vbExclamation, "Wrong collation")
			
		'----- version and collation check passed		
		else
			msg =       "Installation finished successfully." & VbCrLf & VbCrLf
			msg = msg & "The verification after the installation showed:" & VbCrLf & VbCrLf
			msg = msg & "SQL Instance:  " & vbTab & InstanceText  & VbCrLf
			msg = msg & "SQL Version:   " & vbTab & sVersion   & VbCrLf
			msg = msg & "SQL Collation: " & vbTab & myCollation & VbCrLf & VbCrLf
			'----- COMPLETELY SILENT INSTALL WITHOUT ANY INFORMATION, BY JOKER
			'----- rc = DoMessageBox(msg, vbOKOnly + vbInformation, "Installation finished successfully")
			rc = vbOK
		end if	
	end if
end if



'========================================================
'=  End Script
'========================================================

'----- reboot required -----
if RebootRequired then
	msg =       "The SQL Server installation requires a reboot." & VbCrLf
	msg = msg & "Reboot Windows manually."
	rc = DoMessageBox(msg, vbOKOnly + vbInformation, "Reboot required")
	call QuitInstallation(3010)
end if
call QuitInstallation(0)






'========================================================
'=  functions and subs
'========================================================

function CheckFreeSpace(path, SpaceRecommended, SpaceNeeded)
	dim Drive, DriveLetter, SpaceFree, msgType

	Set Drive   = fso.GetDrive(fso.GetDriveName(path))
	DriveLetter = Drive.DriveLetter
	SpaceFree   = CLng(Drive.AvailableSpace/1024/1024)

	if (SpaceFree > SpaceRecommended) and (SpaceFree > SpaceNeeded) then
		rc = vbIgnore
	else
		if SpaceFree > SpaceNeeded then
			msgType = vbAbortRetryIgnore + vbExclamation
		else
			msgType = vbRetryCancel + vbCritical
		end if
		msg =       "Not enough free space on drive " & DriveLetter & ":" & VbCrLf & VbCrLf
		msg = msg & "  recommended space: " & vbTab & SpaceRecommended & " MB     " & VbCrLf
		if SpaceNeeded <> 0 then
			msg = msg & "  (required free space):" & vbTab & "(" & SpaceNeeded      & " MB)" & VbCrLf
		end if
		msg = msg & "  current free space:" & vbTab & SpaceFree        & " MB     "
		rc = DoMessageBox(msg, msgType, "Low disk space")
		if rc = vbAbort or rc = vbCancel then call QuitInstallation(2)
		if rc = vbIgnore then IgnoreFreeSpace = True
	end if
	CheckFreeSpace = rc
end function

'___________________________________________________________________________________________
'
function CheckManagementStudioExpress()
	rc = vbIgnore
	if ExpressInstalled then
		msg =       chr(34) & "SQL Server Management Studio Express" & chr(34) & " is installed" & VbCrLf & VbCrLf
		msg = msg & "We recommended that you uninstall it manually" & VbCrLf
		msg = msg & "before installing SQL Server, which" & VbCrLf
		msg = msg & "includes " & chr(34) & "SQL Server Management Studio" & chr(34)
		rc = DoMessageBox(msg, vbAbortRetryIgnore + vbExclamation, chr(34) & "Management Studio Express" & chr(34) & " found")
		if rc = vbAbort or rc = vbCancel then call QuitInstallation(2)
	end if
	CheckManagementStudioExpress = rc
end function



'========================================================
'=  InstallSQL (SQL Server or Client Tools)
'========================================================

sub InstallSQL

	if (iVersion < iVersionRTM) and (iVersion < iVersionTarget) then
		
		'========================================================
		' check free space (only for RTM installation)
		'========================================================
		do
		loop while CheckManagementStudioExpress() = vbRetry
		
		if OSSystemType = "X86" then
			do
			loop while CheckFreeSpace(prgDir, SpaceNeeded32bitRTM, 0) = vbRetry
		else
			do
			loop while CheckFreeSpace(prgDir, SpaceNeeded64bitRTM, 0) = vbRetry
		end if



		'========================================================
		' DotNet Framework Warning on Windows 2008 R2
		'========================================================

'		if OSFamily = "Windows2008R2" then
'			msg =       "On Windows Server 2008 R2 you have to install the" & VbCrLf
'			msg = msg & ".Net Framework manually before installing SQL Server:" & VbCrLf
'			msg = msg & "For this add the Application Server role in Server Manager." & VbCrLf & VbCrLf
'			msg = msg & "Press OK if .Net Framework is already installed."
'			rc = DoMessageBox(msg, vbOKCancel + vbExclamation, "Add Application Server role")
'			if rc = vbCancel then call QuitInstallation(2)
'		end if
		
		
		
		'========================================================
		' install DotNet Framework (only for RTM installation)
		'========================================================		
		if DotNetNeeded and ((OSFamily = "Windows2012") or (OSFamily = "Windows8")) then
			msg = ".NET 3.5 is not installed on this machine." & VbCrLf _
				& "Please enable .NET 3.5 manually as described on http://technet.microsoft.com/en-us/library/hh831809.aspx."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, ".NET 3.5 not installed/enabled")
			call QuitInstallation(50071)
		elseif DotNetNeeded and (not SilentInstall) and (not IsContInstall) then

			msg = "The SQL Server installation might fail" & VbCrLf _
				& "if not all required .Net Frameworks are up-to-date." & VbCrLf & VbCrLf _
				& "We recommend that you update the .Net Frameworks now." & VbCrLf _
				& "- press YES to install or update the .Net Frameworks" & VbCrLf _
				& "- press NO if the required .Net Frameworks are up-to-date" 
			rc = DoMessageBox(msg, vbYesNo + vbExclamation, "Update .Net Frameworks")
			
			if rc = vbYes then
                
				Wscript.Echo " "
				Wscript.Echo "====================================================="
				Wscript.Echo ".Net framework update might take 15 minutes or longer"
				Wscript.Echo "====================================================="
				if OSFamily = "Windows2008R2" then
                    cmd = "servermanagercmd -install NET-Framework-Core"
                    msg = "Adding feature .NET 3.5 SP1"
                else
    				if OSSystemType = "IA64" and OSFamily = "Windows2003" then
    					cmd = chr(34) & DotNet20_IA64_Setup & chr(34) & " /q /norestart"
    					msg = "or updating .Net framework 2.0SP2"
    				else
    					cmd = chr(34) & DotNet351_Setup & chr(34) & " /q /norestart"
    					msg = "or updating .Net frameworks 3.5SP1, 3.0SP2, 2.0SP2"
    				end if
                end if

				InstallType = InstallDotNet
				
				call InstallStep(cmd, msg)
				if rc <> 0 then
					temp = "Reboot required"
				else
					temp = "Reboot recommended"
				end if
				
				msg =       ".Net Framework was installed successfully." & VbCrLf & VbCrLf
				msg = msg & "Restart Windows and then restart SQL4SAP.VBS"
				rc = DoMessageBox(msg, vbOKOnly + vbExclamation, temp)
				ContInstallRTM = True
				call QuitInstallation(5)
                
			else
				IgnoreDotNet = True
			end if		
		end if
	end if
		

	'========================================================
	' echo target
	'========================================================	
	if ClientToolsOnly then
		Wscript.Echo "Install:          " & "SQL Server Client Tools only"
		Wscript.Echo "Target version:   " & sVersionTarget	
	else
		Wscript.Echo "SQL instance:     " & InstanceText
		Wscript.Echo "SQL version:      " & sVersionTarget
			if not SqlDoesExist then
		Wscript.Echo "SQL collation:    " & SqlCollation			
		Wscript.Echo "Authentication:   " & PolicyAuth
		Wscript.Echo "Login sa:         " & "random password, login disabled"		
			end if
	end if
	Wscript.Echo " "
	Wscript.Echo "================================================"
	Wscript.Echo "The installation might take 15 minutes or longer"
	Wscript.Echo "================================================"		



	'========================================================
	' install SQL Server RTM
	'========================================================				
	if (iVersion < iVersionRTM) and (iVersion < iVersionTarget) then
		cmd = chr(34) & myDir & PathInst & chr(34)
		
		dim sVersionSlipstreamed
		if isSlipstreamedCU then
			iVersion = iVersionHF
			sVersionSlipstreamed = sVersionHF
		elseif isSlipstreamedSP then
			iVersion = iVersionSP
			sVersionSlipstreamed = sVersionSP
		else
			iVersion = iVersionRTM
			sVersionSlipstreamed = sVersionRTM
		end if
'----- ADD
'----- Add installation command
'----- SQL SERVER 2008 R2 --
		if Product = ProductLabel2008R2 then
			
			'----- silent mode
			cmd = cmd & " /Q"
			cmd = cmd & " /ACTION=Install"
            cmd = cmd & " /IACCEPTSQLSERVERLICENSETERMS"
			
			'----- slipstreamed, CURRENTLY ONLY FOR ENTERPRISE EDITION
			if isSlipstreamedCU then
				cmd = cmd & " /PCUSource=" & chr(34) & myDir & FolderEE & "\PCU" & chr(34)
				cmd = cmd & " /CUSource="  & chr(34) & myDir & FolderEE & "\CU"  & chr(34) 
			elseif isSlipstreamedSP then
				cmd = cmd & " /PCUSource=" & chr(34) & myDir & FolderEE & "\PCU" & chr(34)
			end if
			
			'----- license key
            if (SqlDataInstall) then
                cmd = cmd & " /PID=TDJ8M-B6HKB-M984M-QX4PB-Q49MB "
			elseif KeyInstall <> "" then 
                cmd = cmd & " /PID=" & KeyInstall
            end if

			if ClientToolsOnly then
				'----- client tools
				cmd = cmd & " /Features=Tools"
			else
				'----- core engine + Full Text Search
				cmd = cmd & " /Features=SQLEngine,Fulltext"
				
				'----- and SSIS, SSRS
				if FullInstall then
                '--- DON'T FORGET TO UNCOMMENT THE FULL INSTALL CASE A FEW LINES DOWN
					'cmd = cmd & ",IS,RS"
				end if
				
				'----- and client tools
				if not ToolsInstalled then
                    cmd = cmd & ",Tools"
				end if
				
				'----- instance names
				if myInstance <> "MSSQLSERVER" then
					cmd = cmd & " /INSTANCENAME=" & myInstance
					cmd = cmd & " /BROWSERSVCSTARTUPTYPE=Automatic"	   'or /BROWSERSVCStartupType=2  or SQLBrowserStartupType ???
				else
					cmd = cmd & " /INSTANCENAME=MSSQLServer"
				end if
				
				'----- collation
				cmd = cmd & " /SQLCOLLATION=" & SqlCollation
				
				'----- service accounts
				cmd = cmd & " /AGTSVCSTARTUPTYPE=Automatic"
				cmd = cmd & " /SQLSVCACCOUNT="      & chr(34) & OSSystemAccount   & chr(34)
				cmd = cmd & " /AGTSVCACCOUNT="      & chr(34) & OSSystemAccount   & chr(34)
				if FullInstall then
                    '--- DON'T FORGET TO UNCOMMENT THE FULL INSTALL CASE A FEW LINES UP
					'cmd = cmd & " RSSVCACCOUNT="    & chr(34) & OSSystemAccount   & chr(34)
					'cmd = cmd & " ASSVCACCOUNT="    & chr(34) & OSSystemAccount   & chr(34)					
				end if
				
				'----- enable TCP/IP and Named Pipes
				cmd = cmd & " /TCPENABLED=1"
				cmd = cmd & " /NPENABLED=1"
				
				'----- security mode
				if SqlAuthInstall then
					cmd = cmd & " /SECURITYMODE=SQL"
				end if
				
				'----- add Windows "Administrators" group to SQL sysadmin server role
				cmd = cmd & " /SQLSYSADMINACCOUNTS=" & chr(34) & "BUILTIN\Administrators" & chr(34)
				
				'----- sa password (has to be last parameter for this script)
				cmd = cmd & " /SAPWD=" & myPassword
			end if

'----- SQL SERVER 2008 -----
		elseif Product = ProductLabel2008 then
			
			'----- silent mode
			cmd = cmd & " /q"
			cmd = cmd & " /Action=Install"
			
			'----- slipstreamed, CURRENTLY ONLY FOR ENTERPRISE EDITION
			if isSlipstreamedCU then
				cmd = cmd & " /PCUSource=" & chr(34) & myDir & FolderEE & "\PCU" & chr(34)
				cmd = cmd & " /CUSource="  & chr(34) & myDir & FolderEE & "\CU"  & chr(34) 
			elseif isSlipstreamedSP then
				cmd = cmd & " /PCUSource=" & chr(34) & myDir & FolderEE & "\PCU" & chr(34)
			end if
			
			'----- license key
			if KeyInstall <> "" then cmd = cmd & " /PID=" & KeyInstall
			
			if ClientToolsOnly then
				'----- client tools
				cmd = cmd & " /Features=Tools"
			else
				'----- core engine + Full Text Search
				cmd = cmd & " /Features=SQLEngine,Fulltext"
				
				'----- and SSIS, SSRS
				if FullInstall then
					'cmd = cmd & ",IS,RS"
				end if
				
				'----- and client tools
				if not ToolsInstalled then
					cmd = cmd & ",Tools"
				end if
				
				'----- instance names
				if myInstance <> "MSSQLSERVER" then
					cmd = cmd & " /InstanceName=" & myInstance
					cmd = cmd & " /BROWSERSVCSTARTUPTYPE=Automatic"	   'or /BROWSERSVCStartupType=2  or SQLBrowserStartupType ???
				else
					cmd = cmd & " /InstanceName=MSSQLServer"
				end if
				
				'----- collation
				cmd = cmd & " /SQLCOLLATION=" & SqlCollation
				
				'----- service accounts
				cmd = cmd & " /AGTSVCSTARTUPTYPE=Automatic"
				cmd = cmd & " /SQLSVCACCOUNT="      & chr(34) & OSSystemAccount   & chr(34)
				cmd = cmd & " /AGTSVCACCOUNT="      & chr(34) & OSSystemAccount   & chr(34)
				if FullInstall then
					cmd = cmd & " RSSVCACCOUNT="    & chr(34) & OSSystemAccount   & chr(34)
					cmd = cmd & " ASSVCACCOUNT="    & chr(34) & OSSystemAccount   & chr(34)					
				end if
				
				'----- enable TCP/IP and Named Pipes
				cmd = cmd & " /TCPENABLED=1"
				cmd = cmd & " /NPENABLED=1"
				
				'----- security mode
				if SqlAuthInstall then
					cmd = cmd & " /SECURITYMODE=SQL"
				end if
				
				'----- add Windows "Administrators" group to SQL sysadmin server role
				cmd = cmd & " /SQLSYSADMINACCOUNTS=" & chr(34) & "BUILTIN\Administrators" & chr(34)
				
				'----- sa password (has to be last parameter for this script)
				cmd = cmd & " /SAPWD=" & myPassword
			end if

'----- SQL SERVER 2005 -----
		elseif Product = "2005" then
			
			'----- silent mode
			if SilentInstall or SilentRtmSetup then
				cmd = cmd & " /qn"
			else
				cmd = cmd & " /qb"
			end if
			
			'----- software registered for user
			cmd = cmd & " USERNAME=" & chr(34) & "SAP ISV Royalty Licensing Program" & chr(34)
			
			'----- license key (not needed for SAP)
			if KeyInstall <> "" then cmd = cmd & " PIDKEY=" & KeyInstall
	
			if ClientToolsOnly then
				'----- client tools
				cmd = cmd & " ADDLOCAL=Connectivity,SQL_Tools90,SQLXML,Tools_Legacy,SQL_Documentation,SQL_BooksOnline"
			else
				'----- core engine
				cmd = cmd & " ADDLOCAL=SQL_Data_Files,SQL_FullText"
				
				'----- and Replication, SSIS, SSRS, SSNS, SSAS
				if FullInstall then
					cmd = cmd & ",SQL_Replication,SQL_DTS,RS_Server,Notification_Services,Analysis_Server"
				end if
				
				'----- and client tools
				if not ToolsInstalled then
					cmd = cmd & ",Connectivity,SQL_Tools90,SQLXML,Tools_Legacy,SQL_Documentation,SQL_BooksOnline"
				end if

				'----- license mode
				cmd = cmd & " PERSEAT=50"
				
				'----- instance names
				if myInstance <> "MSSQLSERVER" then
					cmd = cmd & " INSTANCENAME=" & myInstance
					cmd = cmd & " SQLBROWSERAUTOSTART=1"
				else
					cmd = cmd & " INSTANCENAME=MSSQLSERVER"
				end if
				
				'----- collation
				cmd = cmd & " SQLCOLLATION=" & SqlCollation
				
				'----- service accounts
				cmd = cmd & " AGTAUTOSTART=1"
				cmd = cmd & " SQLACCOUNT="        & chr(34) & OSSystemAccount & chr(34)
				cmd = cmd & " AGTACCOUNT="        & chr(34) & OSSystemAccount & chr(34)
				cmd = cmd & " SQLBROWSERACCOUNT=" & chr(34) & OSSystemAccount & chr(34)
				if FullInstall then
					cmd = cmd & " RSACCOUNT="     & chr(34) & OSSystemAccount & chr(34)
					cmd = cmd & " ASACCOUNT="     & chr(34) & OSSystemAccount & chr(34)					
				end if
				
				'----- enable TCP/IP and Named Pipes
				cmd = cmd & " DISABLENETWORKPROTOCOLS=0"
				
				'----- security mode
				if SqlAuthInstall then
					cmd = cmd & " SECURITYMODE=SQL"
				end if
				
				'----- sa password (has to be last parameter for this script)
				cmd = cmd & " SAPWD=" & myPassword
			end if
		end if
		
'----- SQL SERVER -----
		InstallType = InstallRTM
		msg = "SQL Server " & SQLEditionInst & " on " & OSSystemType & " - build " & sVersionSlipstreamed
		call InstallStep(cmd, msg)
		

		'----- configure new installed SQL Server instance -----
		'-- SQL RELEASE DEPENDENT --
		if not ClientToolsOnly then 
			sql =       "exec sp_configure 'show advanced options', 1 "
			sql = sql & "reconfigure with override "
			rc = ExecuteSQL(sql)
			sql =       "exec sp_configure 'max degree of parallelism', 1 "
			sql = sql & "exec sp_configure 'xp_cmdshell', 1 "
			sql = sql & "exec sp_configure 'SMO and DMO XPs', 1 "
			'sql = sql & "exec sp_configure 'Agent XPs', 1 "
			sql = sql & "reconfigure with override "
			sql = sql & "ALTER LOGIN [sa] DISABLE "
			rc = ExecuteSQL(sql)		
		end if
		'-- SQL RELEASE DEPENDENT END --
		
	end if

	'-- instance installed successfully, therefore .Net framework is up-to-date
	IgnoreDotNet = False
	
	
	'========================================================
	' install SQL Server Service Pack
	'========================================================
	if (iVersion < iVersionSP) and (iVersion < iVersionTarget) then
		
		'-- SQL RELEASE DEPENDENT --
		if OSSystemType = "X86" then
			do
			loop while CheckFreeSpace(prgDir, SpaceNeeded32bitSP, 0) = vbRetry
		else
			do
			loop while CheckFreeSpace(prgDir, SpaceNeeded64bitSP, 0) = vbRetry
		end if		
		'-- SQL RELEASE DEPENDENT END --
		
		cmd = chr(34) & myDirUNC & PathSP & chr(34)
		
'----- ADD
'----- Add update commmand
'----- SQL SERVER 2008R2 -----
        if Product = ProductLabel2008R2 then
        '----- TODO test if INSTANCEID is not needed for an upgrade from SQL 2008
			if ClientToolsOnly then
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS "
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=MSSQLSERVER"
			else
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME=" & myInstance
			end if
'----- SQL SERVER 2008 -----
		elseif Product = ProductLabel2008 then
			if ClientToolsOnly then
					cmd = cmd & " /quiet"
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /quiet /instancename=MSSQLSERVER"
			else
					cmd = cmd & " /quiet /instancename=" & myInstance
			end if
'----- SQL SERVER 2005 -----
		elseif Product = ProductLabel2005 then
			if ClientToolsOnly then
					cmd = cmd & " /norestart /quiet"
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /norestart /quiet /instancename=MSSQLSERVER"
			else
					cmd = cmd & " /norestart /quiet /instancename=" & myInstance
			end if
		end if
'----- SQL SERVER -----
		
		InstallType = InstallSP
		msg = "SQL Server Service Pack - build " & sVersionSP
		call InstallStep(cmd, msg)
		iVersion = iVersionSP
	end if

	'========================================================
	' install SQL Server Hotfix
	'========================================================
	if (iVersion < iVersionHF) and (iVersion < iVersionTarget) then
		
		cmd = chr(34) & myDirUNC & PathHF & chr(34)
		
'----- ADD
'----- Add update commmand
'----- SQL SERVER 2008R2 -----
        if Product = ProductLabel2008R2 then        
			if ClientToolsOnly then
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS /HIDECONSOLE"
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS /HIDECONSOLE /INSTANCENAME=MSSQLSERVER"
			else
					cmd = cmd & " /Q /IACCEPTSQLSERVERLICENSETERMS /HIDECONSOLE /INSTANCENAME=" & myInstance
			end if
            msg = "SQL Server Cumulative Update - build " & sVersionHF
'----- SQL SERVER 2008 -----
		elseif Product = ProductLabel2008 then
			if ClientToolsOnly then
					cmd = cmd & " /quiet"
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /quiet /instancename=MSSQLSERVER"
			else
					cmd = cmd & " /quiet /instancename=" & myInstance
			end if  
			msg = "SQL Server Cumulative Update - build " & sVersionHF
'----- SQL SERVER 2005 -----
		elseif Product = ProductLabel2005 then
			if ClientToolsOnly then
					cmd = cmd & " /quiet"
			elseif myInstance = "MSSQLSERVER" then
					cmd = cmd & " /quiet /instancename=MSSQLSERVER"
			else
					cmd = cmd & " /quiet /instancename=" & myInstance
			end if  
			msg = "SQL Server Hotfix - build " & sVersionHF
		end if
'----- SQL SERVER -----

		InstallType = InstallHF
		call InstallStep(cmd, msg)
		iVersion = iVersionHF
	end if

	'========================================================
	' start SQLBrowser
	'========================================================
	' workaround for SQL 2005 bug:
	' installing Named Instance AFTER Default Instance results in disbaled SQL Browser
	if myInstance <> "MSSQLSERVER" then
		' wmic.exe service SQLBrowser call ChangeStartMode Automatic
		rc = WinService("SQLBrowser", NetAutoStart)
		
		' wmic.exe service SQLBrowser call StartService
		rc = WinService("SQLBrowser", NetStart)
	end if
	
end sub



'========================================================
'=  InstallStep (RTM, SP or Hotxix)
'========================================================

sub InstallStep(CmdString, CmdMessage)
	dim ReturnCode, PosStart
	
	'----- echo installation step
	PosStart = InStr(1, CmdString, "SAPWD=", 1)
	Wscript.Echo     VbCrLf & "Installing " & CmdMessage & " ..."
	fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf & Now
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Installing " & CmdMessage & " ..."
	if PosStart > 0 then
		fsoLog.WriteLine "  Command:     " & left(CmdString, PosStart+5) & "xxxxxxxxxxxxxxxx"
	else
		fsoLog.WriteLine "  Command:     " & CmdString
	end if
	
	'----- execute command
	ReturnCode = WshShell.Run(CmdString, 0, True)
	fsoLog.WriteLine "  Return Code: " & ReturnCode
	call GetLogFileName
	
	'----- ignore "reboot required"
	if ReturnCode = 3010 then
		RebootRequired = True
		if InstallType = InstallRTM then RebootIgnored = True
		fsoLog.WriteLine VbCrLf & "Ignore return code 3010"	
		
	'----- error "pending file operations"
	elseif ReturnCode = 50071 then
		fsoLog.WriteLine VbCrLf & "return code 50071"
		msg =       "A previous program installation created pending file operations." & VbCrLf & VbCrLf
		msg = msg & "Restart Windows and try again."
		rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
		call QuitInstallation(50071)
		
	'----- other error
	elseif ReturnCode <> 0 then		
		msg =       "The unattended installation failed." & VbCrLf & VbCrLf
		msg = msg & "  Installation Step: " & CmdMessage & VbCrLf
		msg = msg & "  Return Code:       " & ReturnCode & VbCrLf
		msg = msg & "  Log File:          " & LogFile & VbCrLf

		'----- workaround for bug in SQL 2005
		if AlterSaFailed then
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "Retry to install with " & chr(34) & "SQL Server and Windows" & chr(34) & " authentication" & VbCrLf
			msg = msg & "by starting the script " & chr(34) & "_SqlAuth.vbs" & chr(34)
			msg = msg & VbCrLf & VbCrLf & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(42)
		
		'----- not enough free space (and RTM installation failed)
		elseif IgnoreFreeSpace then
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "You ignored the warning regarding low disk space." & VbCrLf
			msg = msg & "Retry the installation with sufficient free disk space."
			msg = msg & VbCrLf & VbCrLf & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(1)
		
		'----- .Net framework was not updated (and RTM installation failed)
		elseif IgnoreDotNet then
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "You did not update the .Net Frameworks." & VbCrLf
			msg = msg & "Retry the installation including .Net Frameworks update."
			msg = msg & VbCrLf & VbCrLf & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(1)		
		
		'----- RTM installation failed
		elseif (iVersion < iVersionRTM) and (iVersion < iVersionTarget) then
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "Check the log file above." & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(1)
			
		'----- SP installation failed
		elseif (iVersion < iVersionSP) and (iVersion < iVersionTarget) then
			msg = msg & "  Current version:   " & CStr(iVersion) & VbCrLf
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "Reboot Windows and try to install the Service Pack again." & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(3)
			
		'----- Hotfix installation failed
		elseif (iVersion < iVersionHF) and (iVersion < iVersionTarget) then

'----- ADD
'----- Add error messages
'----- SQL SERVER 2008 -----
			if Product <> ProductLabel2005 then
				if RebootIgnored = True then
					msg =       "SQL Server was installed successfully." & VbCrLf
					msg = msg & "The subsequent Cumulative Update failed." & VbCrLf & VbCrLf
					msg = msg & "Restart Windows and then restart SQL4SAP.VBS"
					rc = DoMessageBox(msg, vbOKOnly + vbExclamation, "Reboot required")
					ContInstallCU = True
					call QuitInstallation(6)
				else
					msg = msg & "  Current version:   " & CStr(iVersion) & VbCrLf
					msg = msg & VbCrLf & VbCrLf
					msg = msg & "Reboot Windows and try to install" & VbCrLf
					msg = msg & "the Cumulative Update again." & VbCrLf
					msg = msg & "See SAP note " & SapNote & " for known issues."
					rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
					call QuitInstallation(4)
				end if
'----- SQL SERVER 2005 -----
			else
				msg = msg & "  Current version:   " & CStr(iVersion) & VbCrLf
				msg = msg & VbCrLf & VbCrLf
				msg = msg & "Reboot Windows and try to install the Hotfix again." & VbCrLf
				msg = msg & "See SAP note " & SapNote & " for known issues."
				rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
				call QuitInstallation(4)
			end if
'----- SQL SERVER -----
	
		'----- ELSE (should never happen)
		else
			msg = msg & VbCrLf & VbCrLf
			msg = msg & "Check the log file above." & VbCrLf
			msg = msg & "See SAP note " & SapNote & " for known issues."
			rc = DoMessageBox(msg, vbOKOnly + vbCritical, "Installation failed")
			call QuitInstallation(1)		
		end if
		
	end if
	rc = ReturnCode
end sub



'========================================================
'=  calculate paths of log files
'========================================================

sub GetLogFileName()
	dim fsoMainFolder, fsoSubFolders, fsoLogFolder, fsoSubFiles, fsoLogFile
	dim AFolderName, MyFolderName, AFolderDate, MyFolderDate, AFileName

'----- ADD
'----- Add path to log file
'----- SQL SERVER 2008 -----
	if (Product = ProductLabel2008) or (Product = ProductLabel2008R2) then
		'----- log file for SQL installation
		if InstallType <> InstallDotNet then
			
			InstallLogFile = prgDir  & "Microsoft SQL Server\100\Setup Bootstrap\LOG\Summary.txt"
			fsoLog.WriteLine "  Log File:    " & InstallLogFile
			fsoLog.WriteLine "----------------------------------------"
			
			'----- find newest folder with name "JJJJMMDD_HHMMSS"
			MyFolderName = ""
			MyFolderDate = CDate(0)
			on error resume next
				set fsoMainFolder = fso.GetFolder(prgDir & "Microsoft SQL Server\100\Setup Bootstrap\LOG")
				set fsoSubFolders = fsoMainFolder.SubFolders
				for each fsoLogFolder in fsoSubFolders
					AFolderName = fsoLogFolder.Name
					AFolderDate = fsoLogFolder.DateCreated
					if AFolderDate > MyFolderDate then
						if len(AFolderName) = 15 then
							if isNumeric(left(AFolderName,8)) and isNumeric(right(AFolderName,6)) then
								MyFolderName = AFolderName
								MyFolderDate = AFolderDate
							end if
						end if
					end if
				next
			if Not OnErrorResume then on error goto 0
			
			'----- find all log files, whic start with "Summary_"
			on error resume next
				if MyFolderName <> "" then
					set fsoLogFolder = fso.GetFolder(prgDir & "Microsoft SQL Server\100\Setup Bootstrap\LOG\" & MyFolderName)
					set fsoSubFiles = fsoLogFolder.Files
					for each fsoLogFile in fsoSubFiles
						AFileName = fsoLogFile.Name
						if len(AFileName) > 8 then
							if left(AFileName,8) = "Summary_" then
								temp = prgDir & "Microsoft SQL Server\100\Setup Bootstrap\LOG\" _
												& MyFolderName & "\" & AFileName
								call WriteLogFile(temp)	
							end if
						end if
					next
				end if
			if Not OnErrorResume then on error goto 0
			
		'----- log file for .NET framework installation	
		else
			InstallLogFile = ""
			fsoLog.WriteLine "  Log File:    " & InstallLogFile
			fsoLog.WriteLine "----------------------------------------"			
		end if
		
		call WriteLogFile(InstallLogFile)
		
'----- SQL SERVER 2005 -----
	elseif Product = ProductLabel2005 then
		'----- log file for RTM installation
		if InstallType = InstallRTM then
			InstallLogFile = prgDir  & "Microsoft SQL Server\90\Setup Bootstrap\LOG\Summary.txt"
		
		'----- log file for Service Pack installation
		elseif InstallType = InstallSP then
			if iVersionSP > 3000 then
				InstallLogFile  = prgDir  & "Microsoft SQL Server\90\Setup Bootstrap\LOG\Hotfix\Summary.txt"
			else
				InstallLogFile  = rootDir & "Hotfix\HotFix.log"	
			end if	
		
		'----- log file for Hotfix installation		
		elseif InstallType = InstallHF then
			InstallLogFile  = prgDir  & "Microsoft SQL Server\90\Setup Bootstrap\LOG\Hotfix\Summary.txt"

		'----- log file for .NET framework installation	
		else
			InstallLogFile = ""
					
		end if
		
		'----- write log file
		fsoLog.WriteLine "  Log File:    " & InstallLogFile
		fsoLog.WriteLine "----------------------------------------"
		call WriteLogFile(InstallLogFile)

	end if
'----- SQL SERVER -----

end sub



'========================================================
'=  functions and subs to check installed instances
'========================================================

function InstanceDoesExist(instname)
	found = False
	if not IsEmpty(sInstancesHKLM) then
		for i = 0 to ubound(sInstancesHKLM)
			if sInstancesHKLM(i) = instname then found = True
		next
	end if
	if not IsEmpty(sInstancesWow6432) then
		for i = 0 to ubound(sInstancesWow6432)
			if sInstancesWow6432(i) = instname then found = True
		next
	end if

	InstanceDoesExist = found
end function


'___________________________________________________________________________________________
'
sub DimInstanceList
	dim count32, count64
	FoundSQL7 = False
	
	'----- ADD
	'----- Add regpath for installed instances for new releases
	' Find SQL Server 2000 and 2008 instances
	on error resume next
	sInstancesHKLM    = WshShell.RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\InstalledInstances")
	sInstancesWow6432 = WshShell.RegRead("HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\InstalledInstances")
	if Not OnErrorResume then on error goto 0
		
	' Find SQL Server 7 default instance
	if not InstanceDoesExist("MSSQLSERVER") then
		if WinService("MSSQLSERVER", NetQuery) then
			if IsEmpty(sInstancesHKLM) then
				redim sInstancesHKLM(0)
			else
				redim preserve sInstancesHKLM(ubound(sInstancesHKLM)+1)
			end if
			FoundSQL7 = True
			sInstancesHKLM(ubound(sInstancesHKLM)) = "MSSQLSERVER"
		end if
	end if
	
	' number of instances
	if IsEmpty(sInstancesHKLM) then
		count64 = 0
	else
		count64 = ubound(sInstancesHKLM) + 1
	end if
	if IsEmpty(sInstancesWow6432) then
		count32 = 0
	else
		count32 = ubound(sInstancesWow6432) + 1
	end if
	sInstancesNameCnt = count64 + count32
	if sInstancesNameCnt > 0 then	
		redim sInstancesName(count64 + count32 - 1)
		redim sInstancesBIT(count64 + count32 - 1)
		redim sInstancesPrefix(count64 + count32 - 1)
		redim sInstancesRegName(count64 + count32 - 1)
		redim sInstancesEXE(count64 + count32 - 1)
		redim sInstancesLOG(count64 + count32 - 1)
	end if

end sub


'___________________________________________________________________________________________
'
sub SortInstanceList
	if sInstancesNameCnt > 0 then
		' Replace MSSQLSERVER by "."
		for i = 0 to ubound(sInstancesName)
			if UCase(sInstancesName(i)) = "MSSQLSERVER" then sInstancesName(i) = "."
		next
		
		'bubble sort sInstances
		for i = ubound(sInstancesName) - 1 To 0 Step -1
			for j = 0 to i
				if sInstancesName(j) > sInstancesName(j+1) then
					temp = sInstancesName(j+1)
					sInstancesName(j+1) = sInstancesName(j)
					sInstancesName(j)=temp
					
					temp = sInstancesBIT(j+1)
					sInstancesBIT(j+1) = sInstancesBIT(j)
					sInstancesBIT(j)=temp
	
					temp = sInstancesPrefix(j+1)
					sInstancesPrefix(j+1) = sInstancesPrefix(j)
					sInstancesPrefix(j)=temp
					
					temp = sInstancesRegName(j+1)
					sInstancesRegName(j+1) = sInstancesRegName(j)
					sInstancesRegName(j)=temp
					
					temp = sInstancesEXE(j+1)
					sInstancesEXE(j+1) = sInstancesEXE(j)
					sInstancesEXE(j)=temp
					
					temp = sInstancesLOG(j+1)
					sInstancesLOG(j+1) = sInstancesLOG(j)
					sInstancesLOG(j)=temp
				end if
			next
		next
		
		' Replace "." by MSSQLSERVER
		for i = 0 to ubound(sInstancesName)
			if sInstancesName(i) = "." then sInstancesName(i) = "MSSQLSERVER"
		next
	end if
	
	'----- echo installed instances to log file
	fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Installed SQL Server Instances:"
	if sInstancesNameCnt > 0 then
		for i = 0 to ubound(sInstancesName)
		fsoLog.WriteLine "  Instance name:    " & sInstancesName(i)
		fsoLog.WriteLine "  Platform:         " & sInstancesBIT(i) & " bit"
		fsoLog.WriteLine "  Registry prefix:  " & sInstancesPrefix(i)
		fsoLog.WriteLine "  Registry name:    " & sInstancesRegName(i)
		fsoLog.WriteLine "  Path executables: " & sInstancesEXE(i)
		fsoLog.WriteLine "  Path errorlog:    " & sInstancesLOG(i)
		fsoLog.WriteLine ""
		next
	end if
	fsoLog.WriteLine "----------------------------------------"
	
end sub


'___________________________________________________________________________________________
'
sub GetInstanceList(instname)
	' fills the following global variables:
	SQLRegBIT = ""
	' e.g. "32", "64"
	SQLRegPrefix = ""
	' e.g. "HKLM\SOFTWARE\Microsoft\MSSQLServer\"
	'      "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\"
	'      "HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\"
	SQLRegName = ""
	' e.g. ""            for SQL 2000 default instance
	'      "PRD"         for SQL 2000 named instance "PRD"
	'      "MSSQL.1"     for SQL 2005 instance (any)
	'      "MSSQL10.PRD" for SQL 2008 named instance "PRD"
	SQLRegEXE = ""
	' e.g. "C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL"
	'      "C:\Program Files (x86)\Microsoft SQL Server\MSSQL$SQL2000"
	'      "C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL"
	SQLRegLOG = ""
	' e.g. "C:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\LOG\ERRORLOG"
	'      "C:\Program Files (x86)\Microsoft SQL Server\MSSQL$SQL2000\LOG\ERRORLOG"
	'      "C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG"
	if sInstancesNameCnt > 0 then
		for i = 0 to ubound(sInstancesName)
			if (sInstancesName(i) = instname) then
				SQLRegBIT    = sInstancesBIT(i)
				SQLRegPrefix = sInstancesPrefix(i)			
				SQLRegName   = sInstancesRegName(i)
				SQLRegEXE    = sInstancesEXE(i)
				SQLRegLOG    = sInstancesLOG(i)
				exit for
			end if
		next
	end if
end sub


'___________________________________________________________________________________________
'
sub SetInstanceList

	'----- 32 bit Windows	
	if OSSystemType = "X86" then
		k = 0
		if not IsEmpty(sInstancesHKLM) then
			for i = 0 to ubound(sInstancesHKLM)
				sInstancesName(k) = sInstancesHKLM(i)
				sInstancesBIT(k) = "32"
				k = k + 1
			next
		end if
	'----- 64 bit Windows
	else
		k = 0
		if not IsEmpty(sInstancesHKLM) then
			for i = 0 to ubound(sInstancesHKLM)
				sInstancesName(k) = sInstancesHKLM(i)
				if FoundSQL7 and sInstancesHKLM(i) = "MSSQLSERVER" then
					sInstancesBIT(k) = "32"
				else
					sInstancesBIT(k) = "64"
				end if				
				k = k + 1
			next
		end if
		
		if not IsEmpty(sInstancesWow6432) then	
			for i = 0 to ubound(sInstancesWow6432)
				sInstancesName(k) = sInstancesWow6432(i)
				sInstancesBIT(k) = "32"
				k = k + 1
			next
		end if
		
	end if
	
	
	'----- get info for each instance
	dim SQLInstanceName
	dim RegKeyName, RegValueName, RegValueData
	if sInstancesNameCnt > 0 then
		for i = 0 to ubound(sInstancesName)
			SQLInstanceName = sInstancesName(i)
			SQLRegBIT       = sInstancesBIT(i)
			
			SQLRegPrefix    = ""			
			SQLRegName      = ""
			SQLRegEXE       = ""
			SQLRegLOG       = ""
			
			'----- ADD
			'----- Change path of registry keys here
			'----- get registry prefix
			if (OSSystemType = "X86") or (SQLRegBIT = "64") then
				SQLRegPrefix = "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\"
			else 
				SQLRegPrefix = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\"
			end if
			
			'----- SQL Server 2005 and 2008:
			SQLRegName = RegRead(SQLRegPrefix + "Instance Names\SQL\" + SQLInstanceName)
			'----- SQL Server 2000
			if SQLRegName = "" then
				if SQLInstanceName = "MSSQLSERVER" then
					if (OSSystemType = "X86") or (SQLRegBIT = "64") then
						SQLRegPrefix = "HKLM\SOFTWARE\Microsoft\MSSQLServer"
					else 
						SQLRegPrefix = "HKLM\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer"
					end if
					SQLRegName = ""
				else
					SQLRegName = SQLInstanceName
				end if				
			end if
			
			'----- get SQL Server path
			SQLRegEXE  = RegRead(SQLRegPrefix + SQLRegName + "\Setup\SQLPath")
			
			'----- get ERRORLOG path
			RegKeyName = SQLRegPrefix + SQLRegName + "\MSSQLServer\Parameters\"
			for k = 0 to 20
				RegValueName = "SQLArg" & CStr(k)
				RegValueData = ""
				RegValueData = RegRead(RegKeyName & RegValueName)
				if LCase(left(RegValueData & "--", 2)) = "-e" then
					SQLRegLOG = right(RegValueData, len(RegValueData) - 2)
					exit for
				end if
			next
			
			sInstancesPrefix(i)  = SQLRegPrefix 			
			sInstancesRegName(i) = SQLRegName   
			sInstancesEXE(i)     = SQLRegEXE    
			sInstancesLOG(i)     = SQLRegLOG    
		next
	end if
end sub

'___________________________________________________________________________________________
'
function GetInstanceVersion(Instance)
'	Instance in (	"Native Client"
'					"Native Client 2005"
'					"Native Client 2008"
'					"Native Client 2008R2"
'					"Client Tools"
'					"Client Tools 2005"
'					"Client Tools 2008"
'					"Client Tools 2008R2"
'					<instance name> )				
	dim ErrorLogFile, ErrorLogLine, ClientVer, ClientCSD
	ClientVer = ""
	ClientCSD = ""

	'----- ADD
	'----- Add registry path for new version
	'----- Version: SQL Server Native Client
	if left(Instance, 13) = "Native Client" then
		
		if (Instance = "Native Client" and Product = ProductLabel2008R2) or Instance = "Native Client 2008R2" then        
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server Native Client 10.0\CurrentVersion\Version")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server Native Client 10.0\CurrentVersion\PatchLevel")

            '------ check if this is really SQL 10.5 stuff
			if (Left(ClientVer, 4) <> "10.5") then
                ClientVer = ""
            end if
            if (Left(ClientCSD, 4) <> "10.5") then
                ClientCSD = ""
            end if

		elseif (Instance = "Native Client" and Product = ProductLabel2008) or Instance = "Native Client 2008" then
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server Native Client 10.0\CurrentVersion\Version")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server Native Client 10.0\CurrentVersion\PatchLevel")
            
            '------ check if this is really SQL 10.0 stuff
			if (Left(ClientVer, 4) = "10.5") then
                ClientVer = ""
            end if
            if (Left(ClientCSD, 4) = "10.5") then
                ClientCSD = ""
            end if
			
		elseif (Instance = "Native Client" and Product = ProductLabel2005) or Instance = "Native Client 2005" then
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Native Client\CurrentVersion\Version")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Native Client\CurrentVersion\PatchLevel")
		end if
		
		if ClientCSD <> "" then
			call CalcVersions(ClientCSD)
		elseif ClientVer <> "" then
			call CalcVersions(ClientVer)
		else
			call CalcVersions("")
		end if

		
	'----- Version: SQL Server Client Tools
	elseif left(Instance, 12) = "Client Tools" then
		
		if (Instance = "Client Tools" and Product = ProductLabel2008R2) or Instance = "Client Tools 2008R2" then        
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup\CurrentVersion\CurrentVersion")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup\CurrentVersion\CSDVersion")

            '------ check if this is really SQL 10.5 stuff
			if (Left(ClientVer, 4) <> "10.5") then
                ClientVer = ""
            end if
            if (Left(ClientCSD, 4) <> "10.5") then
                ClientCSD = ""
            end if
					
		elseif (Instance = "Client Tools" and Product = ProductLabel2008) or Instance = "Client Tools 2008" then
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup\CurrentVersion\CurrentVersion")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\ClientSetup\CurrentVersion\CSDVersion")
			
            '------ check if this is really SQL 10.0 stuff
			if (Left(ClientVer, 4) = "10.5") then
                ClientVer = ""
            end if
            if (Left(ClientCSD, 4) = "10.5") then
                ClientCSD = ""
            end if
            		
		elseif (Instance = "Client Tools" and Product = ProductLabel2005) or Instance = "Client Tools 2005" then
			ClientVer = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\90\Tools\ClientSetup\CurrentVersion\CurrentVersion")
			ClientCSD = RegRead("HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\90\Tools\ClientSetup\CurrentVersion\CSDVersion")
		end if
		
		if ClientCSD <> "" then
			call CalcVersions(ClientCSD)
		elseif ClientVer <> "" then
			call CalcVersions(ClientVer)
		else
			call CalcVersions("")
		end if
	
	'----- Version: SQL Server Instance
	else
		call GetInstanceList(Instance)
		ErrorLogFile = SQLRegLOG
		ErrorLogLine = ""
		on error resume next
			FileOpen4Read(ErrorLogFile)
			ErrorLogLine = FileReadLine()
			FileClose()
		if Not OnErrorResume then on error goto 0
		call CalcVersions(ErrorLogLine)
	end if
	GetInstanceVersion = VersionStr
end function


'___________________________________________________________________________________________
'
sub CalcVersions(VersionLine)
	Dim PosStart, PosEnd, TempVersionStr
	
	'----- set global variables
	VersionStr   = ""
	VersionMajor = 0
	VersionMinor = 0
	VersionBuild = 0
	VersionSub   = 0

	if not isempty(VersionLine) and VersionLine <> "" then
		PosStart = InStr(1, VersionLine, "SQL Server", 1)
		if PosStart > 0 then
			'----- remove time from 1st line of ERRORLOG file (or @@version)
			TempVersionStr = right(VersionLine, len(VersionLine) - PosStart)
		else
			'----- version string from registry
			TempVersionStr = "  " & VersionLine & "  "
		end if
		' TempVersionStr contains numbers, dots and a space before and after string, e.g.
		' TempVersionStr = "  2000 - 8.00.2040 (Intel X86) ...."

		'----- extract VersionStr
		VersionStr = "0.00.0000.00"                               'valid default
		PosStart = InStr(1, TempVersionStr, ".", 1) - 2           'two chars before the first dot
		if PosStart > 0 then
			PosEnd = InStr(PosStart + 2, TempVersionStr, " ", 1) 'next space after first dot
			if PosEnd > PosStart + 2 then
				VersionStr = trim(mid(TempVersionStr, PosStart, PosEnd - PosStart))
			end if
		end if
		TempVersionStr = VersionStr & ".0.0.0.0"                  'expand dot versions
		if VersionStr = "0.00.0000.00" then VersionStr = ""       'default result
		
		on error resume next
			PosStart = InStr(1, TempVersionStr, ".", 1)
			VersionMajor = CInt(left(TempVersionStr, PosStart - 1))
			TempVersionStr = right(TempVersionStr, len(TempVersionStr) - PosStart)
			
			PosStart = InStr(1, TempVersionStr, ".", 1)
			VersionMinor = CInt(left(TempVersionStr, PosStart - 1))
			TempVersionStr = right(TempVersionStr, len(TempVersionStr) - PosStart)
			
			PosStart = InStr(1, TempVersionStr, ".", 1)
			VersionBuild = CInt(left(TempVersionStr, PosStart - 1))
			TempVersionStr = right(TempVersionStr, len(TempVersionStr) - PosStart)
			
			PosStart = InStr(1, TempVersionStr, ".", 1)
			VersionSub = CInt(left(TempVersionStr, PosStart - 1))
		if Not OnErrorResume then on error goto 0
	end if
end sub



'========================================================
'=  log file functions
'========================================================

sub WriteLogFile(CmdLogFile)
	if CmdLogFile <> "" then
		msg = ""
		on error resume next
			FileOpen4Read(CmdLogFile)
			msg = FileReadAll()
			FileClose()
		if Not OnErrorResume then on error goto 0
		fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf & Now
		fsoLog.WriteLine "----------------------------------------"
		fsoLog.WriteLine "Log file " & CmdLogFile
		fsoLog.WriteLine "----------------------------------------"
		fsoLog.WriteLine msg
		if InstallType = InstallRTM then
			if InStr(1, msg, "Cannot alter the login 'sa', because it does not exist", 1) <> 0 then
				AlterSaFailed = True
			end if
		end if
	end if
end sub


'___________________________________________________________________________________________
'
sub CopyOldLogFiles(theLogFile)
	dim theFile
	if theLogFile <> "" then 
		if (lcase(right(theLogFile, 4)) = ".log") or (lcase(right(theLogFile, 4)) = ".txt") then
			theFile = left(theLogFile, len(theLogFile)-4)
		else
			theFile = theLogFile
		end if
		on error resume next
		fso.CopyFile theFile & ".8",   theFile & ".9", True
		fso.CopyFile theFile & ".7",   theFile & ".8", True
		fso.CopyFile theFile & ".6",   theFile & ".7", True
		fso.CopyFile theFile & ".5",   theFile & ".6", True
		fso.CopyFile theFile & ".4",   theFile & ".5", True
		fso.CopyFile theFile & ".3",   theFile & ".4", True
		fso.CopyFile theFile & ".2",   theFile & ".3", True
		fso.CopyFile theFile & ".1",   theFile & ".2", True
		fso.CopyFile theFile & "",     theFile & ".1", True
		fso.CopyFile theFile & ".log", theFile & ".1", True
		fso.CopyFile theFile & ".txt", theFile & ".1", True
		if not OnErrorResume then on error goto 0
	end if
end sub



'========================================================
'=  Manage Windows Services (query, start, stop, set startup type)
'========================================================

function WinService(ServiceSring,Operation)
	dim objWMIService, colServices, objService
	rc = 1
	
	on error resume next
		set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
		set colServices = objWMIService.ExecQuery("SELECT * FROM Win32_Service WHERE Name = '" & ServiceSring & "'")
		found = false
		
		For Each objService in colServices
			found = true
			'----- NetStop
			if Operation = NetStop then
				if not ((objService.State = "Stopped") or (objService.State = "Stop Pending")) then
					rc = objService.StopService()
					fsoLog.WriteLine VbCrLf
					fsoLog.WriteLine "stopping service " & ServiceSring & " ..."
					fsoLog.WriteLine "  Return Code: " & rc
				else
					rc = 0
				end if
				for i = 1 to 100
					if objService.State = "Stopped" then exit for
				     WScript.Sleep 100
				next
							
			'----- NetStart
			elseif Operation = NetStart then
				if not ((objService.State = "Running") or (objService.State ="Start Pending")) then
					rc = objService.StartService()
					fsoLog.WriteLine VbCrLf
					fsoLog.WriteLine "starting service " & ServiceSring & " ..."
					fsoLog.WriteLine "  Return Code: " & rc
				else
					rc = 0
				end if
				for i = 1 to 100
					if objService.State = "Running" then exit for
				     WScript.Sleep 100
				next
				
			'----- NetAutoStart
			elseif Operation = NetAutoStart then
				if not (objService.StartMode = "Auto") then
					rc = objService.ChangeStartMode("Automatic")
					fsoLog.WriteLine VbCrLf
					fsoLog.WriteLine "change start mode of " & ServiceSring & " to Automatic"
					fsoLog.WriteLine "  Return Code: " & rc
				else
					rc = 0
				end if			
				
			end if
		next
		
		'----- NetQuery
		if Operation = NetQuery then
			rc = found
		elseif not found then
			fsoLog.WriteLine VbCrLf & "service " & ServiceSring & " does not exist"
		end if
	if Not OnErrorResume then on error goto 0
	WinService = rc
end function



'========================================================
'=  execute SQL command
'========================================================

function ExecuteSQL(SqlCommand)
	dim objConn, objRS, SqlConnectStr, SQLConnectName

	if myInstance <> "MSSQLSERVER" then
		SQLConnectName = ".\" & myInstance
	else
		SQLConnectName = "."
	end if
	SqlConnectStr = "Provider=SQLOLEDB;Integrated Security='SSPI';Initial Catalog=master;Data Source='" & SQLConnectName & "'"

	'----- start service
	rc = WinService(myService, NetStart)

	'----- open ADODB
	fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf & Now
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "CreateObject(" & chr(34) & "ADODB.Connection" & chr(34) & ")"
	ErrorOccured = False
	on error resume next
		Err.Clear
		set objConn=CreateObject("ADODB.Connection")
		if Err.Number <> 0 then ErrorOccured = True	
	if Not OnErrorResume then on error goto 0
	if ErrorOccured then fsoLog.WriteLine "=> ERROR"

	'----- connect to SQL Server
	fsoLog.WriteLine "Open(" & SqlConnectStr & ")"
	ErrorOccured = False
	on error resume next
		Err.Clear
		objConn.Open SqlConnectStr
		if Err.Number <> 0 then ErrorOccured = True
	if Not OnErrorResume then on error goto 0
	if ErrorOccured then fsoLog.WriteLine "=> ERROR"

	'----- execute SQL command which returns 1 row with 1 column
	fsoLog.WriteLine "Execute(" & SqlCommand & ")"
	rc = ""
	on error resume next
		set objRS = objConn.execute(SqlCommand)
		rc = objRS.Fields(0)
		objRS.Close
	if not OnErrorResume then on error goto 0
	fsoLog.WriteLine "=> " & rc

	'----- close connection
	fsoLog.WriteLine "Close"
	ErrorOccured = False
	on error resume next
		Err.Clear
		objConn.Close
		if Err.Number <> 0 then ErrorOccured = True
	if Not OnErrorResume then on error goto 0
	if ErrorOccured then fsoLog.WriteLine "=> ERROR"	

	ExecuteSQL = rc
end function



'========================================================
'=  Get Windows and hardware info using WMI
'========================================================

sub CheckWindowsVersion

	OSSystemType = "X86"
				' "X86"      "Unknown"
				'            "X86-based PC"
				' "Alpha"    "64-bit Alpha PC"
				' "IA64"     "Itanium (TM) -based System"
				'            "64-bit Intel PC"
				' "X64"      "x64-based PC"
	OSSystemBit = "32"
				' "32"
				' "64"

	OSFamily = "Unknown"
				' "Unknown"
				' "Windows95"
				' "Windows98"
				' "WindowsCE"
				' 		"WINNT":
				' "WindowsNT3.1"
				' "WindowsNT3.5"
				' "WindowsNT4.0"
				' "Windows2000"
				' "WindowsXP"
				' "Windows2003"
				' "WindowsVista"
				' "Windows2008"
				' "Windows7"
				' "Windows2008R2"
				' 		"WindowsNT" & OSVersion

	OSEdition = "Unknown"
				' "Unknown"
				' "Server"
				' "Workstation"
				' "Cluster"
				' "Small Business Server"

	OSVersion = "1.0"
				' "1.0"
				' "3.1"
				' "3.5"
				' "4.0"
				' "5.0"
				' "5.1"
				' "5.2"

	OSLanguage = "Unknown"
	OSLanguageID = 0
	OSServicePack = "0"
	OSProductSuite = ""
	OSMsiVersion = ""
	OSMdacVersion = ""


	dim objOS, OSCaption, OSProductType
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "System settings:"

	on error resume next
	
	'----- CPU information
	For Each objOS in GetObject("winmgmts:").InstancesOf ("Win32_Processor")
		fsoLog.WriteLine "  Win32_Processor.Name=" & objOS.Name
		fsoLog.WriteLine "  Win32_Processor.NumberOfCores=" & objOS.NumberOfCores
		fsoLog.WriteLine "  Win32_Processor.NumberOfLogicalProcessors=" & objOS.NumberOfLogicalProcessors
	next
	
	'----- OSSystemType
	For Each objOS in GetObject("winmgmts:").InstancesOf ("Win32_ComputerSystem")
		OSLogicalProcessors = 0
		OSLogicalProcessors = objOS.NumberOfLogicalProcessors
		if OSLogicalProcessors = 0 then OSLogicalProcessors = objOS.NumberOfProcessors
		fsoLog.WriteLine "  Win32_ComputerSystem.SystemType=" & objOS.SystemType
		fsoLog.WriteLine "  Win32_ComputerSystem.NumberOfProcessors=" & objOS.NumberOfProcessors
		temp = ""
		temp = objOS.NumberOfLogicalProcessors
		fsoLog.WriteLine "  Win32_ComputerSystem.NumberOfLogicalProcessors=" & temp
		OSSystemType = objOS.SystemType
		if InStr(1, UCase(OSSystemType), "X86-BASED", 1) <> 0 then OSSystemType = "X86"
		if InStr(1, UCase(OSSystemType), "ALPHA", 1)     <> 0 then OSSystemType = "Alpha"
		if InStr(1, UCase(OSSystemType), "ITANIUM", 1)   <> 0 then OSSystemType = "IA64"
		if OSSystemType = "64-bit Intel PC"                   then OSSystemType = "IA64"
		if InStr(1, UCase(OSSystemType), "X64-BASED", 1) <> 0 then OSSystemType = "X64"
	next
	
	'----- OSSystemBit (Alpha not supportet by this script anyway)
	if OSSystemType <> "X86" then OSSystemBit = "64"
	
	'-----
	For Each objOS in GetObject("winmgmts:").InstancesOf ("Win32_OperatingSystem")
		fsoLog.WriteLine "  Win32_OperatingSystem.OSType=" & CStr(objOS.OSType)
		fsoLog.WriteLine "  Win32_OperatingSystem.Version=" & objOS.Version
		fsoLog.WriteLine "  Win32_OperatingSystem.ServicePackMajorVersion=" & CStr(objOS.ServicePackMajorVersion)
		fsoLog.WriteLine "  Win32_OperatingSystem.Caption=" & objOS.Caption
		fsoLog.WriteLine "  Win32_OperatingSystem.ProductType=" & CStr(objOS.ProductType)
		fsoLog.WriteLine "  Win32_OperatingSystem.OSProductSuite=" & CStr(objOS.OSProductSuite)
		fsoLog.WriteLine "  Win32_OperatingSystem.OSLanguage=" & CStr(objOS.OSLanguage)
		rc = 0

		'----- OSTime, OSBootTime
		OSTime = objOS.LocalDateTime
		OSBootTime = objOS.LastBootUpTime

		'----- OSLanguageID
		OSLanguageID = objOS.OSLanguage
		Select case OSLanguageID
			case 9     OSLanguage = "English"
			case 1033  OSLanguage = "English ?United States"
			case 2057  OSLanguage = "English ?United Kingdom"
			case 1031  OSLanguage = "German ?Germany"
			case 1036  OSLanguage = "French ?France"
			case 1040  OSLanguage = "Italian ?Italy"
			case 1034  OSLanguage = "Spanish ?Traditional Sort"
			case 3082  OSLanguage = "Spanish ?International Sort"
			case 1041  OSLanguage = "Japanese"
			case else  OSLanguage = "Other"
		end Select

		'----- OSEdition
		OSCaption = "?"
		OSCaption = objOS.Caption
		if InStr(1, OSCaption, "Professional", 1) <> 0  then OSEdition = "Workstation"
		if InStr(1, OSCaption, "Server", 1)       <> 0  then OSEdition = "Server"
		OSProductType = -1
		OSProductType = objOS.ProductType
		if OSProductType = 1 then OSEdition = "Workstation"
		if OSProductType = 2 then OSEdition = "Server"
		if OSProductType = 3 then OSEdition = "Server"
		
		'----- ADD
		'----- Add new OS here
		'----- OSFamily
		rc = objOS.OSType
		Select case rc
			case 16   OSFamily = "Windows95"
			case 17   OSFamily = "Windows98"
			case 18   OSFamily = "WINNT"
			case 19   OSFamily = "WindowsCE"
		end Select
		OSVersion = Left(objOS.Version & "   ", 3)
		if OSFamily = "WINNT" Then
			Select case OSVersion
				case "3.1" OSFamily = "WindowsNT3.1"
				case "3.5" OSFamily = "WindowsNT3.5"
				case "4.0" OSFamily = "WindowsNT4.0"
				case "5.0" OSFamily = "Windows2000"
				case "5.1" OSFamily = "WindowsXP"
				case "5.2" OSFamily = "Windows2003"
				case "6.0" OSFamily = "WindowsVista"
				case "6.1" OSFamily = "Windows7"
				case "6.2" OSFamily = "Windows8"
				case else  OSFamily = "WindowsNT" & OSVersion
			end Select
		end if
		if OSFamily = "WindowsVista" and OSEdition = "Server" then OSFamily = "Windows2008"
		if OSFamily = "Windows7"     and OSEdition = "Server" then OSFamily = "Windows2008R2"
		if OSFamily = "Windows8"     and OSEdition = "Server" then OSFamily = "Windows2012"
			
		'----- OSServicePack
		OSServicePack = CStr(objOS.ServicePackMajorVersion)

		'----- OSProductSuite
		rc = 0
		rc = objOS.OSProductSuite
		if (rc and 1  ) <> 0 then OSProductSuite = OSProductSuite & "Small Business | "
		if (rc and 2  ) <> 0 then OSProductSuite = OSProductSuite & "Enterprise | "
		if (rc and 4  ) <> 0 then OSProductSuite = OSProductSuite & "BackOffice | "
		if (rc and 8  ) <> 0 then OSProductSuite = OSProductSuite & "Communication Server | "
		if (rc and 16 ) <> 0 then OSProductSuite = OSProductSuite & "Terminal Server | "
		if (rc and 32 ) <> 0 then OSProductSuite = OSProductSuite & "Small Business (Restricted) | "
		if (rc and 64 ) <> 0 then OSProductSuite = OSProductSuite & "Embedded NT | "
		if (rc and 128) <> 0 then OSProductSuite = OSProductSuite & "Data Center | "
		'if (rc and 33 ) <> 0 and OSEdition = "Server" then
		'	OSEdition = "Small Business Server"
		'end if
		if len(OSProductSuite) >= 3 then
			OSProductSuite = left(OSProductSuite, len(OSProductSuite) - 3)
		end if
	next
	
	'----- Cluster Service running ?
	For Each objOS in GetObject("winmgmts:").InstancesOf ("Win32_Service")
		if objOS.Name = "ClusSvc" then
			if objOS.State <> "Stopped" then OSEdition = "Cluster"
		end if
	next

	'----- Microsoft Installer version
	OSMsiVersion = trim(fso.GetFileVersion(rootDir & "system32\msi.dll"))
	if OSMsiVersion = "" then OSMsiVersion = "0.0.0000.0000"

	'----- Microsoft Data Access Components version
	OSMdacVersion = RegRead("HKLM\SOFTWARE\Microsoft\DataAccess\FullInstallVer")
	if OSMdacVersion = "" then OSMdacVersion = "0.00.0000.0"

	if Not OnErrorResume then on error goto 0
end sub



'========================================================
'=  File functions 
'========================================================

sub FileOpen4Read(FileName)
	'FileName, 1=ForReading , False=NoCreate, -2=SystemDefault(Unicode/ASCII)
	set fsoTmp = fso.OpenTextFile(FileName, 1, False, -2)
end sub

'___________________________________________________________________________________________
'
sub FileOpen4Write(FileName)
	'FileName, 2=ForWriting , True=Create, 0=ASCII
	set fsoTmp = fso.OpenTextFile(FileName, 2, True, 0)
end sub

'___________________________________________________________________________________________
'
function FileReadLine()
	FileReadLine = fsoTmp.ReadLine
end function

'___________________________________________________________________________________________
'
function FileEOF()
	FileEOF = fsoTmp.AtEndOfStream
end function

'___________________________________________________________________________________________
'
sub FileWriteLine(FileLine)
	fsoTmp.WriteLine FileLine
end sub

'___________________________________________________________________________________________
'
function FileReadAll()
	FileReadAll = fsoTmp.ReadAll
end function

'___________________________________________________________________________________________
'
sub FileClose()
	fsoTmp.Close
end sub

'___________________________________________________________________________________________
'
function FileGetUNC(FullPath)
	dim tempDriveName, tempShareName, tempShare, tempShareList

	tempDriveName = left(FullPath, 2)
	tempShareName = tempDriveName
	if right(tempDriveName, 1) = ":" then
		on error resume next
			Set tempShareList = GetObject("winmgmts:\\.\root\cimv2").ExecQuery _
				("select * from Win32_NetworkConnection where LocalName = " & chr(34) & tempDriveName & chr(34))
			for each tempShare in tempShareList
				tempShareName = tempShare.RemoteName
			next
		if Not OnErrorResume then on error goto 0
	end if

	FileGetUNC = tempShareName & right(FullPath, len(FullPath)-2)
end function



'========================================================
'=  Registry functions 
'========================================================

function RegRead(RegKeyName)
	dim  RegValueData
	RegValueData = ""
	on error resume next
		RegValueData = WshShell.RegRead(RegKeyName)
	if Not OnErrorResume then on error goto 0
		RegSummary = RegSummary & RegKeyName & VbCrLf & "READ: "
		if isnull(RegValueData) then
			RegSummary = RegSummary & "<NULL>"
		else
			RegSummary = RegSummary & CStr(RegValueData)
		end if
		RegSummary = RegSummary & VbCrLf & VbCrLf
	RegRead = RegValueData
end function


'___________________________________________________________________________________________
'
sub RegWrite(RegKeyName, RegValueData, RegValueType)
	on error resume next
		WshShell.RegWrite RegKeyName, RegValueData, RegValueType
	if Not OnErrorResume then on error goto 0
		RegSummary = RegSummary & RegKeyName & VbCrLf & "WRITE(" & RegValueType & "): "
		if isnull(RegValueData) then
			RegSummary = RegSummary & "<NULL>"
		else
			RegSummary = RegSummary & CStr(RegValueData)
		end if
		RegSummary = RegSummary & VbCrLf & VbCrLf
end sub


'___________________________________________________________________________________________
'
sub RegDelete(RegKeyName)
	on error resume next
		WshShell.RegDelete RegKeyName
	if Not OnErrorResume then on error goto 0
		RegSummary = RegSummary & RegKeyName & VbCrLf & "DELETE: " & VbCrLf & VbCrLf
end sub



'========================================================
'=  Wrapper functions for InputBox, MsgBox and WScript.Quit()
'========================================================

function DoInputBox(Message, Title, Standard, LogResult)
	dim Result
	fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf & Now
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Input Box " & chr(34) & Title & chr(34)
	fsoLog.WriteLine Message
	if SilentInstall then
		Result = Standard
	else
		Result = InputBox(Message, Title, Standard)
	end if
	if LogResult then fsoLog.WriteLine "Result: " & Result
	fsoLog.WriteLine "----------------------------------------"
	DoInputBox = Result
end function


'___________________________________________________________________________________________
'
function DoMessageBox(Message, Options, Title)           
	dim Result
	fsoLog.WriteLine VbCrLf & VbCrLf & VbCrLf & Now
	fsoLog.WriteLine "----------------------------------------"
	fsoLog.WriteLine "Message Box " & chr(34) & Title & chr(34)
	fsoLog.WriteLine Message
	if SilentInstall then
		Select case (Options & 15)
			case vbOKOnly            Result = vbOK
			case vbOKCancel          Result = vbOK
			case vbAbortRetryIgnore  Result = vbIgnore
			case vbYesNoCancel       Result = vbYes
			case vbYesNo             Result = vbYes
			case vbRetryCancel       Result = vbCancel
			case else                Result = vbOK
		end Select
	else	
		Result = MsgBox(Message, Options, Title)
	end if
	Select case Result
		case vbOK		fsoLog.WriteLine "Result: vbOK"
		case vbCancel	fsoLog.WriteLine "Result: vbCancel"
		case vbAbort	fsoLog.WriteLine "Result: vbAbort"
		case vbRetry	fsoLog.WriteLine "Result: vbRetry"
		case vbIgnore	fsoLog.WriteLine "Result: vbIgnore"
		case vbYes	fsoLog.WriteLine "Result: vbYes"
		case vbNo		fsoLog.WriteLine "Result: vbNo"
		case else		fsoLog.WriteLine "Result: unknown"
	end Select
	fsoLog.WriteLine "----------------------------------------"
	DoMessageBox = Result
end function


'___________________________________________________________________________________________
'
sub QuitInstallation(ReturnValue)
	'----- restore overwritten registry values
	if not IsEmpty(RegValueName) then
		for i = 0 to 3
			if not IsEmpty(RegValueName(i)) then
				if IsEmpty(RegValueData(i)) then
					call RegDelete(RegValueName(i))
				else
					call RegWrite(RegValueName(i), RegValueData(i), "REG_DWORD")
				end if
			end if
		next
	end if
	
	if ReturnValue <> 32 then
		'----- print registry values
		fsoLog.WriteLine VbCrLf & VbCrLf
		fsoLog.WriteLine "Registry settings (2/2):"
		fsoLog.WriteLine "----------------------------------------"
		fsoLog.WriteLine RegSummary
		fsoLog.WriteLine "----------------------------------------" 
	
		'----- quit
		fsoLog.WriteLine VbCrLf & VbCrLf & Now
		fsoLog.WriteLine "Quit script with return code " & CStr(ReturnValue)
		if ContInstallRTM then
			fsoLog.WriteLine
			fsoLog.WriteLine "No SQL Server instance installed yet."
			fsoLog.WriteLine "Only .Net-Framework Installed."		 
			fsoLog.WriteLine ContTextRTM & InstanceText
		elseif ContInstallCU then
			fsoLog.WriteLine
			fsoLog.WriteLine "SQL Server instance installed."
			fsoLog.WriteLine "Cumulative Update not installed yet."		 
			fsoLog.WriteLine ContTextCU & InstanceText
		end if			
	end if
	
	'----- possible return codes
	' 0:     installation finished successfully - or: there is nothing to do
	' 3010:  installation finished successfully, reboot required
	' 1:     installation failed
	' 2:     installation canceled by user
	' 3:     installation of Service Pack failed
	' 4:     installation of Hotfix/CU failed
	' 5:     installation not finished, only .Net installed
	' 6:     installation not finished, only RTM installed	
	' 32:    installation failed, Could not open log file
	' 42:    installation failed, Active Directory Group "SA" exists
	' 50071: reboot required before starting installation
	WScript.Quit(ReturnValue)
end sub



'========================================================
'=  dead beat ...
'========================================================
