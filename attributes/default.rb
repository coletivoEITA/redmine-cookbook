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
default["redmine"]["revision"]  = "4fa6a87c38e8d034d2f2b7740bf7507c6cf5f919"
default["redmine"]["port"]      = "80"
default["redmine"]["domain"]    = "redmine.example.com"

# Unicorn setting
default["unicorn"]["port"]             = default["redmine"]["port"]
default["unicorn"]["options"]          = { :tcp_nodelay => true, :backlog => 100 }
default["unicorn"]["worker_processes"] = [node[:cpu][:total].to_i * 4, 8].min
default["unicorn"]["worker_timeout"]   = "60"
default["unicorn"]["preload_app"]      = true
default["unicorn"]["before_exec"]      = nil
default["unicorn"]["before_fork"]      = nil
default["unicorn"]["after_fork"]       = nil
default["unicorn"]["enable_stats"]     = false
default["unicorn"]["copy_on_write"]    = false

# database setting
default["redmine"]["db"]["name"] = "redmine"
default['mysql']['tunable']['character-set-server'] = "utf8"

