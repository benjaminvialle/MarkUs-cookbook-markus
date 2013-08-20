#
# Cookbook Name:: markus
# Recipe:: default
#
# Copyright 2013, MarkUsProject
#

# installing ruby for user markus
ruby_build_ruby "#{node[:markus][:ruby_version]}" do
  prefix_path "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]"
  user        "markus"
  group       "markus"
  action      :install
end
