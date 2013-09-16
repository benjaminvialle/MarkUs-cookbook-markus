#
# Cookbook Name:: markus
# Recipe:: source
#
# Copyright 2013, MarkUsProject
#

include_recipe "markus::default"



postgresql_connection_info = {:host => "localhost",
                              :port => node['postgresql']['config']['port'],
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}

# We are using data_bags here
database_user 'markus' do
  connection postgresql_connection_info
  password 'markus'
  provider Chef::Provider::Database::PostgresqlUser
  action :create
end

database 'markus_development' do
  connection postgresql_connection_info
  provider Chef::Provider::Database::Postgresql
  owner 'markus'
  action :create
end

database 'markus_test' do
  connection postgresql_connection_info
  provider Chef::Provider::Database::Postgresql
  owner 'markus'
  action :create
end

postgresql_database_user 'markus' do
  connection postgresql_connection_info
  database_name 'markus_development'
  privileges [:all]
  action :grant
end

postgresql_database_user 'markus' do
  connection postgresql_connection_info
  database_name 'markus_test'
  privileges [:all]
  action :grant
end

execute "Install bundler for ruby #{node[:markus][:ruby_version]}" do
  cwd         "/home/markus"
  user        "markus"
  group       "markus"
  environment "PATH" => "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
  command     "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/gem install bundler --no-rdoc --no-ri"
  creates     "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle"
  action      :run
end
