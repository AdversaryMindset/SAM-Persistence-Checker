# SAM-Persistence-Checker

This PowerShell script is specifically designed to detect unauthorized modifications of Security Accounts Manager (SAM) profile IDs within Windows systems. It checks if any users have manipulated their profile IDs to masquerade with elevated privileges, such as those of a local administrator. This script is crucial for security audits, helping administrators identify potential security breaches where user privileges may have been escalated through SAM tampering.

## Prerequisites

- Administrative privileges on the host machine.
- psexec to launch powershell script as SYSTEM to view the SAM directly

## Usage

1. Download the `CheckSam.ps1` script from this repository.
2. Open CMD as an Administrator.
3. Navigate to the directory where the script is located.
4. Execute the script:
   psexec -s -i powershell -ExecutionPolicy Bypass .\CheckSAMProfileID.ps1
5. The script will output any profile ID's that have been duplicated.
