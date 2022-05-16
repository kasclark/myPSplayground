# this script takes an XML doc exported from [SOME CRAPPY TOOL] and reformats it for convenience
# if you're unable to execute, try 'Set-ExecutionPolicy -ExecutionPolicy remotesigned -Scope Process' from the PS command line first

# check for arguments
if ($args.Count -eq 0) {
    write-host "Please supply the name of the input file."
    write-host "Example usage: .\convert-XML-CSV.ps1 '.\Report.xml'"
    Exit
}

# open the input file
$path = Get-Location
$file = $args[0]
$filepath = $path.ToString()+$file  
[xml]$data = Get-Content $filepath

# build a well-formatted object
$myArray = @()
$myObject = New-Object System.Object
$myNode

# this will need to be customized based on the input data, but as an example: 
foreach($item in $data.ReportOutput.ReportBody.ReportSection.ReportSection.ReportSection.ReportSection.ReportSection.String) {
    if ($item.InnerText -clike "Node Name:*") {
        #write-host "node: " $item.InnerText
        $myNode = $item.InnerText.split(":")[-1]
        $myObject | Add-Member -type NoteProperty -Name "Node Name" -Value $myNode
    } elseif ($item.InnerText -clike "*UNAUTHORIZED USER FOUND*") {
        #write-host "unauthorized: " $item.InnerText
        $myObject | Add-Member -type NoteProperty -Name "Warning" -Value "UNAUTHORIZED USER FOUND"
    } elseif ($item.InnerText -clike "*EXPIRED PASSWORD FOUND*") {
        $myObject | Add-Member -type NoteProperty -Name "Warning" -Value "EXPIRED PASSWORD FOUND"
        #write-host "expired: " $item.InnerText
    } elseif ($item.InnerText -clike "Username:*") {
        $myObject | Add-Member -type NoteProperty -Name "Username" -Value $item.InnerText.split(":")[-1]
        #write-host "user: " $item.InnerText
    } elseif ($item.InnerText -clike "Status:*") {
        $myObject | Add-Member -type NoteProperty -Name "Status" -Value $item.InnerText.split(":")[-1]
        #write-host "status: "$item.InnerText
    } elseif ($item.InnerText -clike "Password Age:*") {
        $myObject | Add-Member -type NoteProperty -Name "Password Age" -Value $item.InnerText.split(":")[-1]
        #write-host "password: " $item.InnerText
    } elseif ($item.InnerText -clike "Allowed Password Age:*") {
        $myObject | Add-Member -type NoteProperty -Name "Allowed Password Age" -Value $item.InnerText.split(":")[-1]
        #write-host "age: " $item.InnerText
    } elseif ($item.InnerText -clike "__________________________________________________*" -or $item.InnerText -eq "") {
        #write-host "line or blank: " $item.InnerText

        #if no node specified, that means it's still the same one
        if ("Node Name" -notin $myObject.PSobject.Properties.Name){
            write-host "Node is still: " $myNode
            $myObject | Add-Member -type NoteProperty -Name "Node Name" -Value $myNode
        }
        
        # add the object to the array and create a new one, unless it contains no username
        if ("Username" -in $myObject.PSobject.Properties.Name){
            write-host ($myObject | format-table | out-string)
            $myArray += $myObject
            $myObject = New-Object System.Object
            #start-sleep -s 2   
            write-host ($myArray | format-table | out-string)
            #start-sleep -s 5
        }

    }
}

# output that sweet, sweet data
$myArray | export-csv -Path .\your-info.csv -NoTypeInformation
