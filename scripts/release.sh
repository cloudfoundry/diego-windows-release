#!/usr/bin/env bash

git tag v0.${GO_PIPELINE_LABEL}
git push --tags origin
