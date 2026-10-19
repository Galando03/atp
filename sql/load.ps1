# Load ATP CSVs into staging tables.
# Set your password first:  $env:PGPASSWORD = "..."

$env:PGPASSWORD = ""

psql -U postgres -d tennis -c "TRUNCATE stg_players, stg_rankings, stg_matches;"

$DATA = "C:/Users/enric/projects/atp-sql/sackman/atp"

Get-ChildItem "$DATA\atp_rankings_*.csv" | ForEach-Object {
   $p = $_.FullName -replace '\\','/'                                                                                            
   Write-Host "Loading $($_.Name)"                                                                                               
   psql -U postgres -d tennis -c "\copy stg_rankings FROM '$p' WITH (FORMAT csv, HEADER true)"
}

Get-ChildItem "$DATA\atp_matches_????.csv" | ForEach-Object {
   $p = $_.FullName -replace '\\','/'                                                                                            
   Write-Host "Loading $($_.Name)"                                                                               
   psql -U postgres -d tennis -c "\copy stg_matches FROM '$p' WITH (FORMAT csv, HEADER true)"
} 

psql -U postgres -d tennis -c "\copy stg_players FROM '$DATA/atp_players.csv' WITH (FORMAT csv, HEADER true)"