$verbosePreference = "Continue"


# Load core module

$deployRoot = Split-Path -Path "$PSScriptRoot"
Write-Verbose "Using deploy root $deployRoot, based on $PSScriptRoot"
Import-Module "$deployRoot\Scripts\PSDUtility.psm1" -Force


# Keep the logging out of the way

if ((Get-PSDLocalDataPath) -NotLike "X:\*")
{
    Stop-PSDLogging
    $logPath = "X:\MININT\Logs"
    if ((Test-Path $logPath) -eq $false) {
        New-Item -ItemType Directory -Force -Path $logPath | Out-Null
    }
    Start-Transcript "$logPath\PSDPartition.ps1.log"
}


# Partition and format the disk

Update-Disk -Number 0
$disk = Get-Disk -Number 0

if ($tsenv:IsUEFI -eq "True")
{
    if ($disk.PartitionStyle -ne "RAW")
    {
        Write-Verbose "Clearing disk"
        Clear-Disk -Number 0 -RemoveData -RemoveOEM -Confirm:$false
    }
    Write-Verbose "Initializing disk"
    Initialize-Disk -Number 0 -PartitionStyle GPT
    Get-Disk -Number 0

    $osSize = $disk.Size - 499MB - 128MB - 499MB

    $efi = New-Partition -DiskNumber 0 -Size 499MB -AssignDriveLetter -IsActive -GptType c12a7328-f81f-11d2-ba4b-00a0c93ec93b
    $msr = New-Partition -DiskNumber 0 -Size 128MB -IsActive -GptType e3c9e316-0b5c-4db8-817d-f92df00215ae
    $os = New-Partition -DiskNumber 0 -Size $osSize -AssignDriveLetter
    $recovery = New-Partition -DiskNumber 0 -UseMaximumSize -AssignDriveLetter -GptType de94bba4-06d1-4d40-a16a-bfd50179d6ac

    $tsenv:BootVolume = $efi.DriveLetter
    $tsenv:OSVolume = $os.DriveLetter
    $tsenv:RecoveryVolume = $recovery.DriveLetter

    Format-Volume -DriveLetter $tsenv:BootVolume -FileSystem FAT32
    Format-Volume -DriveLetter $tsenv:OSVolume -FileSystem NTFS
    Format-Volume -DriveLetter $tsenv:RecoveryVolume -FileSystem NTFS
}
else
{
    if ($disk.PartitionStyle -ne "RAW")
    {
        Write-Verbose "Clearing disk"
        Clear-Disk -Number 0 -RemoveData -RemoveOEM -Confirm:$false
    }
    Write-Verbose "Initializing disk"
    Initialize-Disk -Number 0 -PartitionStyle MBR
    Get-Disk -Number 0

    $osSize = $disk.Size - 499MB - 499MB

    $boot = New-Partition -DiskNumber 0 -Size 499MB -AssignDriveLetter -IsActive
    $os = New-Partition -DiskNumber 0 -Size $osSize -AssignDriveLetter
    $recovery = New-Partition -DiskNumber 0 -UseMaximumSize -AssignDriveLetter

    $tsenv:BootVolume = $boot.DriveLetter
    $tsenv:OSVolume = $os.DriveLetter
    $tsenv:RecoveryVolume = $recovery.DriveLetter

    Format-Volume -DriveLetter $tsenv:BootVolume -FileSystem NTFS
    Format-Volume -DriveLetter $tsenv:OSVolume -FileSystem NTFS
    Format-Volume -DriveLetter $tsenv:RecoveryVolume -FileSystem NTFS
}
