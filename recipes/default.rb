#
# Cookbook Name:: projectorion
# Recipe:: default
#
# Copyright (C) 2014 Adam Leonard
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2"
include_recipe "apache2::mod_php5"

# #Unencrypted data bag option
# data_bag("BettingBag").each do |item|
# 	item_data = data_bag_item("BettingBag", item)

# 	template "/var/www/cgi-bin/connectToDB.php" do
#     source "connectToDB.php.erb"
#     mode "0644"
#      variables(
#        :connect => item_data["connection_string"],
#        :user => item_data["user"],
#        :userid => item_data["userid"]
#      )
#   end
# end

# Encrypted data bag option
item_data = Chef::EncryptedDataBagItem.load("projectorion-bag", "projectorion")

template "/var/www/cgi-bin/connectToDB.php" do
 source "connectToDB.php.erb"
 mode "0644"
 variables(
   :connection => item_data["connection_string"],
   :user => item_data["user"],
   :password => item_data["userid"]
 )
end


remote_directory "/var/www/cgi-bin" do
	source "app"
end

bash "install_mysql" do
  user "root"
  code <<-EOH
  yum install php-mysql php php-xml php-mcrypt php-mbstring php-cli mysql httpd -y
  EOH
end

service "apache2" do
	action :restart
end

apache_site "default" do
	enable true
end
