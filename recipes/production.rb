#
# Cookbook Name:: markus
# Recipe:: source
#
# Copyright 2013, MarkUsProject
#

include_recipe "markus::default"
include_recipe "nginx::default"
include_recipe "unicorn::default"



postgresql_connection_info = {:host => "localhost",
                              :port => node['postgresql']['config']['port'],
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}

# We are using data_bags here
search(:markus, '*:*') do |instance|

  database_user instance['database_user'] do
    connection postgresql_connection_info
    password instance['database_password']
    provider Chef::Provider::Database::PostgresqlUser
    action :create
  end

  database instance['database'] do
    connection postgresql_connection_info
    provider Chef::Provider::Database::Postgresql
    owner instance['database_user']
    action :create
  end

  postgresql_database_user instance['database_user'] do
    connection postgresql_connection_info
    database_name instance['database']
    privileges [:all]
    action :grant
  end

  # installing latest markus
  remote_file "/home/markus/markus-#{instance['markus_version']}.tar.gz" do
    source "https://github.com/MarkUsProject/Markus/archive/#{instance['markus_version']}.tar.gz"
    action :create_if_missing
    #checksum    node[:markus][:checksum] unless node[:markus][:version] == "master"
    user        "markus"
    group       "markus"
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

  bash "Extract markus source code" do
    cwd         "/home/markus"
    user        "markus"
    group       "markus"
    code <<-EOH
    tar xvzf markus-#{instance['markus_version']}.tar.gz
    cp -r Markus-#{instance['markus_version']} #{instance['instance']}
    EOH
    creates "/home/markus/#{instance['instance']}/Gemfile"
  end

  execute "Install Gemfile for markus" do
    cwd         "/home/markus/#{instance['instance']}"
    user        "markus"
    group       "markus"
    environment "PATH" => "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
    command     "#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle install"
    action :run
  end

  template "/home/markus/#{instance['instance']}/config/database.yml" do
    source "database.postgresql.yml.erb"
    owner "markus"
    group "markus"
    mode 0600
    variables( :database => instance['database'], :username => instance['database_user'], :password => instance['database_password'] )
  end

  template "/home/markus/#{instance['instance']}/config/application.rb" do
    source "application.rb.erb"
    owner "markus"
    group "markus"
    mode 0600
    variables( :time_zone => instance['time_zone'] )
  end

  execute "Load schema in database" do
    cwd         "/home/markus/#{instance['instance']}"
    user        "markus"
    group       "markus"
    environment "RAILS_ENV" => "production"
    command     "PATH=#{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin:$PATH #{node[:markus][:ruby_path]}/#{node[:markus][:ruby_version]}/bin/bundle exec rake db:schema:load"
    action      :run
  end

  directory "/home/markus/#{instance['instance']}/tmp/log" do
    owner "markus"
    group "markus"
    mode 00755
    recursive true
    action :create
  end

  directory "/home/markus/#{instance['instance']}/tmp/pids" do
    owner "markus"
    group "markus"
    mode 00755
    recursive true
    action :create
  end

  directory "/home/markus/#{instance['instance']}/tmp/sockets" do
    owner "markus"
    group "markus"
    mode 00755
    recursive true
    action :create
  end

  template "/home/markus/#{instance['instance']}/config/unicorn.rb" do
    source "unicorn.rb.erb"
    owner "markus"
    group "markus"
    mode 0600
    variables(:markus_path => "/home/markus/#{instance['instance']}")
  end

  template "/etc/init.d/#{instance['instance']}" do
    source "markus_unicorn_init.erb"
    owner "root"
    group "root"
    mode 0755
    variables(:markus_path => "/home/markus/#{instance['instance']}", :instance => instance['instance'])
  end

  template "/etc/nginx/sites-available/#{instance['instance']}" do
    source "markus_nginx_site.erb"
    owner "root"
    group "root"
    mode 0600
    variables(:markus_path => "/home/markus/#{instance['instance']}", :instance => instance['instance'], :domain => instance['domain'])
  end

  nginx_site 'default' do
    enable false
  end

  nginx_site "#{instance['instance']}" do
    enable true
  end

  service 'nginx' do
    supports :status => true, :restart => true, :reload => true
    action :restart
  end

  service "#{instance['instance']}" do
    supports :status => true, :restart => true, :reload => true
    action :restart
  end

end
