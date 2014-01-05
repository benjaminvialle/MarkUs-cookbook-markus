#
# Cookbook Name:: markus
# Attributes:: default
#
# Licensed under the GPL License, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
default[:markus][:version]            = "master"
default[:markus][:checksum]           = ""
default[:markus][:ruby_version]       = "1.9.3-p484"
default[:markus][:ruby_path]          = "/home/markus/.rubies"
default[:markus][:ruby_sitedir]       = "/home/markus/.rubies/#{node[:markus][:ruby_version]}/lib/ruby/site_ruby"
