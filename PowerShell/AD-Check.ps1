function CheckAD {
    param([string]$user)
        try{ 
           Get-ADUser -Filter * | Where-Object { ($_.SamAccountName -like $user) -or ($_.UserPrincipalName -like $user)}
        }Catch{
           return 0
        }
    }

function New-ADCheck {
    param (
      [switch]$Path = "txt/file/path",
      [switch]$SingleUser = $null
    )

        if($SingleUser -match $null){
            foreach ($user in Get-Content -Path $Path) {
                CheckAD $user
            }
        }else {
            CheckAD $SingleUser
        }
}

##Export-ModuleMember -Function "New-ADCheck"
