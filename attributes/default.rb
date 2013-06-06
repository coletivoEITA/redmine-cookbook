#
# Author:: Seigo Uchida (<spesnova@gmail.com>)
# Cookbook Name:: redmine
# Attributes:: default
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

default["redmine"]["user"]      = "root"
default["redmine"]["deploy_to"] = "/opt/redmine"
default["redmine"]["repo"]      = "git://github.com/spesnova/redmine.git"
default["redmine"]["revision"]  = "bfa275211564aba5d6b54d87e104e2db76122d5f"
default["redmine"]["port"]      = "80"
default["redmine"]["domain"]    = "redmine.example.com"

# Unicorn setting
default["unicorn"]["port"]             = default["redmine"]["port"]
default["unicorn"]["worker_processes"] = "5"

# database setting
default["redmine"]["db"]["name"] = "redmine"
default['mysql']['tunable']['character-set-server'] = "utf8"

