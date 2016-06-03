[![Stories in Ready](https://badge.waffle.io/gchaix/webdev-vagrant.png?label=ready&title=Ready)](https://waffle.io/gchaix/webdev-vagrant)
webdev-vagrant
==============

Creates VirtualBox VM on your local machine pre-configured with Apache, PHP, MySQL. This method provides a viable alternative to MAMP or XAMPP or even a local LAMP stack, especially for diverse teams working on the same project.

This project is designed by default to work with Drupal, but it should work equally well with other PHP applications.

Build status: [![Circle CI](https://circleci.com/gh/gchaix/webdev-vagrant.svg?style=svg)](https://circleci.com/gh/gchaix/webdev-vagrant)

TLDR - getting started right away
=============

0. clone this repo
0. clone your project webroot into ```./htdocs```
0. run ```vagrant up```

Requirements
==============

* VirtualBox version 4.2.10 or newer - https://www.virtualbox.org/wiki/Downloads
* VirtualBox extensions 4.2.10 or newer - http://download.virtualbox.org/virtualbox/4.2.10
* Vagrant version 1.5.1 or newer - http://vagrantup.com/
* A 64bit-capable processor and operating system (Tested with Ubuntu 12.10 and OS X 10.6)
  * It should be possible to run on a 32bit host machine by substituting a 32bit base box, but this has not been tested. Feedback is welcome!
* vagrant-triggers extension - https://github.com/emyl/vagrant-triggers
  * Install: ```vagrant plugin install vagrant-triggers```

Installation
=============

* Install [Vagrant](http://downloads.vagrantup.com/)
  * Additionally, ensure the vagrant-triggers plugin is installed: `$ vagrant plugin install vagrant-triggers`
* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* Install [git](http://git-scm.com/downloads) if you don't have it already. If you're not familiar with git, [ensure you are](http://git-scm.com/doc).
* Clone this repository. It provides the root of a new project repository.
* Put or symlink your project webroot into the `{reporoot}/htdocs` directory.

Configuration details
==============

* The VM is running CentOS 6, Apache 2.2.15, MySQL 5.1, PHP 5.3.3.
* The EPEL repo is enabled, so newer versions of packages are available.
* Apache is configured to serve up /server/htdocs by default.
* The root password is 'vagrant'.
* The 'vagrant' user is set to have full sudo rights, no password required.
* The root user on the MySQL server is preconfigured and the credentials are stored in the root user's .my.cnf, so you can run `sudo mysql` and be logged in on the MySQL console as root.
* The directory containing the Vagrantfile config file and the rest of this repository (including your project webroot) on your local machine is mounted on the virtual machine in `/server` to facilitate moving files to and from the virtual machine.

Usage
==============

* To start up the virtual machine, run `vagrant up` in the same directory as the Vagrantfile config file (this can take a few minutes). As soon as it's booted you should be able to hit the URL specified after the `==> VAGRANT for [$projectname]` message, and see whatever is in the `{reporoot}/htdocs` directory.
* If your application uses a MySQL database, configure your app to connect to `localhost` with the username `root` and password `root`.
* To access the virtual machine, run `vagrant ssh`.  That will log you into the virtual machine as the user `vagrant`.
  * In typical usage, you should only need to run database commands within the VM. All other work happens on your physical host computer.
* To shut the machine down, run `vagrant halt`.  This gracefully shuts the machine down, retaining whatever changes you've made to the VM.
* To delete the virtual machine, run `vagrant destroy`.  This will completely erase the virtual machine and your MySQL databases. Your `Vagrantfile`, application code, and puppet rules are all left intact.
* To enable a drupal instance, add this block to the default.pp manifest:
```
squishy_v1::drupal_site { 'default':
  root => '/server/htdocs',
    db_pass => 'asdf',
}
```

Known Bugs
====

Empty interface name
---

There is a [bug in vagrant 1.6.0](https://github.com/mitchellh/vagrant/issues/3649) that causes an error on `vagrant up`. This is the error message:

```
==> default: Configuring and enabling network interfaces...
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

/sbin/ifdown

Stdout from the command:



Stderr from the command:

usage: ifdown <device name>

```

If you see this message, install `biosdevname` and try again: 

```
vagrant ssh -c 'sudo yum install -y biosdevname'
vagrant reload
```

General error || Missing Drupal Files 
---
You might see an error message at the end of your puppet run that looks something like this:

```
The following SSH command responded with a non-zero exit status.
Vagrant assumes that this means the command failed!

FACTER_vagrant='1' FACTER_vagrant_ssh_user='someuser' puppet apply --hiera_config /server/vagrant/hiera.yaml --logdest syslog --modulepath '/tmp/vagrant-puppet-1/modules-0' --manifestdir /tmp/vagrant-puppet-1/manifests --detailed-exitcodes /tmp/vagrant-puppet-1/manifests/default.pp || [ $? -eq 2 ]

Stdout from the command:



Stderr from the command:
```

This is a generalized message telling you that puppet was unable to do something. If you added the block of code to default.pp to enable drupal development, there's a good chance you're seeing the error because puppet can't find your drupal files. Be sure to either install the files for drupal to the htdocs directory, or symlink htdocs to wherever your drupal files live.

If you're sure you've got your drupal files in the right place, or didn't include the drupal code in your default.pp, you can connect to the VM with `vagrant ssh` and run the following command to see what puppet was unable to do: 
`sudo cat /var/log/messages | grep "Could not"`

No drupal database
---


If you've included the drupal code in your default.pp and put your drupal files in the htdocs directory, you might see the following error when visiting the URL that vagrant you:

```
PDOException: SQLSTATE[42S02]: Base table or view not found: 1146 Table 'default.semaphore' doesn't exist: SELECT expire, value FROM {semaphore} WHERE name = :name; Array ( [:name] => variable_init ) in lock_may_be_available() (line 167 of /server/drupal-7.29/includes/lock.inc).
```

This simply means there is no database for drupal to use. You can follow the directions on the drupal site to manually set up a database, or you can do it the super simple way by connecting to your VM with `vagrant ssh` and then `cd /server/htdocs && drush si`

Answer "yes" to the scary confirmation prompt about dropping all your tables (you have no database, and no tables to drop). Drush will set up your database and give you a username and password to use for further drupal setup. Reload the URL that vagrant gave you to see the "Welcome to Site-Install" message from drupal.

Credits
==============
A big thanks to Evan Heidtmann [(ezheidtmann)](https://github.com/ezheidtmann) for taking my vague, badly-implemented idea and making it actually *work*.  The base box and most of the Puppet and configuration scripts are his work.

Huge chunks shamelessly stolen from a gist posted by David Lutz [(dlutzy)](https://github.com/dlutzy): https://gist.github.com/2469037/646a2b99656ef68eba87cec3ecec96d2d581f68d

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Copyright 2015 Greg Lund-Chaix

See [COPYING.txt](COPYING.txt) for more information.

