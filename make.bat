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

go get github.com/onsi/ginkgo/ginkgo || exit /b
go get github.com/onsi/gomega || exit /b
go install github.com/coreos/etcd || exit /b
:: ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows || exit /b
:: ginkgo -r -noColor src/github.com/cloudfoundry-incubator/executor || exit /b
:: ginkgo -r -noColor src/github.com/cloudfoundry-incubator/rep || exit /b


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
bsdtar -cvzf windows_app_lifecycle.tgz -n -C Builder/bin/Release . -C ../../../Launcher/bin/Release . -C ../../../Healthcheck/bin/Release . -C ../../../WebAppServer/bin/Release .|| exit /b
copy windows_app_lifecycle.tgz ..\..\..\..\output || exit /b
popd || exit /b
