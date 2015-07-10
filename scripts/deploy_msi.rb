#!/usr/bin/env ruby

require 'net/ssh'
require 'net/ssh/gateway'

ADMIN_PASS = ENV['ADMIN_PASS'] or raise "Please set env var ADMIN_PASS"
JUMP_MACHINE_IP = ENV['JUMP_MACHINE_IP']
MACHINE_IP = ENV['MACHINE_IP'] or raise "Please set env var MACHINE_IP"
CONSUL_IPS = ENV['CONSUL_IPS'] or raise "Please set env var CONSUL_IPS"
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

def execute_my_scripts_please(ssh)
  current_execution_policy = ssh.exec!("powershell /C Get-ExecutionPolicy").chomp
  ssh.exec!("powershell /C Set-ExecutionPolicy Bypass -Scope CurrentUser")
  yield
  ssh.exec!("powershell /C Set-ExecutionPolicy #{current_execution_policy} -Scope CurrentUser")
end

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
  puts ssh.exec!("powershell  wget '/C wget '#{MSI_URL}' -OutFile #{MSI_LOCATION}")

  etcd_ca_content = Base64.encode64(ENV["ETCD_CA_FILE"])
  etcd_cert_content = Base64.encode64(ENV["ETCD_CERT_FILE"])
  etcd_key_content = Base64.encode64(ENV["ETCD_KEY_FILE"])
  etcd_key_file = "C:\\etcd_key_file"
  etcd_ca_file = "C:\\etcd_ca_file"
  etcd_cert_file = "C:\\etcd_cert_file"
  puts ssh.exec!(%{powershell /c "[System.Text.Encoding]::ASCII.GetString( [System.Convert]::FromBase64String('#{etcd_ca_content}') ) | out-file #{etcd_ca_file} -encoding ascii})
  puts ssh.exec!(%{powershell /c "[System.Text.Encoding]::ASCII.GetString( [System.Convert]::FromBase64String('#{etcd_cert_content}') ) | out-file #{etcd_cert_file} -encoding ascii})
  puts ssh.exec!(%{powershell /c "[System.Text.Encoding]::ASCII.GetString( [System.Convert]::FromBase64String('#{etcd_key_content}') ) | out-file #{etcd_key_file} -encoding ascii})

  puts "Provisioning the machine"
  execute_my_scripts_please(ssh) do
    response = ssh.exec!("powershell -Command & $env:windir/sysnative/WindowsPowerShell/v1.0/powershell.exe -Command #{SETUP_LOCATION}")
    puts response
    if response.include?("PSSecurityException")
      exit(1)
    end
  end

  puts "Install"
  puts ssh.exec!("msiexec /norestart /passive /i #{MSI_LOCATION} "+
                 "ADMIN_USERNAME=Administrator "+
                 "ADMIN_PASSWORD=#{ADMIN_PASS} "+
                 "CONSUL_IPS=#{CONSUL_IPS} "+
                 "ETCD_CA_FILE=#{etcd_ca_file} "+
                 "ETCD_CERT_FILE=#{etcd_cert_file} "+
                 "ETCD_KEY_FILE=#{etcd_key_file} "+
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
