#
# Cookbook Name:: markus
# Recipe:: source
#
# Copyright 2013, MarkUsProject
#

include_recipe "markus::default"
include_recipe "nginx::default"
include_recipe "unicorn::default"

template "/home/markus/Markus-#{node[:markus][:version]}/config/database.yml" do
  source "database.postgresql.yml.erb"
  owner "markus"
  group "markus"
  mode 0600
end

execute "Load schema in database" do
  cwd         "/home/markus/Markus-#{node[:markus][:version]}"
  user        "markus"
  group       "markus"
  environment "RAILS_ENV" => "production"
  command     "PATH=#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:$PATH #{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle exec rake db:schema:load"
  action      :nothing
end

directory "/home/markus/Markus-#{node[:markus][:version]}/tmp/log" do
  owner "markus"
  group "markus"
  mode 00644
  recursive true
  action :create
end

directory "/home/markus/Markus-#{node[:markus][:version]}/tmp/pids" do
  owner "markus"
  group "markus"
  mode 00644
  recursive true
  action :create
end

directory "/home/markus/Markus-#{node[:markus][:version]}/tmp/sockets" do
  owner "markus"
  group "markus"
  mode 00644
  recursive true
  action :create
end

template "/home/markus/Markus-#{node[:markus][:version]}/config/unicorn.rb" do
  source "unicorn.rb.erb"
  owner "markus"
  group "markus"
  mode 0600
  variables(:markus_path => "/home/markus/Markus-#{node[:markus][:version]}")
end

template "/etc/init.d/markus" do
  source "markus_unicorn_init.erb"
  owner "markus"
  group "markus"
  mode 0600
end

template "/etc/nginx/sites-available/markus" do
  source "markus_nginx_site.erb"
  owner "root"
  group "root"
  mode 0600
end

nginx_site 'default' do
  enable false
end

nginx_site 'markus' do
  enable true
end

service 'nginx' do
  supports :status => true, :restart => true, :reload => true
  action :restart
end
