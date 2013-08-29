#
# Cookbook Name:: markus
# Recipe::LDAP
#
# Configures MarkUs' LDAP module for ECN
#
# Copyright 2013, MarkUsProject
#

include_recipe "markus::production"


# packages needed in order to compile LDAP module
case node['platform']

when "debian"
  %w{ libldap2-dev libldap-dev }.each do |pg_pack|
    package pg_pack
  end

end

# We are using data_bags here
search(:markus, '*:*') do |instance|

  template "/home/markus/#{instance['instance']}/lib/tools/ldap/ldap_synch_auth.h" do
    source "ldap_synch_auth.h.erb"
    owner "markus"
    group "markus"
    mode 0600
  end

  bash "Compile LDAP module for #{instance['instance']}" do
    cwd "/home/markus/#{instance['instance']}/lib/tools/ldap"
    code <<-EOH
    make
    EOH
    creates "/home/markus/#{instance['instance']}/lib/tools/ldap/ldap_synch_auth"
  end

  template "/home/markus/#{instance['instance']}/config/dummy_validate.sh" do
    source "dummy_validate_LDAP.sh.erb"
    owner "markus"
    group "markus"
    mode 0755
    variables( :ldap_auth_path => "/home/markus/#{instance['instance']}/lib/tools/ldap/ldap_synch_auth" )
  end

end
