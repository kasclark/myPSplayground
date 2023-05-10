# Purpose: Audit a Windows system, by executing a series of checks and saving the results to a file
# Usage: .\auditWindows.ps1
# If you're unable to execute, try 'Set-ExecutionPolicy -ExecutionPolicy remotesigned -Scope Process' from the PS command line first

# Import all teh things
# ...

# User defined variables **UPDATE THESE FOR YOUR SCENARIO**
$requiredSoftware = @("carbon", "tanium", "tripwire", "sentinel", "cohesity", "puppet", "nessus") # List of software that to check for (tip: keep the strings short to avoid errors when they don't match exactly e.g., excel rather than Microsoft Excel)
$printToConsole = 1 # Change to '0' to disable console output.
$eventCollectorAccount = "eventCollectorServiceAccount" # Change to the account that can pull event logs

# Prepare the output
$auditResults = @() # Array of results (test, result)

##################### STEP 1: REQUIRED SOFTWARE #####################
if ($printToConsole){Write-Host "`n========== STEP 1: Checking required software... ==========`n"}

# Gather list of installed software
$installedSoftware = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName

# Check whether certain software is installed
foreach ($rs in $requiredSoftware) {
    $testResult = New-Object System.Object
    $testResult | Add-Member -type NoteProperty -Name "TEST" -Value $rs
    $found = 0
    foreach ($is in $installedSoftware) {
        if ($is -match $rs) {
            if ($printToConsole){Write-Host $is.DisplayName.PadRight(54), "PASS" -ForegroundColor Green}
            $testResult | Add-Member -type NoteProperty -Name "RESULT" -Value "PASS"
            $found = 1
            break
        } 
    }
    if (-not $found) {
        if ($printToConsole){Write-Host $rs.PadRight(54),"FAIL" -ForegroundColor Red}
        $testResult | Add-Member -type NoteProperty -Name "RESULT" -Value "FAIL"
    }
    $auditResults += $testResult
}

##################### STEP 2: REQUIRED SETTINGS #####################
if ($printToConsole){Write-Host "`n========== STEP 2: Checking required settings... ==========`n"}

# Check if password complexity is enabled
$testResult = New-Object System.Object
$testResult | Add-Member -type NoteProperty -Name "TEST" -Value "Password Complexity"
if (Get-ADDefaultDomainPasswordPolicy | select -ExpandProperty ComplexityEnabled) {
    if ($printToConsole){Write-Host "Password complexity".PadRight(54), "PASS" -ForegroundColor Green}
        $testResult | Add-Member -type NoteProperty -Name "RESULT" -Value "PASS"
    } else {
    if ($printToConsole){Write-Host "Password complexity".PadRight(54), "FAIL" -ForegroundColor Red}
        $testResult | Add-Member -type NoteProperty -Name "RESULT" -Value "FAIL"
}
$auditResults += $testResult

# Check audit policy
# unsuccessful login attempts are being logged?
# No idea how to do this... 
# how about pull entire default domain policy into xml and parse it?
# Get-GPOReport -name "Default Domain Policy" -ReportType xml -Path "gporeport.xml"

# Check WEC configuration
# What exactly?
# just an idea... get the local group 'event log readers' and see if it's empty or if the correct account is listed
$eventLogReaders = Get-LocalGroupMember -Group "Event Log Readers"
$testResult = New-Object System.Object
$testResult | Add-Member -type NoteProperty -Name "TEST" -Value "WEC"
$found = 0
foreach ($elr in $eventLogReaders) {
    if ($elr -match $eventCollectorAccount) {
        $found = 1 
        if ($printToConsole){Write-Host $eventCollectorAccount.PadRight(54), "PASS" -ForegroundColor Green}
        break
    } 
}
if (-not $found) {
    if ($printToConsole){Write-Host $eventCollectorAccount.PadRight(54), "FAIL" -ForegroundColor Red}
    $testResult | Add-Member -type NoteProperty -Name "RESULT" -Value "FAIL"
}
$auditResults += $testResult

# enforce authentication of interactive user access

##################### STEP 3: MISCELLANEOUS #####################
if ($printToConsole){Write-Host "`n============ STEP 3: Miscellaneous settings... ============`n"}

# Check console of various things to see if they are reporting in correctly to the SIEM, AV, Nessus, Cohesity, etc.


## Save output to a file named 'audit-results-[date].csv'
$auditResults | export-csv -Path .\audit-restults-$(get-date -f yyyy-MM-dd).csv -NoTypeInformation