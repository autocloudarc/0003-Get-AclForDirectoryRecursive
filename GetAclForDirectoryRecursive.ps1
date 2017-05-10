#requires -version 4.0
#requires -RunAsAdministrator
<#
****************************************************************************************************************************************************************************
PROGRAM		: 0003-Get-AclsRecursivelyForDirectoryTkn.ps1

DESCIRPTION	: 
This script will recursively enumerate and log the ACL list of a specified directory and all its associated subdirectories and files. 
You will be prompted for the target path and log path where the ACL list will be recorded. The following information will be reported for each folder, 
subfolder or file: Full path, owner and the access control entries, consisting of the principal, access control type [AC TYPE], ie. Allow and rights [RIGHTS] such as Modify 
or Full Control. When the script completes, you will be prompted to open the log file and review the results.

PARAMETERS	: $TargetPath, $LogPath
INPUTS		: You will be prompted for the home directory share or local path path for the $TargetPath varialbe, as well as the log path for the $LogPath variable. 
OUTPUTS		: $Log
EXAMPLES	: Get-AclsRecursivelyForDirectory.ps1
REQUIREMENTS: PowerShell Version 4.0, Run as administrator
LIMITATIONS	: NA
AUTHOR(S)	: Preston K. Parsard
EDITOR(S)	: 
REFERENCES	: 
1. https://technet.microsoft.com/en-us/magazine/2008.02.powershell.aspx

KEYWORDS	: Directory, files, folders, permissions, Acl, access

LICENSE:

The MIT License (MIT)
Copyright (c) 2016 Preston K. Parsard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software. 

DISCLAIMER:

THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, 
royalty-free right to use and modify the Sample Code and to reproduce and distribute the Sample Code, provided that You agree: (i) to not use Our name, 
logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, 
and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, 
that arise or result from the use or distribution of the Sample Code.
****************************************************************************************************************************************************************************
#>

<# WORK ITEMS
TASK-INDEX: 
#>

<# 
***************************************************************************************************************************************************************************
REVISION/CHANGE RECORD	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DATE        VERSION    NAME               CHANGE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
22 MAY 2016 00.00.0001 Preston K. Parsard Initial release
22 MAY 2016  00.00.0009 Preston K. Parsard Updated filename to: 0003-Get-AclsRecursivelyForDirectoryTkn.ps1 in order to index and tag as a contributed script
#>

#region INITIALIZE VALUES	

$BeginTimer = Get-Date
$Processed = 0

# Setup script execution environment
Clear-Host 
# Set foreground color 
$OriginalForeground = "Green"
$EmphasisForeground = "Yellow"
$host.ui.RawUI.ForegroundColor = $OriginalForeground

# Create and populate prompts object with property-value pairs
# PROMPTS (PromptsObj)
$PromptsObj = [PSCustomObject]@{
 pAskToOpenLog = "Would you like to open the log now ? [YES/NO]"
} #end $PromptsObj

# Create and populate responses object with property-value pairs
# RESPONSES (ResponsesObj): Initialize all response variables with null value
$ResponsesObj = [PSCustomObject]@{
 pOpenLogNow = $null
} #end $ResponsesObj

Do
{
 $host.ui.RawUI.ForegroundColor = $EmphasisForeground
 Write-Host("Please enter the target path for your target directory, i.e. \\fs1.litware.lab\home or d:\data")
 [string] $TargetPath = Read-Host
 $host.ui.RawUI.ForegroundColor = $OriginalForeground
 Write-Host("")
} #end Do
Until (($TargetPath) -ne $null)

$ColumnWidth = 108
$EmptyString = ""
$DoubleLine = ("=" * $ColumnWidth)
$SingleLine = ("-" * $ColumnWidth)
[int]$l= 0

Do
{
 $host.ui.RawUI.ForegroundColor = $EmphasisForeground
 Write-Host("Please enter the log path where the output for this script will be saved, i.e. \\fs1.litware.lab\logs or d:\logs")
 [string] $LogPath = Read-Host
 $host.ui.RawUI.ForegroundColor = $OriginalForeground
} #end Do
Until (($LogPath) -ne $null)

