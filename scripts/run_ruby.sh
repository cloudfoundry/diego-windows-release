#!/usr/bin/env bash

chruby 2.1.2
export GEM_HOME=~/.gems
export GEM_PATH=$GEM_HOME:$GEM_PATH
export BUNDLE_GEMFILE=$(dirname $0)/Gemfile
gem install bundler --no-rdoc --no-ri
bundle install
ruby_script=$1
shift
bundle exec ${ruby_script} "$@"
