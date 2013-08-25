#
# Cookbook Name:: markus
# Recipe:: source
#
# Copyright 2013, MarkUsProject
#

include_recipe "markus::default"

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
