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

# Setup database # TODO cover postgresql
# TODO set default character utf8 /etc/mycnf
include_recipe "mysql::server" # TODO cover 'recipe[mysql::server_ec2]'
include_recipe "mysql::client"
include_recipe "mysql::ruby"

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

# TODO enable iptables 80


if node[:platform_family] == "rhel"
  %w{ ImageMagick ImageMagick-devel ipa-pgothic-fonts }.each do |pkg|
    package pkg
  end
end

# Prepare about deploy directories
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

%w{ config log system pids cached-copy }.each do |dir|
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
    template "#{node['redmine']['deploy_to']}/shared/config/database.yml" do
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
    # 下記 resource は bundle install する前は shared から release へ
    # に symlink が貼れれておらず adapter の指定をするためここにもファイルを置く
    template "#{release_path}/config/database.yml" do
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
    # TODO config/configuration.yml
    execute "bundle install --without development test > /tmp/bundle.log" do
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
    end
  end
  purge_before_symlink %w{ log tmp/pids public/system }
  create_dirs_before_symlink %w{ tmp public config }
  symlinks "system" => "public/system",
           "pids"   => "tmp/pids",
           "log"    => "log"

  # Restart
  # TODO restart unicorn
end
