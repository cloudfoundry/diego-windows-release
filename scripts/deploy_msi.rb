#!/usr/bin/env ruby

require 'net/ssh'
require 'net/ssh/gateway'
require 'base64'

ADMIN_PASS = ENV['ADMIN_PASS'] or raise "Please set env var ADMIN_PASS"
JUMP_MACHINE_IP = ENV['JUMP_MACHINE_IP']
MACHINE_IP = ENV['MACHINE_IP'] or raise "Please set env var MACHINE_IP"
REDUNDANCY_ZONE = ENV['REDUNDANCY_ZONE'] or raise "Please set env var REDUNDANCY_ZONE"
BOSH_URL = ENV['BOSH_URL'] or raise "Please set env var BOSH_URL"
MSI_FILE_DIR = ARGV[0] or raise "Please run with first arg as directory of MSI File"

MSI_URL = File.read "#{MSI_FILE_DIR}/url"
EXPECTED_SHA = MSI_URL.match(/DiegoWindowsMSI-(.*)-([0-9a-f]+).msi$/) { |x| x[2] } or raise "Please set a download url (in #{MSI_FILE_DIR}/url)"

INSTALL_DIR = "c:\\diego-install"
MSI_LOCATION = "#{INSTALL_DIR}\\diego.msi"

GENERATOR_URL = File.read("install-script-generator/url")
GENERATOR_LOCATION = "#{INSTALL_DIR}\\generator.exe"

SETUP_URL = MSI_URL.gsub("DiegoWindowsMSI", "setup").gsub(".msi", ".ps1")
SETUP_LOCATION = "#{INSTALL_DIR}\\setup.ps1"

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
  puts ssh.exec!("rd #{INSTALL_DIR} /s /q")
  puts ssh.exec!("mkdir #{INSTALL_DIR}")

  puts "Downloading setup script from #{SETUP_URL}"
  puts ssh.exec!("powershell /C wget '#{SETUP_URL}' -OutFile #{SETUP_LOCATION}")

  puts "Downloading msi from #{MSI_URL}"
  puts ssh.exec!("powershell /C wget '#{MSI_URL}' -OutFile #{MSI_LOCATION}")

  puts "Downloading install script generator from #{GENERATOR_URL}"
  puts ssh.exec!("powershell /C wget '#{GENERATOR_URL}' -OutFile #{GENERATOR_LOCATION}")

  puts "Generating the install script"
  puts ssh.exec!("#{GENERATOR_LOCATION} -boshUrl=#{BOSH_URL} -outputDir=#{INSTALL_DIR} -windowsUsername=Administrator -windowsPassword=#{ADMIN_PASS}")

  puts "Provisioning the machine"
  execute_my_scripts_please(ssh) do
    response = ssh.exec!("powershell -Command & $env:windir/sysnative/WindowsPowerShell/v1.0/powershell.exe -Command #{SETUP_LOCATION}")
    puts response
    if response.include?("PSSecurityException")
      exit(1)
    end
  end

  puts "Install"
  puts ssh.exec!("#{INSTALL_DIR}\\install_#{REDUNDANCY_ZONE}.bat")

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
