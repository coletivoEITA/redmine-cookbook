#
# Author:: Seigo Uchida (<spesnova@gmail.com>)
# Cookbook Name:: redmine
# Recipe:: default
#
# Copyright (C) 2013 Seigo Uchida (<spesnova@gmail.com>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "git"
# TODO install ruby

user node["redmine"]["user"] do
  home node["redmine"]["base_path"]
  system true
end

# Setup database
# TODO cover postgresql
include_recipe "mysql::client"
include_recipe "mysql::ruby"
# TODO support 'recipe[mysql::server_ec2]'
include_recipe "mysql::server"

# Set "default-character-set=utf8" in [mysql] section
execute 'sed -i "s/\[mysql\]/\[mysql\]\ndefault-character-set=utf8/" /etc/my.cnf' do
  user "root"
  not_if "grep 'default-character-set=utf8' /etc/my.cnf"
  action :run
end

service "mysqld" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

connection_info = {
  :host => "localhost",
  :username => "root",
  # specify at node["mysql"]["server_root_password"]
  # TODO use data bags
  :password => node["mysql"]["server_root_password"]
}

mysql_database "redmine" do
  connection connection_info
  action :create
end

mysql_database_user "redmine_user" do
  connection connection_info
  # TODO use data bags
  password "super"
  action :create
end

mysql_database_user "redmine_user" do
  connection connection_info
  database_name "redmine"
  privileges [:all]
  # TODO use data bags
  password "super"
  action :grant
end

# Setup web server
# TODO install nginx
# Install unicorn
include_recipe "unicorn"

# Setup firewall
service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end

template "/etc/sysconfig/iptables" do
  source "iptables.erb"
  owner "root"
  group "root"
  mode "0600"
  variables({:port => node["redmine"]["port"]})
  notifies :restart, "service[iptables]"
end

if node[:platform_family] == "rhel"
  %w{ ImageMagick ImageMagick-devel ipa-pgothic-fonts }.each do |pkg|
    package pkg
  end
end

# Making the directories for deploy
directory node["redmine"]["deploy_to"] do
  owner node["redmine"]["user"]
  group node["redmine"]["user"]
  mode "0755"
  recursive true
end

directory "#{node['redmine']['deploy_to']}/shared" do
  owner node["redmine"]["user"]
  group node["redmine"]["user"]
  mode "0755"
end

%w{ config log system pids cached-copy bundle }.each do |dir|
  directory "#{node['redmine']['deploy_to']}/shared/#{dir}" do
    owner node["redmine"]["user"]
    group node["redmine"]["user"]
    mode "0755"
    recursive true
  end
end

# Deploy the redmine app
deploy_revision node["redmine"]["deploy_to"] do
  action :deploy
  user node["redmine"]["user"]
  group node["redmine"]["group"]
  environment "RAILS_ENV" => "production"

  # Checkout
  repo node["redmine"]["repo"]
  revision node["redmine"]["revision"]
  shallow_clone false
  enable_submodules true

  # Migrate
  before_migrate do
    [
      "#{node['redmine']['deploy_to']}/shared/config/database.yml",
      "#{release_path}/config/database.yml"
    ].each do |dir|
      template dir do
        source "database.yml.erb"
        owner node["redmine"]["user"]
        group node["redmine"]["user"]
        mode "0644"
        variables({
          :database => "redmine",
          :host     => "localhost",
          :username => "redmine_user",
          :password => "super",
          :encoding => "utf8"
        })
      end
    end
    # TODO config/configuration.yml
    execute "bundle install --path #{node["redmine"]["deploy_to"]}/shared/bundle > /tmp/bundle.log" do
      user "root"
      cwd release_path
      action :run
    end
    execute 'bundle exec rake generate_secret_token' do
      cwd release_path
      not_if { ::File.exists?("#{release_path}/config/initializers/secret_token.rb") }
      action :run
    end
  end
  symlink_before_migrate "config/database.yml" => "config/database.yml"
  migrate true
  migration_command "bundle exec rake db:migrate --trace >/tmp/migration.log 2>&1"

  # Symlink
  before_symlink do
    unicorn_config "#{release_path}/config/unicorn.rb" do
      listen({ "80" => { :tcp_nodelay => true, :backlog => 100 }})
      worker_processes "5"
      pid "#{node['redmine']['deploy_to']}/shared/pids/unicorn.pid"
      stderr_path "#{node['redmine']['deploy_to']}/shared/log/unicorn.stderr.log"
      stdout_path "#{node['redmine']['deploy_to']}/shared/log/unicorn.stdout.log"
    end
  end
  purge_before_symlink %w{ log tmp/pids public/system }
  create_dirs_before_symlink %w{ tmp public config }
  symlinks "system" => "public/system",
           "pids"   => "tmp/pids",
           "log"    => "log"

  # Restart
  # TODO support USR2 restart process
  restart_command "kill -HUP `cat #{node['redmine']['deploy_to']}/shared/pids/unicorn.pid`"

end

execute "bundle exec unicorn -c config/unicorn.rb -D -E production" do
  user "root"
  cwd "#{node["redmine"]["deploy_to"]}/current"
  not_if { ::File.exists?("#{node["redmine"]["deploy_to"]}/shared/pids/unicorn.pid") }
  action :run
end

