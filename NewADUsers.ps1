[CmdletBinding()]
param (
    [Switch]$Authorize
)
#########################################
# Edited by Jaren Havell using Gimmney  #
# Original from  NetworkProGuide.com    #
# Version 1.3                           #
#########################################
# Import the AD module
Import-Module activedirectory  

# Store data from NewADUsers.csv in $ADUsers
$ADUsers = Import-csv .\NewADUsers.csv

# ============================================================================
# MODE 1: AUDIT MODE (DEFAULT)
# ============================================================================
if (-not $Authorize)
{
    Write-Host "`n==========================================" -ForegroundColor Cyan
    Write-Host "             AUDIT MODE ACTIVE            " -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "No changes will be made to Active Directory.`n" -ForegroundColor DarkGray

    $ProposedCreates = 0
    $ProposedUpdates = 0

    foreach ($User in $ADUsers)
    {
        $Username  = $User.username
        $Firstname = $User.firstname
        $Lastname  = $User.lastname
        $UPN       = "$Username@students.edadvance.org"
        $FullName  = "$Firstname $Lastname"

        # Check for matching accounts
        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$Username' -or UserPrincipalName -eq '$UPN' -or Name -eq '$FullName'" -ErrorAction SilentlyContinue

        if ($ExistingUser)
        {
            Write-Host "[PROPOSED ACTION] UPDATE PASSWORD -> User '$Username' already exists." -ForegroundColor Yellow
            $ProposedUpdates++
        }
        else
        {
            Write-Host "[PROPOSED ACTION] CREATE ACCOUNT -> New user '$Username' will be created." -ForegroundColor Green
            $ProposedCreates++
        }
    }

    Write-Host "`n------------------------------------------" -ForegroundColor DarkGray
    Write-Host "AUDIT SUMMARY" -ForegroundColor Cyan
    Write-Host "Total Accounts Processed : $($ADUsers.Count)"
    Write-Host "Accounts to Create       : $ProposedCreates" -ForegroundColor Green
    Write-Host "Passwords to Reset       : $ProposedUpdates" -ForegroundColor Yellow
    Write-Host "------------------------------------------`n" -ForegroundColor DarkGray

    Write-Host "NOTE: You have run this script in audit mode. After you have reviewed the proposed items below, re-run the script with -authorize" -ForegroundColor Magenta
    Write-Host ""
}

# ============================================================================
# MODE 2: AUTHORIZE MODE (EXECUTE CHANGES)
# ============================================================================
else
{
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "           AUTHORIZE MODE ACTIVE          " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Applying changes to Active Directory...`n" -ForegroundColor DarkGray

    $Results = @()

    foreach ($User in $ADUsers)
    {
        $Username      = $User.username
        $Password      = $User.password
        $Firstname     = $User.firstname
        $Lastname      = $User.lastname
        $OU            = $User.ou
        $email         = $User.email
        $streetaddress = $User.streetaddress
        $city          = $User.city
        $zipcode       = $User.zipcode
        $state         = $User.state
        $country       = $User.country
        $description   = $User.description
        $office        = $User.office
        $telephone     = $User.telephone
        $jobtitle      = $User.jobtitle
        $company       = $User.company
        $department    = $User.department

        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $UPN            = "$Username@students.edadvance.org"
        $FullName       = "$Firstname $Lastname"

        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$Username' -or UserPrincipalName -eq '$UPN' -or Name -eq '$FullName'" -ErrorAction SilentlyContinue

        if ($ExistingUser)
        {
            # Match found: Update password
            try {
                Set-ADAccountPassword -Identity $ExistingUser.SamAccountName -NewPassword $SecurePassword -Reset -ErrorAction Stop
                
                Write-Host "[UPDATED] Password changed for existing user: $($ExistingUser.SamAccountName)" -ForegroundColor Yellow

                $Results += [PSCustomObject]@{
                    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Username     = $Username
                    Status       = "Password Updated"
                    ErrorDetails = ""
                }
            }
            catch {
                $ErrMsg = $_.Exception.Message
                Write-Host "[FAILED] Password reset for ${Username}: $ErrMsg" -ForegroundColor Red

                $Results += [PSCustomObject]@{
                    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Username     = $Username
                    Status       = "Failed (Password Reset)"
                    ErrorDetails = $ErrMsg
                }
            }
        }
        else
        {
            # No match: Create new user
            try {
                New-ADUser `
                    -SamAccountName $Username `
                    -UserPrincipalName $UPN `
                    -Name $FullName `
                    -GivenName $Firstname `
                    -Surname $Lastname `
                    -Enabled $True `
                    -DisplayName $FullName `
                    -Path $OU `
                    -City $city `
                    -Company $company `
                    -State $state `
                    -StreetAddress $streetaddress `
                    -OfficePhone $telephone `
                    -EmailAddress $email `
                    -Title $jobtitle `
                    -Department $department `
                    -AccountPassword $SecurePassword `
                    -ChangePasswordAtLogon $True `
                    -ErrorAction Stop

                Write-Host "[CREATED] New user: $Username" -ForegroundColor Green

                $Results += [PSCustomObject]@{
                    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Username     = $Username
                    Status       = "User Created"
                    ErrorDetails = ""
                }
            }
            catch {
                $ErrMsg = $_.Exception.Message
                Write-Host "[FAILED] Could not create user ${Username}: $ErrMsg" -ForegroundColor Red

                $Results += [PSCustomObject]@{
                    Timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Username     = $Username
                    Status       = "Failed (User Creation)"
                    ErrorDetails = $ErrMsg
                }
            }
        }
    }

    # Export results to CSV
    $OutputFile = ".\ADUsers_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $Results | Export-Csv -Path $OutputFile -NoTypeInformation

    Write-Host "`nProcess complete. Results saved to $OutputFile`n" -ForegroundColor Cyan
}
