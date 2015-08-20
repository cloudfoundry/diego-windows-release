#!/usr/bin/env ruby

begin
require 'octokit'
require 'git'
require 'colorize'
rescue LoadError
  puts "Run gem install octokit, git and colorize"
  exit 1
end

unless ENV['GITHUB_TOKEN'] && ARGV[0]
  puts "Usage: GITHUB_TOKEN=token #{$0} diego-version"
  exit 1
end

def token
  ENV['GITHUB_TOKEN']
end

def github
  @github ||= Octokit::Client.new access_token: token
end

def diego_repo
  'cloudfoundry-incubator/diego-release'
end

def msi_repo
  'cloudfoundry-incubator/diego-windows-msi'
end

def diego_commit_for_release release
  github.tags(diego_repo).select { |t| t.name == release }.first[:commit][:sha]
end

def msi_releases
  github.releases(msi_repo)
end

def diego_version
  ARGV[0] or raise "Please specify diego_version as an argument"
end

releases = msi_releases.map do |r|
  {
    "version" => r.tag_name,
    "compatible_shas" => r.body.split("\n").grep(/diego-release/).map { |x| x.split('@')[1]},
  }
end

desired_sha = diego_commit_for_release(diego_version)
diego_release_repo = Git.open("~/workspace/diego-release")
diego_release_repo.fetch

stats = releases.map do |r|
  r["compatible_shas"].map do |sha|
    begin
      commits = diego_release_repo.log.between(desired_sha, sha)
      reverted_commits = diego_release_repo.log.between(sha, desired_sha)
      count = commits.count
      if count == 0
        count = -reverted_commits.count
      end
      {
        "release" => r["version"],
        "count" => count,
      }
    rescue
    end
  end
end


stats.flatten!.compact!.sort_by! do |a|
  [a["count"].abs, a["release"]]
end

stats.each do |s|
  release = s['release']
  count = s['count']
  msg = "release #{release} is compatible with #{count.abs} commits #{count > 0 ? "after": "before"} #{diego_version}"

  case
  when count.abs < 5
    color = :green
  when count.abs < 10
    color = :yellow
  else
    color = :red
  end

  puts msg.colorize color
end
