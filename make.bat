:: diego-windows-msi

:: Consul agent is in bin/consul.exe

:: Testing

:: Msbuild must be in path

del /F /Q output\*
::SET GOROOT= C:\Go
SET GOPATH=%CD%;%CD%\src\github.com\cloudfoundry-incubator\garden-windows\Godeps\_workspace
SET GOBIN=%CD%\bin
SET PATH=%GOBIN%;%GOROOT%;%PATH%

:: https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d
REGEDIT.EXE  /S  "%~dp0\fix_visual_studio_building_msi.reg"

:: install the binaries in %GOBIN%
go install github.com/coreos/etcd || exit /b 1
go install github.com/onsi/ginkgo/ginkgo || exit /b 1
go install github.com/onsi/gomega || exit /b 1
:: Run the tests

ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows || exit /b 1
:: windows cmd doesn't like quoting arguments, use -skip=foo.bar instead of -skip='foo bar'
:: we use the dot operator to match anything, -skip expects a regex
ginkgo -skip=transition.to.running -r -noColor src/github.com/cloudfoundry-incubator/executor || exit /b 1
ginkgo -skip=when.an.interrupt.signal.is.sent.to.the.representative^|should.not.exit,.but.keep.trying.to.maintain.presence.at.the.same.ID^|The.Rep.Evacuation.when.it.has.running.LRP.containers^|when.a.Ping.request.comes.in -noColor src/github.com/cloudfoundry-incubator/rep || exit /b 1

:: Install the garden-windows, rep and executor in the MSI go-executables directory
SET GOBIN=%CD%\src\github.com\cloudfoundry-incubator\containerizer\DiegoWindowsMSI\go-executables
go install github.com/cloudfoundry-incubator/garden-windows || exit /b 1
go install github.com/cloudfoundry-incubator/executor/cmd/executor || exit /b 1
go install github.com/cloudfoundry-incubator/rep/cmd/rep || exit /b 1
copy bin\consul.exe %GOBIN%

pushd src\github.com\cloudfoundry-incubator\containerizer || exit /b 1
	nuget restore || exit /b 1
	devenv Containerizer\Containerizer.csproj /build "Release" || exit /b 1
	devenv Containerizer.Tests\Containerizer.Tests.csproj /build "Release" || exit /b 1
	packages\nspec.0.9.68\tools\NSpecRunner.exe Containerizer.Tests\bin\Release\Containerizer.Tests.dll || exit /b 1
	devenv DiegoWindowsMSI\DiegoWindowsMSI.vdproj /build "Release" || exit /b 1
	xcopy DiegoWindowsMSI\Release\DiegoWindowsMSI.msi ..\..\..\..\output\ || exit /b 1
popd || exit /b 1

pushd src\github.com\pivotal-cf-experimental\nora || exit /b 1
	nuget restore || exit /b 1
	devenv Nora.sln /build "Release" || exit /b 1
	packages\nspec.0.9.68\tools\NSpecRunner.exe Nora.Tests\bin\Release\Nora.Tests.dll || exit /b 1
popd || exit /b 1

pushd src\github.com\cloudfoundry-incubator\windows_app_lifecycle || exit /b 1
	nuget restore || exit /b 1
	devenv WindowsCircus.sln /build "Release" || exit /b 1
	packages\nspec.0.9.68\tools\NSpecRunner.exe Builder.Tests\bin\Release\BuilderTests.dll || exit /b 1
	packages\nspec.0.9.68\tools\NSpecRunner.exe Launcher.Tests\bin\Release\LauncherTests.dll || exit /b 1
	packages\nspec.0.9.68\tools\NSpecRunner.exe WebAppServer.Tests\bin\Release\WebAppServer.Tests.dll || exit /b 1
	bsdtar -czvf windows_app_lifecycle.tgz -C Builder\bin . -C ..\..\Launcher\bin . -C ..\..\Healthcheck\bin . -C ..\..\WebAppServer\bin . || exit /b 1
	xcopy windows_app_lifecycle.tgz ..\..\..\output\ || exit /b 1
popd || exit /b 1

