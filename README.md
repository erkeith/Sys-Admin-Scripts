# Sys-Admin-Scripts
PowerShell Scripts for SYS Admin work

## Remote System Checker Script
This PowerShell script performs various maintenance tasks on a remote computer, such as checking for active users, verifying free space, checking for updates, and more.

### Parameters
- ComputerName (Mandatory): The name of the computer to perform the maintenance tasks on.
- CheckProcess: The name of the process to check.
- ActiveUsers: Switch to check for active users.
- CheckUpdates: Switch to check for available updates.
- CheckFreeSpace: Switch to check for free space on the drives.
- ConnectionTest: Switch to test the connection to the computer.
- IgnoreInitialChecks: Switch to ignore initial checks.
- InitialChecks: Switch to perform initial checks.
- LogoutUser: Switch to log out a user.

### Usage Examples
#### Example 1: Check for Active Users and Free Space
```powershell
.\RemoteSystemChecker.ps1 -ComputerName "Server01" -ActiveUsers -CheckFreeSpace
```
#### Example 2: Perform Initial Checks and Check for Updates
```powershell
.\RemoteSystemChecker.ps1 -ComputerName "Server01" -InitialChecks -CheckUpdates
```
#### Example 3: Check if a Specific Process is Running
```powershell
.\RemoteSystemChecker.ps1 -ComputerName "Server01" -CheckProcess "notepad"
```
#### Example 4: Log Out a User
```powershell
.\RemoteSystemChecker.ps1 -ComputerName "Server01" -LogoutUser "JohnDoe"
```
