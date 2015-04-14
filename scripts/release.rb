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
  env_var 'GO_REVISION_diego_windows_msi'
end

def release
  label = env_var 'GO_PIPELINE_LABEL'
  "v0.#{label}"
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

def s3_url
  "https://s3.amazonaws.com/diego-windows-msi/output/DiegoWindowsMSI-#{short_sha}.msi"
end

def create_github_tag
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

def upload_release_assets release
  temp_file = "/tmp/DiegoWindowsMSI.msi"
  File.open(temp_file, "wb") do |saved_file|
    open(s3_url, "rb") do |read_file|
      saved_file.write(read_file.read)
    end
  end
  github.upload_asset release[:url],
                      temp_file,
                      content_type: 'application/octet-stream',
                      name: "DiegoWindowsMSI.msi"
end

res = create_github_tag
upload_release_assets res
