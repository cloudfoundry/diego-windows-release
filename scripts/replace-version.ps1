$productcode = [guid]::NewGuid().ToString().ToUpper()
$packagecode = [guid]::NewGuid().ToString().ToUpper()
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
push-location $dir
  $oldversion = """ProductVersion"" = ""8:1.0.0"""
  $version = """ProductVersion"" = ""8:$env:APPVEYOR_BUILD_VERSION"""
  $oldproductcode = """ProductCode"" = ""8:{48F8F0E2-6555-4500-8868-C9F8FD9394F2}"""
  $productcode = """ProductCode"" = ""8:{$productcode}"""
  $oldpackagecode = """PackageCode"" = ""8:{E5C8395D-FB02-4615-9865-0BBECC3076D6}"""
  $packagecode = """PackageCode"" = ""8:{$packagecode}"""
  $oldsubject = """Subject"" = ""8:"""
  $subject = """Subject"" = ""8:DiegoWindows-$env:APPVEYOR_BUILD_VERSION-$env:APPVEYOR_REPO_COMMIT"""
  (get-content ..\DiegoWindowsRelease\DiegoWindowsMSI\DiegoWindowsMSI.vdproj).replace("$oldversion","$version").replace("$oldproductcode", "$productcode").replace("$oldpackagecode", "$packagecode").replace("$oldsubject", "$subject") | set-content ..\DiegoWindowsRelease\DiegoWindowsMSI\DiegoWindowsMSI.vdproj
pop-location