$StartTime = (((get-date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")

Function Script:New-Log
{
  [int]$Script:l++
  # Create log file with a "u" formatted time-date stamp
  $LogFile = "Get-AclsRecursivelyForDirectory" + "-" + $StartTime + "-" + [int]$Script:l + ".log"
  $Script:Log = Join-Path -Path $LogPath -ChildPath $LogFile
  New-Item -Path $Script:Log -ItemType File -Force
} #end function

New-Log

Function Get-LogSize
{
 $LogObj = Get-ChildItem -Path $Log 
 # CONIFIG: Use 1mb for production, 1kb for testing. Default value will be [1mb]
 $LogSize = ([System.Math]::Round(($LogObj.Length/1mb)))
 If ($LogSize -gt 10)
 {
  ShowAndLog("")
  ShowAndLog("------------------------")
  ShowAndLog("Creating new log file...")
  ShowAndLog("------------------------")
  # Create a new log with new index and timestamp
  $LogSize = 0
  New-Log
 } #end if
} #end function

$DelimDouble = ("=" * 100 )
$Header = "GET ACLs FOR DIRECTORIES: " + $StartTime

# Index to uniquely identify each line when logging using the LogWithIndex function
$Index = 0
# Populate Summary Display Object
# Add properties and values
# Make all values upper-case
 $SummObj = [PSCustomObject]@{
  TARGETPATH = $TargetPath.ToUpper()
  LOGFILE = $Log
 } #end $SummObj

# Send output to both the console and log file
Function ShowAndLog
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$Output)
$Output | Tee-Object -FilePath $Log -Append
} #end ShowAndLog

# Send output to both the console and log file and include a time-stamp
Function LogWithTime
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$LogEntry)
# Construct log time-stamp for indexing log entries
# Get only the time stamp component of the date and time, starting with the "T" at position 10
$TimeIndex = (get-date -format o).ToString().Substring(10)
$TimeIndex = $TimeIndex.Substring(0,17)
"{0}: {1}" -f $TimeIndex,$LogEntry 
} #end LogWithTime

# Send output to both the console and log file and include an index
Function Script:LogWithIndex
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$LogEntry)
# Increment QA index counter to uniquely identify this item being inspected
$Script:Index++
"{0}`t{1}" -f $Script:Index,$LogEntry | Tee-Object -FilePath $Log -Append
} #end LogWithIndex

# Send output to log file only
Function LogToFile
{
[CmdletBinding()] Param([Parameter(Mandatory=$True)]$LogData)
$LogData | Out-File -FilePath $Log -Append
} #end LogToFile

#endregion INITIALIZE VALUES

#region MAIN	

# Clear-Host 

# Display header
ShowAndLog($DelimDouble)
ShowAndLog($Header)
ShowAndLog($DelimDouble)

# Netbios domain name
$Domain = $env:userdomain

# List NTFS permissions
ShowAndLog("Enumerating ACL lists on files and folders...")
$WalkDirectory  = Get-ChildItem -Path $TargetPath -Recurse -Force
ForEach ($Directory in $WalkDirectory)
{
 $CurrentACL = Get-Acl $Directory.FullName
 ShowAndLog($SingleLine)
 ShowAndLog("[PATH.....]: $($CurrentACL.Path)")
 ShowAndLog("[OWNER....]: $($CurrentACL.Owner)")
 $AceCount = $CurrentACL.Access.Count
 For ($a =1; $a -lt $AceCount; $a++)
 {
  $CurrentAce = $CurrentAcl.Access.Item($a)
  ShowAndLog("[PRINCIPAL]: $($CurrentAce.IdentityReference) [AC TYPE]: $($CurrentAce.AccessControlType) [RIGHTS] $($CurrentAce.FileSystemRights)")
 } #end for
 $Processed++
 . Get-LogSize
} #end ForEach

. Get-LogSize
#endregion MAIN

#region FOOTER		

# Calculate elapsed time
ShowAndLog("Calculating script execution time...")
$StopTimer = Get-Date
$EndTime = (((Get-Date -format u).Substring(0,16)).Replace(" ", "-")).Replace(":","")
$ExecutionTime = New-TimeSpan -Start $BeginTimer -End $StopTimer

$Footer = "SCRIPT COMPLETED AT: "
[int]$TotalUsers = $Processed

ShowAndLog($DelimDouble)
ShowAndLog($Footer + $EndTime)
ShowandLog("# of file and folder objects processed: $Processed")
ShowAndLog("TOTAL SCRIPT EXECUTION TIME: $ExecutionTime")
ShowAndLog("Log path is: $Log")
ShowAndLog($DelimDouble)

# Prompt to open log
# CONFIG: Comment out the entire prompt below (Do...Until loop) after testing is completed and you are ready to schedule this script. This is just added as a convenience during testing.

Do 
{
 $ResponsesObj.pOpenLogNow = read-host $PromptsObj.pAskToOpenLog
 $ResponsesObj.pOpenLogNow = $ResponsesObj.pOpenLogNow.ToUpper()
}
Until ($ResponsesObj.pOpenLogNow -eq "Y" -OR $ResponsesObj.pOpenLogNow -eq "YES" -OR $ResponsesObj.pOpenLogNow -eq "N" -OR $ResponsesObj.pOpenLogNow -eq "NO")

# Exit if user does not want to continue
if ($ResponsesObj.pOpenLogNow -eq "Y" -OR $ResponsesObj.pOpenLogNow -eq "YES") 
{
 Start-Process notepad.exe $Log
} #end if


# End of script
LogWithTime("END OF SCRIPT!")

#endregion FOOTER

# CONFIG: If you need to schedule this script, remove pause statement below for production run in your environment. 
# CONFIG: ...This has only been added as a convenience during testing so that the powershell console isn't lost after the script completes.
Pause
Exit