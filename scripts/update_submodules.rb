#!/usr/bin/env ruby

# curdir = `pwd`
# puts durir
modules = Dir.chdir('/Users/pivotal/workspace/diego-release') do
  `git submodule status --recursive`
end
modules.split(/\n/).each do |line|
  a = line.split(/\s+/)
  sha = a[1]
  dir = a[2]
  puts dir

  if Dir.exists?(dir)
    puts "\t#{sha}"
    Dir.chdir(dir) do
      `git fetch && git co #{sha}`
    end
  end
end
