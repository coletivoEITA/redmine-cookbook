# Redmine cookbook
This cookbook is designed to deploy the Redmine application.

Currently supported:

* Deploy the redmine app from the source
* Install and Manage MySQL by using the opscode official recipe
* Install and Manage nginx(yet) with Unicorn by using the opscode official recipe

Roadmap:

* Install and setting nginx
* Support log rotate for Rails, Unicorn logs
* Use node attributes instead of hard coding
* Support USR2 restart process
* Support ruby install
* Support other platform

# Requirements
Chef version 0.10.10+

## Platform

* CentOS

Tested on:

* CentOS 6.4

## Cookbooks

* git
* mysql
* database
* unicorn
* iptables
 * (this cookbook may be deprecated or heavily modified in favor of the general firewall cookbook)
*

## Gemfile.lock
Your redmine app must have `Gemfile.lock` to success `$ bundle install`.

# Usage
TODO

# Attributes
See the `attributes/default.rb` for default values.

* `node["redmine"]["user"]`
* `node["redmine"]["deploy_to"]` - The redmine application's deploy root path
* `node["redmine"]["repo"]` - Repository URL for the redmine application
* `node["redmine"]["revision"]` - The revision to be checked out
* `node["redmine"]["db"]["name"]` - The Database name for redmine

# Recipes
## default
Setup the redmine application.

# Data Bags
This cookbook use the redmine data bag for some password.

Use knife to create a data bag for redmine.
```
$ knife data bag create redmine
$ mkdir data_bags/redmine
```
Create a secret redmine data in the `data_bag/redmine/database.json` directory.
```
{
  "id": "database",
  "user_password": "<PASSWORD>"
}
```

* `user_password` - The database user password described in config/database.yml

Upload the json data to Chef Server.
```
$ knife data bag from file redmine data_bags/redmine/database.json
```

# License and Author

Author:: Seigo Uchida (<spesnova@gmail.com>)

Copyright:: 2013 Seigo Uchida (<spesnova@gmail.com>)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
