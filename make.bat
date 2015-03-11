:: diego-windows-msi

:: Consul agent is in bin/consul.exe

:: Testing

:: Msbuild must be in path

del /F /Q output\*
::SET GOROOT= C:\Go
SET GOPATH=%CD%
SET PATH=%GOPATH%/bin;%GOROOT%;%PATH%

:: https://visualstudiogallery.msdn.microsoft.com/9abe329c-9bba-44a1-be59-0fbf6151054d
REGEDIT.EXE  /S  "%~dp0\fix_visual_studio_building_msi.reg"

:: install the binaries in %GOBIN%
go get github.com/tools/godep
pushd src\github.com\cloudfoundry-incubator\garden-windows || exit /b
	godep restore || exit /b
popd || exit /b
go install github.com/coreos/etcd || exit /b

:: Run the tests

ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows || exit /b
:: windows cmd doesn't like quoting arguments, use -skip=foo.bar instead of -skip='foo bar'
:: we use the dot operator to match anything, -skip expects a regex
ginkgo -skip=transition.to.running -r -noColor src/github.com/cloudfoundry-incubator/executor || exit /b
ginkgo -skip=when.an.interrupt.signal.is.sent.to.the.representative^|should.not.exit,.but.keep.trying.to.maintain.presence.at.the.same.ID^|The.Rep.Evacuation.when.it.has.running.LRP.containers^|when.a.Ping.request.comes.in -noColor src/github.com/cloudfoundry-incubator/rep || exit /b

:: Install the garden-windows, rep and executor in the MSI go-executables directory
SET GOBIN=%CD%\src\github.com\cloudfoundry-incubator\containerizer\DiegoWindowsMSI\go-executables
go install github.com/cloudfoundry-incubator/garden-windows
go install github.com/cloudfoundry-incubator/executor/cmd/executor
go install github.com/cloudfoundry-incubator/rep/cmd/rep

pushd src\github.com\cloudfoundry-incubator\containerizer || exit /b
	nuget restore || exit /b
	devenv Containerizer\Containerizer.csproj /build "Release" || exit /b
	devenv Containerizer.Tests\Containerizer.Tests.csproj /build "Release" || exit /b
	packages\nspec.0.9.68\tools\NSpecRunner.exe Containerizer.Tests\bin\Debug\Containerizer.Tests.dll || exit /b
	devenv DiegoWindowsMSI\DiegoWindowsMSI.vdproj /build "Release" || exit /b
	copy DiegoWindowsMSI\Release\DiegoWindowsMSI.msi ..\..\..\..\output || exit /b
popd || exit /b

pushd src\github.com\pivotal-cf-experimental\nora || exit /b
	nuget restore || exit /b
	msbuild Nora.sln || exit /b
	packages\nspec.0.9.68\tools\NSpecRunner.exe Nora.Tests\bin\Debug\Nora.Tests.dll || exit /b
popd || exit /b

pushd src\github.com\cloudfoundry-incubator\windows_app_lifecycle || exit /b
	nuget restore || exit /b
	devenv WindowsCircus.sln /build "Release" || exit /b
	packages\nspec.0.9.68\tools\NSpecRunner.exe Builder.Tests\bin\Debug\BuilderTests.dll || exit /b
	packages\nspec.0.9.68\tools\NSpecRunner.exe Launcher.Tests\bin\Debug\LauncherTests.dll || exit /b
	packages\nspec.0.9.68\tools\NSpecRunner.exe WebAppServer.Tests\bin\Debug\WebAppServer.Tests.dll || exit /b
	bsdtar -czvf windows_app_lifecycle.tgz -C Builder\bin\Release . -C ..\..\..\Launcher\bin\Release . -C ..\..\..\Healthcheck\bin\Release . -C ..\..\..\WebAppServer\bin\Release .|| exit \b
	copy windows_app_lifecycle.tgz ..\..\..\..\output || exit /b
popd || exit /b

