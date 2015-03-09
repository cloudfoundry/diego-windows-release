# diego-windows-msi

## Testing

1. go get github.com/onsi/ginkgo/ginkgo
1. go get github.com/onsi/gomega
1. go install github.com/coreos/etcd
1. export GOROOT=
1. export GOPATH=$PWD
1. export PATH=$GOPATH/bin:$PATH
1. ginkgo -r -noColor src/github.com/cloudfoundry-incubator/garden-windows
1. ginkgo -r -noColor src/github.com/cloudfoundry-incubator/executor
1. ginkgo -r -noColor src/github.com/cloudfoundry-incubator/rep

1. cd src\github.com\cloudfoundry-incubator\containerizer
1. curl https://api.nuget.org/downloads/nuget.exe -o nuget.exe
1. nuget restore
1. msbuild Containerizer.sln
1. packages\nspec.0.9.68\tools\NSpecRunner.exe Containerizer.Tests\bin\Debug\Containerizer.Tests.dll
