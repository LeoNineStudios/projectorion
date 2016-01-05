#
# Cookbook Name:: projectorion
# Recipe:: default
#
# Copyright (C) 2014 Adam Leonard
#
# All rights reserved - Do Not Redistribute
#

execute 'update yum' do
  command 'yum update -y'
  notifies :run, 'execute[add rpm]', :immediately
end

execute 'add rpm' do
  command 'rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm'
  action :nothing
end

packages = ['php54w', 'php54w-mysql', 'php54w-pdo', 'mysql', 'unzip']

packages.each do |pkg|
  package pkg
end

include_recipe 'apache2::default'
include_recipe 'apache2::mod_php5'
include_recipe 'projectorion::reload_override'

# mysql_secret = Chef::EncryptedDataBagItem.load_secret(node['projectorion']['mysql']['secretpath'])
item_data = data_bag_item('projectorion-bag', 'projectorion')

template '/var/www/cgi-bin/connectToDB.php' do
  source 'connectToDB.php.erb'
  mode '0644'
  variables(connect: item_data['connection_string'],
            user: item_data['user'],
            userid: item_data['userid']
           )
end

remote_file "#{Chef::Config[:file_cache_path]}/projectorion-src.zip" do
  source 'https://s3.amazonaws.com/leoninestudios/projectorion/projectorion-src.zip'
  mode '0755'
  action :create
end

execute 'unzip_source' do
  command "unzip -u #{Chef::Config[:file_cache_path]}/projectorion-src.zip -d /var/www/"
end

execute 'download composer' do
  command 'curl -s https://getcomposer.org/installer | php && php composer.phar install'
  cwd '/var/www/cgi-bin/composer/'
  not_if { ::File.directory?('/var/www/cgi-bin/composer/vendor') }
end

template '/var/www/cgi-bin/users/signin.php' do
  source 'signin.php.erb'
  mode '0644'
  variables(google_client: item_data['google_client'],
            google_secret: item_data['google_secret']
           )
end

service 'apache2' do
  action [:enable, :start]
end

# Removed due to move to Google Cloud
# cron 'node_eraser' do
#   hour '4'
#   minute '45'
#   command 'knife node delete projectorion-wsas -y -c /etc/chef/client.rb'
# end
#
# cron 'client_eraser' do
#   hour '4'
#   minute '45'
#   command 'knife client delete projectorion-wsas -y -c /etc/chef/client.rb'
# end
