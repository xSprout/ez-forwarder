######################################################
#
# Splunk for Microsoft Exchange
# Exchange 2010 Mailbox Store Data Definition
# 
# Copyright (C) 2005-2018 Splunk Inc. All Rights Reserved.
# All Rights Reserved
#
######################################################

# Return the drive that the given Path resides on.
# The path is stored in $Path.PathName
function Get-VolumeForPath($Path) {
	$Volumes = Get-WMIObject -class "win32_volume" -namespace "root/cimv2" -ComputerName $env:ComputerName |Select Name,Capacity,FreeSpace
	$LongestVolName = ""
	$DBVolume = $null
	$UpcasedPathName = $Path.PathName.ToUpper()
	
	foreach ($Volume in $Volumes) {
		if ($UpcasedPathName.StartsWith($Volume.Name.ToUpper())) {
			if ($Volume.Name.Length -gt $LongestVolName.Length) {
				$LongestVolName = $Volume.Name
				$DBVolume = $Volume
			}
		}
	}
	
	$DBVolume
}

# Returns the % free space on the specified volume,
# which may be $null.
function Get-PercFreeForVolume($Volume) {
	if ($Volume) {
		if ($Volume.Capacity -eq 0) {
			$VolumePercFree = 100
		} else {
			$VolumePercFree = ($Volume.FreeSpace / $Volume.Capacity) * 100.00
		}
	} else {
		$VolumePercFree = 100
	}
	return $VolumePercFree
}

function Output-DatabaseInfo($Store, $Database) {
	# Build the output string from an array
	$Output = New-Object System.Collections.ArrayList

	$Active = "Unknown"
	if ($Database.IsValid) {
		if ($Database.MasterType -eq "Server") {
			if ($Database.Server.Name -eq $Store.Name) {
				$Active = "Active"
			} else {
				$Active = "Passive"
			}
		} else {
			if ($Database.Mounted) {
				$Active = "Passive"
				foreach ($s in $Database.Servers) { 
					if ($s.Name -eq $Store.Name) {
						$Active = "Active"
					}
				}
			} else {
				$Active = "Passive"
			}
		}
	} else {
		$Active = "Passive"
	}

	$Status = "Unknown"
	if ($Database.IsPublicFolderDatabase) {
		if ($Database.Mounted) {
			$Status = "Mounted"
		} else {
			$Status = "Unmounted"
		}
	} elseif ($Database.MasterType -eq "DatabaseAvailabilityGroup") {
		$DAGCopyStatus = (Get-MailboxDatabaseCopyStatus -Identity "$($Database.Identity)\$Store")
		$DAGStatus = $DAGCopyStatus.Status
		$DAGHealth = $DAGCopyStatus.ContentIndexState
		$Status = "$DAGStatus,$DAGHealth"
	} else {
		if ($Database.Mounted) {
			$Status = "Mounted"
		} else {
			$Status = "Unmounted"
		}
	}

	$LogDisk = Get-VolumeForPath($Database.LogFolderPath)
	$LogDiskPercFree = Get-PercFreeForVolume($LogDisk)
	
	$LogFiles = (DIR "$($Database.LogFolderPath)\*.log")
	$LogSize = 0
	Foreach ($LogFile in $LogFiles) {
		$LogSize = $LogSize + $LogFile.Length
	}
	
	$EdbDisk = Get-VolumeForPath($Database.EdbFilePath)
	if ($EdbDisk) {
		$EdbDiskName = $EdbDisk.Name
		$EdbDiskFreeSpace = $EdbDisk.FreeSpace
		$EdbDiskCapacity = $EdbDisk.Capacity
	} else {
		$EdbDiskName = "Unknown"
		$EdbDiskFreeSpace = 0
		$EdbDiskCapacity = 0
	}
	$EdbDiskPercFree = Get-PercFreeForVolume($EdbDisk)
	$EdbSize = ($Database.EdbFilePath.PathName | Get-ChildItem).Length

	$Date = Get-Date -format 'yyyy-MM-ddTHH:mm:sszzz'
	[void]$Output.Add($Date)

	[void]$Output.Add("Database=`"$($Database.Identity)`"") 
	[void]$Output.Add("Active=`"$Active`"")
	[void]$Output.Add("MasterType=`"$($Database.MasterType)`"")
	[void]$Output.Add("Status=`"$Status`"")
	[void]$Output.Add("PublicFolderDatabase=`"$($Database.PublicFolderDatabase)`"")
	[void]$Output.Add("IsMailboxDatabase=`"$($Database.IsMailboxDatabase)`"")
	[void]$Output.Add("IsPublicFolderDatabase=`"$($Database.IsPublicFolderDatabase)`"")
	[void]$Output.Add("LogFolderPath=`"$($Database.LogFolderPath)`"")
	[void]$Output.Add("LogPercFree={0:N3}" -f $LogDiskPercFree)
	[void]$Output.Add("LogSize=$LogSize")
	[void]$Output.Add("FilePath=`"$($Database.EdbFilePath)`"")
	[void]$Output.Add("FileDiskName=$EdbDiskName")
	[void]$Output.Add("FileDiskFreeSpace=$EdbDiskFreeSpace")
	[void]$Output.Add("FileDiskCapacity=$EdbDiskCapacity")
	[void]$Output.Add("MainPercFree={0:N3}" -f $EdbDiskPercFree)
	[void]$Output.Add("FileSize=$EdbSize")
	[void]$Output.Add("LocalCopy=`"False`"")
	[void]$Output.Add("CopyFilePath=`"`"")
	[void]$Output.Add("CopyPercFree=0")
	[void]$Output.Add("CopyFileSize=0")
	[void]$Output.Add("CopyStatus=Disabled")
	[void]$Output.Add("SnapshotLastFullBackup=`"$($Database.SnapshotLastFullBackup)`"")
	[void]$Output.Add("SnapshotLastIncrementalBackup=`"$($Database.SnapshotLastIncrementalBackup)`"")
	[void]$Output.Add("SnapshotLastDifferentialBackup=`"$($Database.SnapshotLastDifferentialBackup)`"")
	[void]$Output.Add("SnapshotLastCopyBackup=`"$($Database.SnapshotLastCopyBackup)`"")
	[void]$Output.Add("LastFullBackup=`"$($Database.LastFullBackup)`"")
	[void]$Output.Add("LastIncrementalBackup=`"$($Database.LastIncrementalBackup)`"")
	[void]$Output.Add("LastDifferentialBackup=`"$($Database.LastDifferentialBackup)`"")
	[void]$Output.Add("LastCopyBackup=`"$($Database.LastCopyBackup)`"")
	
	# Send the output down the line
	Write-Host ($Output -join " ")
	
}

$Store = Get-MailboxServer -Identity $env:ComputerName

$DatabaseList = New-Object System.Collections.ArrayList
Foreach ($database in Get-MailboxDatabase -server $Store -Status) {
        [void]$DatabaseList.Add($database)
}
Foreach ($database in Get-PublicFolderDatabase -server $Store -Status) {
        [void]$DatabaseList.Add($database)
}

$OutputEncoding = [Text.Encoding]::UTF8
Foreach ($database in $DatabaseList) {
	Output-DatabaseInfo -Store $Store -Database $database
}
