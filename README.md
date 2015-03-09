# diego-windows-msi

## Testing

go get github.com/onsi/ginkgo/ginkgo
go get github.com/onsi/gomega
go install github.com/coreos/etcd
export GOROOT=
export GOPATH=$PWD
export PATH=$GOPATH/bin:$PATH
ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows
ginkgo -r -noColor src/github.com/cloudfoundry-incubator/executor
ginkgo -r -noColor src/github.com/cloudfoundry-incubator/rep

pushd src/github.com/cloudfoundry-incubator/containerizer
curl https://api.nuget.org/downloads/nuget.exe -o nuget.exe
nuget restore
/c/Windows/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe Containerizer.sln
packages/nspec.0.9.68/tools/NSpecRunner.exe Containerizer.Tests/bin/Debug/Containerizer.Tests.dll
popd

pushd src/github.com/pivotal-cf-experimental/nora
curl https://api.nuget.org/downloads/nuget.exe -o nuget.exe
nuget restore
/c/Windows/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe Nora.sln
packages/nspec.0.9.68/tools/NSpecRunner.exe Nora.Tests/bin/Debug/Nora.Tests.dll
popd

pushd src/github.com/cloudfoundry-incubator/windows_app_lifecycle
curl https://api.nuget.org/downloads/nuget.exe -o nuget.exe
nuget restore
/c/Windows/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe WindowsCircus.sln
packages/nspec.0.9.68/tools/NSpecRunner.exe Builder.Tests/bin/Debug/BuilderTests.dll
packages/nspec.0.9.68/tools/NSpecRunner.exe Launcher.Tests/bin/Debug/LauncherTests.dll
packages/nspec.0.9.68/tools/NSpecRunner.exe WebAppServer.Tests/bin/Debug/WebAppServer.Tests.dll
popd
