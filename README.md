# NewADUsers
Script for creating new users in Active Directory

The Active Directory Bulk User Provisioning Tool (`NewADUsers.ps1`) automates creating new user accounts or updating existing passwords using data imported from `NewADUsers.csv`. Prepare your user roster in Excel using required headers (`username`, `password`, `firstname`, `lastname`, `ou`, `email`, etc.), generating usernames with `=RIGHT(C2, 2) & A2 & UPPER(LEFT(D2, 1)) & UPPER(LEFT(E2, 1))` to combine the 2-digit graduation year, program code, and student initials (e.g., `30CCARS`). Ensure Distinguished Names in the `ou` column containing commas (e.g., `"OU=Students,DC=ct,DC=us"`) are wrapped in double quotes to prevent CSV column alignment errors.

| | A | B | C | D | E |
|---|:---|:---|:---|:---|:---|
| **1** | **Program** | **yearofgraduation** | **firstname** | **lastname** | **username** |
| **2** | CCA | 2030 | Robert | Saget | 30CCARS |

To run the tool on a Domain Controller, launch an elevated PowerShell prompt within the script's directory. Running `.\NewADUsers.ps1` defaults to **Audit Mode**, providing a color-coded console summary of proposed account creations and password resets without modifying Active Directory. After reviewing the dry run, execute `.\NewADUsers.ps1 -authorize` to apply live directory changes and output a timestamped summary report CSV (`ADUsers_Results_YYYYMMDD_HHMMSS.csv`) detailing all completed actions and error messages.
