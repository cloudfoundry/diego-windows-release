$username=$env:GOCD_USERNAME
$password=$env:GOCD_PASSWORD
$uri=$env:URI
$commit=$env:APPVEYOR_REPO_COMMIT
$base64AuthInfo=[Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}"-f$username,$password)))
Invoke-RestMethod -Headers @{Authorization=("Basic {0}"-f$base64AuthInfo)} -Method Post -Uri $uri -Body @{"materials[diego-windows-msi]" =$commit}
