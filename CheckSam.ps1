##################################################################################################
# Adversary Mindset LLC
# Copyright 2024 Adversary Mindset LLC
# May 7, 2024
#
# Check SAM for Users Utilizing SAM Profile Modification
# If any users are found with duplicate profile IDs they may be using the SAM persistence trick
##################################################################################################

# Ensure the script is running with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires administrator privileges." -ForegroundColor Red
    exit
}

# Attempt to load the SAM registry hive if it's not already loaded
$samLoaded = $false
if (-not (Test-Path "HKLM:\SAM"))
{
    try
    {
        & reg.exe load HKLM\SAM C:\Windows\System32\config\SAM
        $samLoaded = $true
    }
    catch
    {
        Write-Error "Failed to load SAM registry hive. Please ensure this script is run as SYSTEM."
        exit
    }
}

# Path to the users in the SAM
$path = "HKLM:\SAM\SAM\Domains\Account\Users"

# Getting the names and types of users
try
{
    $users = Get-ChildItem $path -ErrorAction Stop | Where-Object { $_.Name -notmatch "Names" } | ForEach-Object {
        $userPath = $_.PSPath
        $userData = Get-ItemProperty -Path $userPath -Name "F" -ErrorAction SilentlyContinue

        if ($userData -and $userData.F) {
            # Extract bytes corresponding to the 7th line (byte index 48 to 50 for the first two bytes of the 7th line)
            $bytesToCheck = $userData.F[48..49]
            # Convert the bytes to a hexadecimal string
            $hexProfileID = ($bytesToCheck | ForEach-Object { $_.ToString("X2") }) -join ''
         }
        else {
            $hexProfileID = "Not Accessible/Does Not Exist"
         }

	  $sid = $_.PSChildName.TrimStart('0') # Trim leading zeros for readability

        [PSCustomObject]@{
            SID = $_.PSChildName
            ProfileID = $hexProfileID
        }
    }

    # Display users
    Write-Host "Users, and Profile ID (from 7th line of 'F' Hex):"
    $users | Format-Table -AutoSize

    # Check for duplicated Profile IDs
    $duplicates = $users | Group-Object ProfileID | Where-Object { $_.Count -gt 1 -and $_.Name -ne "Not Accessible/Does Not Exist" }
    if ($duplicates) {
        Write-Host "Duplicate Profile IDs found:"
        $duplicates | ForEach-Object {
            Write-Host "$($_.Name):"
            $_.Group | Format-Table SID, ProfileID -AutoSize
        }
    } else {
        Write-Host "No duplicate Profile IDs found."
    }
}
catch
{
    Write-Error "Failed to read user data from the SAM registry. Error: $_"
}

# Unload the SAM hive if it was loaded by this script
if ($samLoaded)
{
    & reg.exe unload HKLM\SAM
}
