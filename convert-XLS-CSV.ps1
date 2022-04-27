# this script takes an Excel doc exported from [SOME CRAPPY TOOL] and reformats it for convenience
# if you're unable to execute, try 'Set-ExecutionPolicy -ExecutionPolicy remotesigned -Scope Process' from the PS command line first

# import all the things
Import-Module -Name ImportExcel -Force

# check for arguments
if ($args.Count -eq 0) {
    write-host "Please supply the name of the input file."
    write-host "Example usage: .\convert-XLS-CSV.ps1 '.\Report.xlsx'"
    Exit
}

# open the input file
$path = Get-Location
$file = $args[0]
$filepath = $path.ToString()+$file  
$xl = New-Object -ComObject Excel.Application
$wb = $xl.Workbooks.Open($filepath,2,$true)
$ws = $wb.Sheets.Item(1)

# input data into array
$data = New-Object System.Collections.ArrayList
$r = 1
while(1) {
    $cell = $ws.Cells.Item($r,1).Text
    if($cell -eq "") {
        break
    } elseif ($cell -eq "Node Names : ") {
        break
    } else {
        $data.Add($cell) > $null
        $r++
    }
}

# build a well-formatted object
$myArray = @()
$myObject = New-Object System.Object

# this will need to be customized based on the input data, but as an example: 
foreach ($item in $data) {
    if ($item -clike "Node Name:*") {
        $myObject | Add-Member -type NoteProperty -Name "Node Name" -Value $item.split(":")[-1]
    } elseif  ($item -clike "Username:*") {
        $myObject | Add-Member -type NoteProperty -Name "Username" -Value $item.split(":")[-1]
    } elseif ($item -clike "Status:*") {
        $myObject | Add-Member -type NoteProperty -Name "Status" -Value $item.split(":")[-1]
    } elseif ($item -clike "Password Age:*") {
        $myObject | Add-Member -type NoteProperty -Name "Password Age" -Value $item.split(":")[-1]
    } elseif ($item -clike "Allowed Password Age:*") {
        $myObject | Add-Member -type NoteProperty -Name "Allowed Password Age" -Value $item.split(":")[-1]
        $myArray += $myObject
        $myObject = New-Object System.Object
    }
}

# output that sweet, sweet data
$myArray | export-csv -Path .\tripwire-info.csv -NoTypeInformation

# clean up
$wb.Close()
$xl.Quit()
