param (
    [string]$Listener = "demolisten"  # Update with your AG listener name
)

# Ensure Listener is provided
if (-not $Listener) {
    Write-Error "Listener parameter is required."
    exit 1  # Exit with an error code
}

# Query to determine if the instance connected via Listener is the Primary Replica
$SqlCmd = "
    SELECT CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM sys.dm_hadr_availability_replica_states
            WHERE is_local = 1 AND role_desc = 'PRIMARY'
        ) 
    THEN 'PRIMARY' ELSE 'SECONDARY' END AS ReplicaRole;
"

try {
    $Result = Invoke-Sqlcmd -ServerInstance $Listener -Database master -Query $SqlCmd -TrustServerCertificate -ErrorAction Stop

    if ($Result.ReplicaRole -eq 'PRIMARY') {
        Write-Host "$Listener is connected to the PRIMARY replica." -ForegroundColor Green
        exit 0  # Exit with success
    } else {
        Write-Host "$Listener is connected to a SECONDARY replica." -ForegroundColor Yellow
        exit 1  # Exit with failure (prevents login sync if running in SQL Agent job)
    }
} catch {
    Write-Error "Error checking replica role on ${Listener}: $_"
    exit 1  # Exit with failure if an error occurs
}
