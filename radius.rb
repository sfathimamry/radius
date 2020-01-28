# Cookbook Name:: radius 
# Recipe:: default 
# 
case node['platform'] 
when "debian", "ubuntu" 
include_recipe 'apt' 
when "centos","redhat" 
include_recipe 'yum' 
include_recipe "yum-epel" 
end 
 
# Install build dependencies
remote_install 'radius' do
  source 'https://github.com/FreeRADIUS/freeradius-server/archive/release_3_0_4.tar.gz'
  version '3.0.4'
  build_command './configure'
  compile_command 'make'
  install_command 'make install'
end

# Install build dependencies 
#packages = node['freeradius']['packages'] 
 #packages.each do |pkg| 
  # package pkg do 
   #  action :install 
   #end 
 #end 
 
 
 # Configuration dirs 
 ["chef","local"].each do |dir| 
   directory "/etc/raddb/#{dir}" do 
     action :create 
     owner "root" 
     group "radiusd" 
     mode  00755 
   end 
 end 
 
 
 # Main config files (the ones that includes local and chef files) 
 ["clients.conf"].each do |file| 
   cookbook_file "/etc/raddb/#{file}" do 
     source "#{file}"
     mode 00644 
   end 
 end 
 
 
 ["mschap"].each do |file| 
   cookbook_file "/etc/raddb/mods-available/#{file}" do 
     source "#{file}" 
     mode 00644 
   end 
 end 
 
 
 # Authorize (users) configuration 
 cookbook_file "/etc/raddb/mods-config/files/authorize" do 
   source "authorize" 
   mode 00644 
 end 
 
 
 # Default site 
 cookbook_file "/etc/raddb/sites-available/default" do 
   source "default_site" 
   mode 00644 
 end 
 
 
 # Files in chef dir 
 ["clients.conf","users"].each do |file| 
   cookbook_file "/etc/raddb/chef/#{file}" do 
     source "chef/#{file}" 
     mode 00644 
     action :create 
   end 
 end 
 
 
 # Sample files in local dir 
 ["clients.conf","users"].each do |file| 
   cookbook_file "/etc/raddb/local/#{file}" do 
     source "local/#{file}" 
     mode 00644 
     action :create_if_missing 
   end 
 end 
 

 # Ruckus extensions 
 [ "dictionary", "dictionary.ruckus" ].each do |file| 
   cookbook_file "/usr/share/freeradius/#{file}" do 
     source "#{file}" 
     mode 00644 
     notifies :reload, 'service[radiusd]' 
   end 
 end 
 

 # FIXME: setfacl -m u:radiusd:rx /var/lib/samba/winbindd_privileged 
 execute 'set-winbind-acl' do 
   command 'setfacl -m u:radiusd:rx /var/lib/samba/winbindd_privileged' 
 end 
 
 
 service "radiusd" do 
  action [ :enable, :start ] 
 end 
