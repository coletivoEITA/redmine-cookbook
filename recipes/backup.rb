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

directory "#{node["backup"]["config_path"]}/models" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

backup_model node["redmine"]["database"] do
  description "Backup up Redmine database"

  definition <<-DEF
    split_into_chunks of "#{node['redmine']['backup']['split_into_chunks_of']}"

    database MySQL do |db|
      db.name               = "#{node['redmine']['database']}"
      db.username           = "#{node['redmine']['database_user']}"
      db.password           = "#{data_bag_item('redmine', 'database')['user_password']}"
      db.host               = "localhost"
      db.port               = "#{node['mysql']['port']}"
      db.socket             = "#{node['mysql']['socket']}"
      db.additional_options = ["--quick", "--single-transaction"]
    end

    compress_with Gzip

    # TODO store_with block
    # TODO notify_by block
  DEF

  schedule({
    :minute => 0,
    :hour   => 8,
  })
end
