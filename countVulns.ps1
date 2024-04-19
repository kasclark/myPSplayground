param (
    [string]$csvFilePath
)

# Import the CSV file
$data = Import-Csv -Path $csvFilePath

# Initialize counters
$critical = 0
$high = 0

# Loop through each row in the CSV
foreach ($row in $data) {
    # Get the "Vulnerability Risk Score" value
    $score = [int]$row.'Vulnerability Risk Score'

    # Check the score and increment the appropriate counter
    if ($score -gt 849) {
        $critical++
    } elseif ($score -gt 649 -and $score -le 850) {
        $high++
    }
}

# Output the counts
Write-Output "Number of criticals: $critical"
Write-Output "Number highs: $high"
