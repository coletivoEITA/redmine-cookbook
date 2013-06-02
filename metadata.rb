name             "redmine"
maintainer       "Seigo Uchida"
maintainer_email "spesnova@gmail.com"
license          "All rights reserved"
description      "Installs/Configures redmine"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%W{ centos }.each do |os|
  supports os
end

%W{ git mysql database unicorn }.each do |cb|
  depends cb
end
