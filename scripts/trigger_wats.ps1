$username=$env:USERNAME
$password=$env:PASSWORD
$uri=$env:URI
$base64AuthInfo=[Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}"-f$username,$password)))
Invoke-RestMethod -Headers @{Authorization=("Basic {0}"-f$base64AuthInfo)} -Method Post -Uri $uri
