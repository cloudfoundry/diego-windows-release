#!/usr/bin/env bash

chruby 2.1.2
gem install bundler --no-rdoc --no-ri
export BUNDLE_GEMFILE=$(dirname $0)/Gemfile
bundle
bundle exec $(dirname $0)/deploy_msi.rb
