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
git checkout $CF_SHA
cd ../diego-release
git checkout $DIEGO_SHA
cd ../diego-windows-msi
git checkout $DWM_SHA
cd ../

git config --global user.name "CI (Automated)"
git config --global user.email "greenhouse@pivotal.io"
git checkout master
git commit -m "DiegoWindowsMSI Release v$MSI_VERSION" cf-release diego-release diego-windows-msi
