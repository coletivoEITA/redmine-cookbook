#
# Author:: Seigo Uchida (<spesnova@gmail.com>)
# Cookbook Name:: redmine
# Attributes:: backup
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

default["backup"]["base_dir"]            = "/opt/backup"
default["backup"]["encryption_password"] = nil

# backup setting for redmine
default["backup"]["redmine"]["split_into_chunks_of"]      = 2048
default["backup"]["redmine"]["cron"]["minute"]            = "*"
default["backup"]["redmine"]["cron"]["hour"]              = "1"
default["backup"]["redmine"]["cron"]["day"]               = "*"
default["backup"]["redmine"]["cron"]["weekday"]           = "*"
default["backup"]["redmine"]["cron"]["mailto"]            = "sample@example.com"
default["backup"]["redmine"]["store"]["server_username"]  = "sample_user"
default["backup"]["redmine"]["store"]["server_password"]  = "sample_password"
default["backup"]["redmine"]["store"]["server_ip"]        = "123.45.678.90"
default["backup"]["redmine"]["store"]["server_port"]      = "22"
default["backup"]["redmine"]["store"]["path"]             = "/opt/backup/stores"
default["backup"]["redmine"]["store"]["keep"]             = "5"



