# Given an email adddress, look up the user name in AD.


foreach($line in Get-Content $args[0]) {
    if($line -match $regex){
        $name=$(Get-ADUser -filter {Emailaddress -eq $line} | Select-Object -ExpandProperty Name)
        Write-Output "$line $name"
    }
}
