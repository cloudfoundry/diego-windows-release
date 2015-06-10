:: diego-windows-msi

:: Consul agent is in bin/consul.exe

:: Testing

rmdir /S /Q output
mkdir output
::SET GOROOT= C:\Go
SET GOBIN=%CD%\bin
SET DEVENV_PATH=%programfiles(x86)%\Microsoft Visual Studio 12.0\Common7\IDE
SET PATH=%GOBIN%;%GOROOT%;%PATH%;%DEVENV_PATH%
:: TODO: get rid of godeps
SET GOPATH=%CD%
SET CONTAINERIZER_BIN=%CD%\src\\github.com\cloudfoundry-incubator\garden-windows\containerizer\Containerizer\bin\Containerizer.exe

:: Visual Studio must be in path
where devenv
if errorLevel 1 ( echo "devenv was not found on PATH")

:: https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d
REGEDIT.EXE  /S  "%~dp0\fix_visual_studio_building_msi.reg" || exit /b 1

:: install the binaries in %GOBIN%
go install github.com/coreos/etcd || exit /b 1
go install github.com/onsi/ginkgo/ginkgo || exit /b 1
go install github.com/onsi/gomega || exit /b 1

SET GOBIN=%CD%\DiegoWindowsMSI\DiegoWindowsMSI\go-executables

:: Install metron, it contains all relevant gocode inside itself.
pushd src\github.com\cloudfoundry\loggregator || exit /b 1
  SET OLD_GOPATH=%GOPATH%
  SET GOPATH=%CD%
  go install metron || exit /b 1
  SET GOPATH=%OLD_GOPATH%
popd

:: Install the garden-windows, rep and executor in the MSI go-executables directory
go install github.com/cloudfoundry-incubator/garden-windows || exit /b 1
go install github.com/cloudfoundry-incubator/executor/cmd/executor || exit /b 1
go install github.com/cloudfoundry-incubator/rep/cmd/rep || exit /b 1
copy bin\consul.exe %GOBIN%

pushd src\github.com\cloudfoundry-incubator\garden-windows\containerizer || exit /b 1
  call make.bat || exit /b 1
popd

:: Run the tests

ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows || exit /b 1
:: windows cmd doesn't like quoting arguments, use -skip=foo.bar instead of -skip='foo bar'
:: we use the dot operator to match anything, -skip expects a regex
ginkgo -skip=reports.garden.containers.as.-1  -r -noColor src/github.com/cloudfoundry-incubator/executor || exit /b 1
ginkgo -skip=when.an.interrupt.signal.is.sent.to.the.representative^|should.not.exit,.but.keep.trying.to.maintain.presence.at.the.same.ID^|The.Rep.Evacuation.when.it.has.running.LRP.containers^|when.a.Ping.request.comes.in -noColor src/github.com/cloudfoundry-incubator/rep || exit /b 1


for /f "tokens=*" %%a in ('git rev-parse --short HEAD') do (
    set VERSION=%%a
)

pushd DiegoWindowsMSI || exit /b 1
  rmdir /S /Q packages
  nuget restore || exit /b 1
  echo SHA: %VERSION% > RELEASE_SHA
  devenv DiegoWindowsMSI\DiegoWindowsMSI.vdproj /build "Release" || exit /b 1
  xcopy DiegoWindowsMSI\Release\DiegoWindowsMSI.msi ..\output\ || exit /b 1
popd

IF DEFINED APPVEYOR_BUILD_VERSION (SET VERSION=%APPVEYOR_BUILD_VERSION%-%VERSION%)

move /Y output\DiegoWindowsMSI.msi output\DiegoWindowsMSI-%VERSION%.msi || exit /b 1
:: running the following command without the echo part will prompt
:: the user to specify whether the destination is a directory (D) or
:: file (F). we echo F to select file.
echo F | xcopy docs\INSTALL.md output\INSTALL-%VERSION%.md || exit /b 1
echo F | xcopy scripts\setup.ps1 output\setup-%VERSION%.ps1 || exit /b 1
pushd src\github.com\cloudfoundry-incubator\windows_app_lifecycle || exit /b 1
  call make.bat || exit /b 1
  xcopy windows_app_lifecycle-*.tgz ..\..\..\..\output\ || exit /b 1
popd
