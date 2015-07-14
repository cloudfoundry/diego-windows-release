#!/usr/bin/env ruby

require 'octokit'
require 'time'
require 'open-uri'

def env_var var
  ENV[var] or raise "Environment variable #{var} isn't set"
end

def token
  env_var 'GITHUB_TOKEN'
end

def revision
  Dir.chdir(File.dirname(__FILE__)) do
    `git rev-parse HEAD`.chomp
  end
end

def msi_file
  Dir::glob('./msi-file/DiegoWindowsMSI-*-*.msi').first
end

def release
  label = msi_file.match(/DiegoWindowsMSI-(\d+\.\d+)-.*.msi/)[1]
  "v#{label}"
end

def github
  @github ||= Octokit::Client.new :login => 'jvshahid', :access_token => token
end

def repo
  'pivotal-cf/diego-windows-msi'
end

def short_sha
  revision[0..6]
end

def create_github_tag
  puts "Creating release #{release} with sha #{revision}"
  github.create_tag repo,
                    release,
                    "Release #{release}",
                    revision,
                    "commit",
                    "Greenhouse", # tagger name isn't being used by the api
                    "greenhouse@pivotal.io", # tagger email isn't being used by the api
                    Time.now.utc.iso8601

  github.create_release repo,
                        release,
                        name: release,
                        body: "Diego windows MSI Release #{release}"
end

def content_type filename
  if File.extname(filename) == ".md"
    "text/plain"
  else
    "application/octet-stream"
  end
end

def upload_release_assets(filepath, release, filename=nil)
  filename ||= File.basename filepath
  github.upload_asset release[:url],
                      filepath,
                      content_type: content_type(filename),
                      name: filename
end

def download_from_s3 url, destination
  File.open(destination, "wb+") do |f|
    open(url, "rb") do |read_file|
      f.write(read_file.read)
    end
  end
  destination
end

def release_already_created?(release)
  github.releases(repo).any? {|r| r.tag_name == release}
end

if release_already_created?(release)
  puts "Release #{release} already created, skipping"
  exit(0)
end

puts "Creating github release"
res = create_github_tag
puts "Created github release"

puts "Uploading msi to github release"
upload_release_assets msi_file, res, "DiegoWindowsMSI.msi"
puts "Uploaded msi to github release"

puts "Uploading installation instructions to github release"
upload_release_assets "diego-windows-msi/docs/INSTALL.MD", res
puts "Uploaded installation instructions to github release"

puts "Uploading setup script to github release"
upload_release_assets "diego-windows-msi/scripts/setup.ps1", res
puts "Uploaded setup script to github release"

puts "FIXME: Put cf/diego shas in descriptions"
