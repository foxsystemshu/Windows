$FILE="" #File path
$DEP="" #Department name
$GROUP="" #Add users to this group

$users = Get-Content -Path $FILE

foreach($value in $users){
    $User = Get-ADUser -Identity $value -Properties department
    $User.department = $DEP
    Set-ADUser -Instance $User

    #comment out the line below when need to add users to same group
    #Add-ADGroupMember -Identity $GROUP -Members $User 
}
    
