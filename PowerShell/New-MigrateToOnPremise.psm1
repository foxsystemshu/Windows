$END_PONIT = "" # endpoint domain név
$CSV_FILE = "" #fájl elérési útja
$DB_REGEX = "" #mailbox DB név regex pl 'DB_*'
$global:ActualDeliveryDomain = ""

#### DeliveryDomain-t kezelő funkció ####
## Feladata ##
## Meghatározni a kézbesítési tartományt az adott fájból, mindig a listában az első mailbox cím a meghatározó, ezt veszi alapul##

function getDeliveryDomain{
    $raw_content = Get-Content $CSV_FILE
    $DD = $raw_content[1].Split("@")[1].Trim()
    for ($i = 1; $i -lt $raw_content.Count; $i++) {           
            $ADD = $raw_content[$i].Split("@")[1].Trim()
            
            if($DD -ne $ADD){
                Write-Host "A rendszer csak egységes DeliveryDomain-t tud kezelni egyszerre, a $($raw_content[$i]) nem egyezik. A listában az első mailbox cím a mérvadó!"
                Write-Host "Kilépek...!"
                return $false
            }
    }
    $global:ActualDeliveryDomain = $DD
    return $true
}

####Migrációt megvalósító funkció ####
### Feladata: ###
## Létrehozni a kapcsolatot az EXO session-nel, majd elindítani a kapot paraméterek alapján a migrációt
## A felhasználók a $CSV_FILE-ban eltárolt, rögzitett helyen lévő report file alapján migrálódnak 
#FONTOS:  Ahhoz, hogy ne kapjunk hibát a session létrehozásakor, fel kell tenni az Exchange Online modult.  
function Migrate {
    param (
        $name,$DeliveryDomain,$db=1,$days
    )
    $getsessions = Get-PSSession | Select-Object -Property State, Name
    $isconnected = (@($getsessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
    If ($isconnected -ne "True") {
        Connect-ExchangeOnline
        Write-Host "Nem volt csatlakozva az EXCHANGE ONLINE szolgáltatáshoz, próbálja újra futtatni a parancsot!"
    }else{
        if($db -ne 0){
            New-MigrationBatch -Name $name -TargetDatabases @($db) -AutoComplete -TargetDeliveryDomain $DeliveryDomain -TargetEndpoint $END_PONIT -TimeZone "Central Europe Standard Time" -StartAfter (Get-date).AddDays($days) -CSVData ([System.IO.File]::ReadAllBytes($CSV_FILE)) 
        }else{
            New-MigrationBatch -Name $name -TargetDatabases @($db) -AutoComplete -TargetDeliveryDomain $DeliveryDomain -TargetEndpoint $END_PONIT -TimeZone "Central Europe Standard Time" -AutoStart -CSVData ([System.IO.File]::ReadAllBytes($CSV_FILE)) 
        }    
    }
}

###### Adatbázis választó funkció #####
### Feladata: ###
## Kiválasztani a legtöbb szabad helyet tartalmazó Mailbox adatbázist,
## és átadja visszatérési értékként a kiválasztott DB nevet.
#ToDO:  Ha a mailbox nagyobb mint az aktuális DB kóta, akkor azt nővelni kell itt.
function DatabaseChoice {
   $activeDBs = @()
    $dbs = Get-MailboxDatabase  -status | Select-Object Name,AvailableNewMailboxSpace,DatabaseSize,Mounted

    foreach($db in $dbs){
        if($db.Mounted -eq $true -and $db.name -like $DB_REGEX){
           $activeDBs += $db      
        }
    }

    [int]$max = ($activeDBs | measure-object -Property AvailableNewMailboxSpace -Maximum ).Maximum.Split(" ")[0].Trim()
    foreach ($item in $activeDBs) {
        [int]$i = $item.AvailableNewMailboxSpace.Split(" ")[0].Trim()
       if($i -eq $max){
           $choice = $item
       }
    }
   Write-Host $choice.name  $choice.AvailableNewMailboxSpace

return $choice.name
}

function New-MigToOnPremise{
    param($BatchName, $days,$db)
    
    if($null -ne $db){
        $dbname = $db
    }else{
        $dbname =  DatabaseChoice
    }
    
        if(getDeliveryDomain){
            Migrate -name $BatchName -DeliveryDomain $global:ActualDeliveryDomain -db $dbname -days $days
            return $true
        }else{
            return $false
        }
}
 

Export-ModuleMember -Function 'New-MigToOnPremise'



   
