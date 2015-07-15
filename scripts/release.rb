#!/usr/bin/env ruby

require 'octokit'
require 'time'
require 'open-uri'

def token
  ENV['GITHUB_TOKEN'] or raise "Environment variable #{var} isn't set"
end

def revision(dir = File.dirname(__FILE__))
  Dir.chdir(dir) do
    `git rev-parse HEAD`.chomp
  end
end

def msi_file
  Dir::glob('./msi-file/DiegoWindowsMSI-*-*.msi').first
end

def release
  "v#{File.read('./msi-file/version').chomp}"
end

def github
  @github ||= Octokit::Client.new access_token: token
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
                    "greenhouse-ci ", # tagger name isn't being used by the api
                    "pivotal-netgarden-eng@pivotal.io", # tagger email isn't being used by the api
                    Time.now.utc.iso8601

  diego_release = revision("diego-release") rescue "UNKNOWN"
  cf_release = revision("cf-release") rescue "UNKNOWN"
  release_body = <<-BODY
cloudfoundry-incubator/diego-release@#{diego_release}
cloudfoundry/cf-release@#{cf_release}
BODY
  github.create_release(repo,
                        release,
                        name: release,
                        body: release_body)
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
upload_release_assets "diego-windows-msi/docs/INSTALL.md", res
puts "Uploaded installation instructions to github release"

puts "Uploading setup script to github release"
upload_release_assets "diego-windows-msi/scripts/setup.ps1", res
puts "Uploaded setup script to github release"
