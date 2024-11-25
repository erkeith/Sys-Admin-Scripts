  [Parameter(Mandatory=$true)]
  [string]$ComputerName,

  [string]$CheckProcess,

  [switch]$ActiveUsers,
  [switch]$CheckUpdates,
  [switch]$CheckFreeSpace,
  [switch]$ConnectionTest,
  [switch]$IgnoreInitialChecks,
  [switch]$InitialChecks,
  [switch]$LogoutUser
)


function CleanupComputer {
    param (
        [string]$ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        # Uninstall PSWindowsUpdate Module
        Uninstall-Module -Name PSWindowsUpdate -AllVersions
    } -ErrorAction Stop
}

function GetFreeSpace {
    param (
        [string]$ComputerName
    )
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name, 
            @{Name="FreeSpace(GB)";Expression={[math]::round($_.Free/1GB,2)}}, 
            @{Name="UsedSpace(GB)";Expression={[math]::round(($_.Used/1GB),2)}}, 
            @{Name="TotalSpace(GB)";Expression={[math]::round($_.Used/1GB + $_.Free/1GB,2)}}
    }
}

function GetUsers {
    param (
        [string]$ComputerName
    )

    try {
        $loggedInUsers = quser /server:$ComputerName
        $parsedOutput = $loggedInUsers | ForEach-Object {
                if ($_ -match '^\s*(\S+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(.+)$') {
                    [PSCustomObject]@{
                        UserName  = $matches[1]
                        State     = $matches[4]
                        LogonTime = $matches[6]
                    }
                }
            }
        if ($parsedOutput) {
            $parsedOutput | Select-Object UserName, State, LogonTime | Format-Table -AutoSize
        } else {
            Write-Output "No users are currently logged into this machine."
        }
    } catch {
        Write-Output "No users are currently logged into this machine."
    }
}


function GetUpdateList {
    param (
        [string]$ComputerName
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        # Install Update Module if not installed
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
        }

        # Import Update Module
        Import-Module PSWindowsUpdate

        # Check For Available Updates
        $updates = Get-WindowsUpdate -MicrosoftUpdate


        # Output Updates to Terminal
        if ($updates.Count -eq 0) {
            Write-Output "✔️ - System is fully updated"
        } else {
            foreach ($update in $updates) {
                if ($update.KB) {
                    Write-Output "$($update.KB) - $($update.Status) - $($update.Title)"
               }
            }
            #Get-WindowsUpdate
        }
    } -ErrorAction Stop
    
}

function InitialChecks {
    param (
        [string]$ComputerName
    )
 
    ## Verify the Machine is pingable
    $pingable = Test-Connection -ComputerName $ComputerName -Quiet

    if ($pingable) {
        Write-Output ""
        Write-Output "✔️ - $ComputerName can be reached"
    } else {
        Write-Output "❌ - $ComputerName is not reachable"
        exit
    }

    $wsmable = Test-WSMan -ComputerName $ComputerName

    if ($wsmable) {
        Write-Output "✔️ - $ComputerName has WinRM running"
    } else {
        Write-Output "❌ - $ComputerName does not have WinRM running or working"
        exit
    }

    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            param([string]$ComputerName)
            $protocols = [Net.ServicePointManager]::SecurityProtocol
            if ($protocols -band [Net.SecurityProtocolType]::Tls11) {
                
                Write-Output "✔️ - $ComputerName - TLS 1.1 enabled"
            } else {
                Write-Output "❌ - $ComputerName - TLS 1.1 not enabled"
            }
        } -ArgumentList $ComputerName -ErrorAction Stop
    } catch {}

}

function LogoutUser {
    param (
        [string]$ComputerName,
        [string]$UserName
    )

    try {
        $userSession = quser /server:$ComputerName | Where-Object { $_ -match $UserName }
        if ($userSession) {
            $sessionId = ($userSession -split '\s+')[2]
            logoff $sessionId /server:$ComputerName
            Write-Output "User $UserName has be logged off of $ComputerName."
        } else {
            Write-Output "User $UserName could not be logged off of $ComputerName."
        }
    } catch {
        Write-Output "User $UserName could not be logged off of $ComputerName."
    }
}

function PrintDecorator {
    param (
        [string]$message,
        [bool]$headerMessage
    )
    $totalWidth = 40
    $padding = ($totalWidth - $message.Length) /2

    $headerChar = "=" * $totalWidth
    $centeredMessage = "-" * [math]::Floor($padding) + $message + "-" * [math]::Ceiling($padding)

    if ($headerMessage) {
        Write-Output $headerChar
        Write-Output $centeredMessage
        Write-Output $headerChar
    } else {
        Write-Output ""
        Write-Output $centeredMessage
    }
}

function GetProcess{
    param(
        [string]$ComputerName,
        [string]$CheckProcess
    )

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
	param($CheckProcess)
        $process = Get-Process -Name $CheckProcess -ErrorAction SilentlyContinue
	if (-not $process) {
	     Write-Output "❌ - Specified process is not running."
	} else {
	     $process
	}
    } -ArgumentList $CheckProcess
}


# Print Machine Name
PrintDecorator -message " $ComputerName " -headerMessage $true


if (-not $IgnoreInitialChecks) {
    PrintDecorator -message " Running Initial Checks " -headerMessage $false
    InitialChecks -ComputerName $ComputerName
}

if ($ActiveUsers) {
    PrintDecorator -message " Active Users " -headerMessage $false
    GetUsers -ComputerName $ComputerName
}

if ($CheckFreeSpace) {
    PrintDecorator -message " Identifying Hardrive Usage " -headerMessage $false
    Write-Output ""
    GetFreeSpace -ComputerName $ComputerName
}

if ($CheckUpdates) {
    PrintDecorator -message " Getting List of Updates " -headerMessage $false
    Write-Output ""
    GetUpdateList -ComputerName $ComputerName
    CleanupComputer -ComputerName $ComputerName
}

if ($CheckProcess) {
    PrintDecorator -message " Checking Process $CheckProcess " -headerMessage $false
    Write-Output ""
    GetProcess -ComputerName $ComputerName -CheckProcess $CheckProcess
}

if ($LogoutUser) {
    LogoutUser -ComputerName $ComputerName -UserName $LogoutUser
}
