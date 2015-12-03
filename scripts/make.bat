@echo on

rmdir /S /Q output
mkdir output
SET DEVENV_PATH=%programfiles(x86)%\Microsoft Visual Studio 12.0\Common7\IDE
SET PATH=%GOROOT%;%PATH%;%DEVENV_PATH%

for /f "tokens=*" %%a in ('git rev-parse HEAD') do (
    set VERSION=%%a
)
IF DEFINED APPVEYOR_BUILD_VERSION (SET VERSION=%APPVEYOR_BUILD_VERSION%-%VERSION%)

:: Visual Studio must be in path
where devenv
if errorLevel 1 ( echo "devenv was not found on PATH")

:: https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d
REGEDIT.EXE  /S  "%~dp0\fix_visual_studio_building_msi.reg" || exit /b 1

SET GOBIN=%CD%\bin
SET PATH=%GOBIN%;%PATH%
pushd greenhouse-install-script-generator || exit /b 1
  SET GOPATH=%CD%
  go install github.com/onsi/ginkgo/ginkgo || exit /b 1
  ginkgo -r -noColor src\integration || exit /b 1
  cd src\generate
  go install || exit /b 1
popd
echo F | xcopy bin\generate.exe output\generate-%VERSION%.exe || exit /b 1

pushd hakim || exit /b 1
  SET GOPATH=%CD%\vendor;%CD%
  ginkgo -r -noColor src\ || exit /b 1
  go install hakim || exit /b 1
popd
echo F | xcopy bin\hakim.exe output\hakim-%VERSION%.exe || exit /b 1

SET GOBIN=%CD%\DiegoWindowsRelease\DiegoWindowsMSI\go-executables
:: Install metron, it contains all relevant gocode inside itself.
pushd loggregator || exit /b 1
  SET GOPATH=%CD%
  ginkgo -r -noColor src\metron || exit /b 1
  go install metron || exit /b 1
popd

pushd diego-release || exit /b 1
  SET GOPATH=%CD%
  :: windows cmd doesn't like quoting arguments, use -skip=foo.bar
  :: instead of -skip='foo bar'
  ginkgo -r -noColor src/github.com/cloudfoundry-incubator/executor || exit /b 1
  ginkgo -noColor src/github.com/cloudfoundry-incubator/rep || exit /b 1

  go install github.com/cloudfoundry-incubator/rep/cmd/rep || exit /b 1
popd

:: consul.exe is checked in, download from https://www.consul.io/downloads.html
copy bin\consul.exe %GOBIN%

pushd DiegoWindowsRelease || exit /b 1
  rmdir /S /Q packages
  nuget restore || exit /b 1
  echo SHA: %VERSION% > RELEASE_SHA
  devenv DiegoWindowsMSI\DiegoWindowsMSI.vdproj /build "Release" || exit /b 1
  xcopy DiegoWindowsMSI\Release\DiegoWindows.msi ..\output\ || exit /b 1
popd
move /Y output\DiegoWindows.msi output\DiegoWindows-%VERSION%.msi || exit /b 1

:: running the following command without the echo part will prompt
:: the user to specify whether the destination is a directory (D) or
:: file (F). we echo F to select file.
echo F | xcopy docs\INSTALL.md output\INSTALL-%VERSION%.md || exit /b 1
echo F | xcopy cloudformation.json.template output\cloudformation-%VERSION%.json.template || exit /b 1
