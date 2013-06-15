#
# Author:: Seigo Uchida (<spesnova@gmail.com>)
# Cookbook Name:: redmine
# Recipe:: backup
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

# Set up "backup" directories and config file
backup_generate_config node["hostname"] do
  base_dir node["backup"]["base_dir"]
  encryption_password node["backup"]["encryption_password"]
end

backup_generate_model "redmine" do
  description "Backup up Redmine database"
  split_into_chunks_of node["backup"]["redmine"]["split_into_chunks_of"]
  backup_type "database"
  database_type "MySQL"
  options({
    "db.name"               => "\'#{node['redmine']['database']}\'",
    "db.username"           => "\'#{node['redmine']['database_user']}\'",
    "db.password"           => "\'#{data_bag_item('redmine', 'database')['user_password']}\'",
    "db.host"               => "\'localhost\'",
    "db.port"               => "\'#{node['mysql']['port']}\'",
    "db.socket"             => "\'#{node['mysql']['socket']}\'",
    "db.additional_options" => ["--quick", "--single-transaction"]
  })
  store_with({
    "engine" => "SCP",
    "settings" => {
      "scp.username" => node["backup"]["redmine"]["store"]["server_username"],
      "scp.password" => node["backup"]["redmine"]["store"]["server_password"],
      "scp.ip"       => node["backup"]["redmine"]["store"]["server_ip"],
      "scp.port"     => node["backup"]["redmine"]["store"]["server_port"],
      "scp.path"     => node["backup"]["redmine"]["store"]["path"],
      "scp.keep"     => node["backup"]["redmine"]["store"]["keep"]
    }
  })
  minute node["backup"]["redmine"]["cron"]["miniute"]
  hour node["backup"]["redmine"]["cron"]["hour"]
  day node["backup"]["redmine"]["cron"]["day"]
  weekday node["backup"]["redmine"]["cron"]["weekday"]
  mailto node["backup"]["redmine"]["cron"]["mailto"]
  action :backup
end

