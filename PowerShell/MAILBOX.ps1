$SH = Get-Mailbox -RecipientTypeDetails SharedMailbox
$s =""
$group = $null
foreach ($mailbox in $SH){
    Write-Host "$(($mailbox).name)-hoz tartozó SendAs jogok" -ForegroundColor DarkMagenta
    Write-Host ""

    $Muser = Get-ADUser ($mailbox).name
    $SendAs = (Get-Acl -Path "AD:$($Muser.distinguishedname)").Access | where{($_.ActiveDirectoryRights -like "*ExtendedRight*") -and ($_.IsInherited -like "*false*") -and ($_.ObjectType -eq "ab721a54-1e2f-11d0-9819-00aa0040529b") -and ($_.IdentityReference -like "ONEICT\*")}
   [string[]]$osszk = $null

    $SendAs | %{
    
        $kolcseghely = (Get-ADUser -Identity ($_).IdentityReference.toString().split("\")[1] -Properties department).department
        #Write-host $kolcseghely

        [string[]]$osszk += $kolcseghely
        
    }
    
  $group +=  $osszk | Group-Object -NoElement | %{
        [PSCustomObject]@{        'Name' = $_.Name        'Count'  = $_.Count        'Mailbox'  = $(($mailbox).name)        }
     
     }
   
}

$group | Out-GridView -PassThru

