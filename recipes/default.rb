#
# Cookbook Name:: markus
# Recipe:: default
#
# Copyright 2013, MarkUsProject
#

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

postgresql_connection_info = {:host => "localhost",
                              :port => node['postgresql']['config']['port'],
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}

database_user 'markus' do
  connection postgresql_connection_info
  password 'markus'
  provider Chef::Provider::Database::PostgresqlUser
  action :create
end

database 'markus_production' do
  connection postgresql_connection_info
  provider Chef::Provider::Database::Postgresql
  owner 'markus'
  action :create
end

postgresql_database_user 'markus' do
  connection postgresql_connection_info
  database_name 'markus_production'
  privileges [:all]
  action :grant
end

# installing latest markus
remote_file "/home/markus/markus-#{node[:markus][:version]}.tar.gz" do
  source "https://github.com/MarkUsProject/Markus/archive/#{node[:markus][:version]}.tar.gz"
  action :create_if_missing
  checksum    node[:markus][:checksum] unless node[:markus][:version] == "master"
  user        "markus"
  group       "markus"
end

bash "Install bundler for ruby #{node[:markus][:ruby_version]}" do
  cwd         "/home/markus"
  user        "markus"
  group       "markus"
  command     "PATH=#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:$PATH #{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/gem install bundler"
  creates "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle"
end

bash "Extract markus source code" do
  cwd         "/home/markus"
  user        "markus"
  group       "markus"
  code <<-EOH
    tar xvzf markus-#{node[:markus][:version]}.tar.gz
  EOH
  creates "/home/markus/Markus-master/Gemfile"
end

execute "Install Gemfile for markus" do
  cwd         "/home/markus/Markus-#{node[:markus][:version]}"
  user        "markus"
  group       "markus"
  command     "PATH=#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:$PATH #{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle install"
  action :run
end
