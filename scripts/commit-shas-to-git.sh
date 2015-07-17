#!/usr/bin/env sh
set -ex

CF_SHA=`(cd cf-release && git rev-parse HEAD)`
DIEGO_SHA=`(cd diego-release && git rev-parse HEAD)`
DWM_SHA=`(cd diego-windows-msi && git rev-parse HEAD)`
MSI_VERSION=`cat ./msi-file/version`
echo $CF_SHA
echo $DIEGO_SHA
echo $DWM_SHA
echo $MSI_VERSION

cd cf-diego-dwm-locker
cd cf-release
git co $CF_SHA
cd ../diego-release
git co $DIEGO_SHA
cd ../diego-windows-msi
git co $DWM_SHA
cd ../

git ci -m "DiegoWindowsMSI Release v$MSI_VERSION" cf-release diego-release diego-windows-msi
git push origin master
