#!/usr/bin/env ruby

require 'net/ssh'
require 'net/ssh/gateway'

ADMIN_PASS = ENV['ADMIN_PASS'] or raise "Please set env var ADMIN_PASS"
JUMP_MACHINE_IP = ENV['JUMP_MACHINE_IP']
MACHINE_IP = ENV['MACHINE_IP'] or raise "Please set env var MACHINE_IP"
CONSUL_IPS = ENV['CONSUL_IPS'] or raise "Please set env var CONSUL_IPS"
ETCD_CLUSTER = ENV['ETCD_CLUSTER'] or raise "Please set env var ETCD_CLUSTER"
CF_ETCD_CLUSTER = ENV['CF_ETCD_CLUSTER'] or raise "Please set env var CF_ETCD_CLUSTER"
REDUNDANCY_ZONE = ENV['REDUNDANCY_ZONE'] or raise "Please set env var REDUNDANCY_ZONE"
LOGGREGATOR_SHARED_SECRET = ENV['LOGGREGATOR_SHARED_SECRET'] or raise "Please set env var LOGGREGATOR_SHARED_SECRET"
MSI_FILE_DIR = ARGV[0] or raise "Please run with first arg as directory of MSI File"

MSI_URL = File.read "#{MSI_FILE_DIR}/url"
EXPECTED_SHA = MSI_URL.match(/DiegoWindowsMSI-(.*)-([0-9a-f]+).msi$/) { |x| x[2] } or raise "Please set a download url (in #{MSI_FILE_DIR}/url)"
MSI_LOCATION = "c:\\diego.msi"

SETUP_URL = MSI_URL.gsub("DiegoWindowsMSI", "setup").gsub(".msi", ".ps1")
SETUP_LOCATION = "c:\\setup.ps1"

options = {
  auth_methods: ["publickey"],
  use_agent: false,
  key_data: [ENV['JUMP_MACHINE_SSH_KEY']]
}

# Figure out the sha of the msi being installed using the download url.

block = ->(ssh) do
  hostname = ssh.exec!("hostname").chomp
  puts "Hostname: #{hostname}"

  puts "Uninstall"
  puts ssh.exec!("msiexec /norestart /passive /x #{MSI_LOCATION}")
  ssh.exec!("del /Y #{MSI_LOCATION}")

  puts "Downloading setup script from #{SETUP_URL}"
  puts ssh.exec!("powershell /C wget '#{SETUP_URL}' -OutFile #{SETUP_LOCATION}")

  puts "Downloading msi from #{MSI_URL}"
  puts ssh.exec!("powershell /C wget '#{MSI_URL}' -OutFile #{MSI_LOCATION}")

  puts "Provisioning the machine"
  puts ssh.exec!("powershell -Command & $env:windir/sysnative/WindowsPowerShell/v1.0/powershell.exe -Command #{SETUP_LOCATION}")

  puts "Install"
  puts ssh.exec!("msiexec /norestart /passive /i #{MSI_LOCATION} "+
                 "ADMIN_USERNAME=Administrator "+
                 "ADMIN_PASSWORD=#{ADMIN_PASS} "+
                 "CONSUL_IPS=#{CONSUL_IPS} "+
                 "ETCD_CLUSTER=#{ETCD_CLUSTER} "+
                 "CF_ETCD_CLUSTER=#{CF_ETCD_CLUSTER} "+
                 "LOGGREGATOR_SHARED_SECRET=#{LOGGREGATOR_SHARED_SECRET} "+
                 "STACK=windows2012R2 "+
                 "REDUNDANCY_ZONE=#{REDUNDANCY_ZONE} "+
                 (ENV["SYSLOG_HOST_IP"] ? "SYSLOG_HOST_IP=#{ENV["SYSLOG_HOST_IP"]} " : "")+
                 (ENV["SYSLOG_PORT"] ? "SYSLOG_PORT=#{ENV["SYSLOG_PORT"]} " : "")
                )

  output = ssh.exec!("powershell /C type $Env:ProgramW6432/CloudFoundry/DiegoWindows/RELEASE_SHA")
  actual_sha = output.chomp.split(/\s+/).last
  puts actual_sha.inspect

  if actual_sha != EXPECTED_SHA
    puts "Installation failed: expected #{EXPECTED_SHA}, got #{actual_sha}"
    exit(1)
  end
  puts "Installation succeeded, #{EXPECTED_SHA} == #{actual_sha}"
end

if JUMP_MACHINE_IP
  gateway = Net::SSH::Gateway.new(JUMP_MACHINE_IP, 'ec2-user', options)
  gateway.ssh(MACHINE_IP, "ci", options, &block)
else
  Net::SSH.start(MACHINE_IP, "ci", options, &block)
end
