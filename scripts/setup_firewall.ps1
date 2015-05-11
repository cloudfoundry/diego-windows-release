$admins = New-Object System.Security.Principal.NTAccount("Administrators")
$adminsSid = $admins.Translate([System.Security.Principal.SecurityIdentifier])

$currentUser = New-Object System.Security.Principal.NTAccount($env:username)
$currentUserSid = $currentUser.Translate([System.Security.Principal.SecurityIdentifier])

New-NetFirewallRule -Name "AllowAdmins" -DisplayName "Allow admins" `
  -Description "Allow admin users" -RemotePort Any `
  -LocalPort Any -LocalAddress Any -RemoteAddress Any `
  -Enabled True -Profile Any -Action Allow -Direction Outbound `
  -LocalUser "D:(A;;CC;;;$adminsSid) (A;;CC;;;$currentUserSid)"

set-netfirewallprofile -all -DefaultInboundAction Allow -DefaultOutboundAction Block
