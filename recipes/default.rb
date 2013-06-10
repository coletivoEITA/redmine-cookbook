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
  system true
end

# Setup database
# TODO support postgresql
include_recipe "mysql::client"
include_recipe "mysql::ruby"
# TODO support 'recipe[mysql::server_ec2]'
include_recipe "mysql::server"

service "mysqld" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

connection_info = {
  :host => "localhost",
  :username => "root",
  # specify at node["mysql"]["server_root_password"]
  # TODO use data bags
  :password => node["mysql"]["server_root_password"]
}

mysql_database node["redmine"]["database"] do
  connection connection_info
  action :create
end

mysql_database_user node["redmine"]["database_user"] do
  connection connection_info
  password data_bag_item("redmine", "database")["user_password"]
  action :create
end

mysql_database_user node["redmine"]["database_user"] do
  connection connection_info
  database_name node["redmine"]["database"]
  privileges [:all]
  password data_bag_item("redmine", "database")["user_password"]
  action :grant
end

# Setup web server
# TODO install nginx

# Setup firewall
template "/etc/sysconfig/iptables" do
  source "iptables.erb"
  owner "root"
  group "root"
  mode "0600"
  variables({:port => node["redmine"]["port"]})
  notifies :restart, "service[iptables]"
end

service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
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

# Install unicorn
include_recipe "unicorn"

# TODO add notifies attribute that notify restart unicorn
unicorn_config "#{node['redmine']['deploy_to']}/shared/config/unicorn.rb" do
  listen({ "80" => { :tcp_nodelay => true, :backlog => 100 }})
  worker_processes node["unicorn"]["worker_processes"]
  worker_timeout node["unicorn"]["worker_timeout"]
  preload_app node["unicorn"]["preload_app"]
  pid "#{node['redmine']['deploy_to']}/shared/pids/unicorn.pid"
  before_exec node["unicorn"]["before_exec"]
  before_fork node["unicorn"]["before_fork"]
  after_fork node["unicorn"]["after_fork"]
  stderr_path "#{node['redmine']['deploy_to']}/shared/log/unicorn.stderr.log"
  stdout_path "#{node['redmine']['deploy_to']}/shared/log/unicorn.stdout.log"
  copy_on_write node["unicorn"]["copy_on_write"]
  enable_stats node["unicorn"]["enable_stats"]
  notifies nil
end

# Insall and setup for rmagick
if node[:platform_family] == "rhel"
  %w{ ImageMagick ImageMagick-devel ipa-pgothic-fonts }.each do |pkg|
    package pkg
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
          :database => node["redmine"]["database"],
          :host     => "localhost",
          :username => node["redmine"]["database_user"],
          :password => data_bag_item("redmine", "database")["user_password"],
          :encoding => "utf8"
        })
      end
    end
    template "#{node['redmine']['deploy_to']}/shared/config/configuration.yml" do
      source "configuration.yml.erb"
      owner node["redmine"]["user"]
      group node["redmine"]["user"]
      mode "0644"
    end
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
  migration_command "bundle exec rake db:migrate --trace >/tmp/migration.log 2>&1 && bundle exec rake redmine:plugins --trace > /tmp/plugins_migration.log"

  # Symlink
  purge_before_symlink %w{ log tmp/pids public/system }
  create_dirs_before_symlink %w{ tmp public config }
  symlinks "system" => "public/system",
           "pids"   => "tmp/pids",
           "log"    => "log",
           "config/configuration.yml" => "config/configuration.yml",
           "config/unicorn.rb" => "config/unicorn.rb"

  # Restart
  # TODO support USR2 restart process
  if ::File.exists?("#{node['redmine']['deploy_to']}/shared/pids/unicorn.pid`")
    restart_command "kill -HUP `cat #{node['redmine']['deploy_to']}/shared/pids/unicorn.pid`"
  end
end

execute "bundle exec unicorn -c config/unicorn.rb -D -E production" do
  user "root"
  cwd "#{node["redmine"]["deploy_to"]}/current"
  not_if { ::File.exists?("#{node["redmine"]["deploy_to"]}/shared/pids/unicorn.pid") }
  action :run
end
