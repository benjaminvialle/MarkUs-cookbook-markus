#
# Cookbook Name:: markus
# Recipe:: default
#
# Copyright 2013, MarkUsProject
#

# installing ghostscript to convert PDF
case node['platform']

when "debian"
  package "ghostscript" do
    action :install
  end
end

# installing ruby for user markus
ruby_build_ruby "#{node[:markus][:ruby_version]}" do
  prefix_path "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}"
  user        "markus"
  group       "markus"
  action      :install
  # When compiling ruby with ruby-build, we have to force --enable-shared
  # --enable-shared is needed to force ruby to have shared linkable librairies
  # --enable-shared is needed in order to compile subversion ruby bindings
  environment "CONFIGURE_OPTS" => "--enable-shared"
end

# installing subversion for user markus
remote_file "/home/markus/subversion-#{node[:subversion][:version]}.tar.gz" do
  source "#{node[:subversion][:download_link]}/subversion-#{node[:subversion][:version]}.tar.gz"
  action :create_if_missing
  user        "markus"
  group       "markus"
end

bash "Compile subversion #{node[:subversion][:version]} for user markus with ruby-#{node[:markus][:ruby_version]}" do
  cwd         "/home/markus"
  user        "markus"
  group       "markus"
  code <<-EOH
    tar xvzf subversion-#{node[:subversion][:version]}.tar.gz
    cd subversion-#{node[:subversion][:version]}
    ./configure --with-ruby-sitedir=#{node[:markus][:ruby_sitedir]} --prefix=#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}
    make && make swig-rb && make install && make install-swig-rb
  EOH
  creates "#{node[:markus][:ruby_sitedir]}/1.9.1/svn/repos.rb"
  creates "#{node[:markus][:ruby_sitedir]}/1.9.1/svn/client.rb"
end
