# Our "lamp" manifest requires this external variable.
$mysql_root_password = 'root'

include squishy_v1::minimum
include squishy_v1::lamp
include webdev_extras::extras

apache::vhost { 'vagrant':
  priority => '10',
  port => '80',
  docroot => '/server/htdocs',
  override => ['all'],
}

# Uncomment this block to enable drupal
# squishy_v1::drupal_site { 'default':
#     root => '/server/htdocs',
#         db_pass => 'asdf',
# }

# Ensure that apache::vhost doesn't clobber our docroot.
# Alternately, you can use `link` or `directory` if you want to be explicit.
file { '/server/htdocs':
  ensure => present,
}

# Enable development settings in php.ini
augeas { 'vagrant_php.ini':
  context => "/files/etc/php.ini",
  changes => [
    'set PHP/display_errors On',
    'set PHP/display_startup_errors On',
    'set PHP/error_reporting "E_ALL | E_STRICT',
  ],
}

# insecure settings for ssh client within vagrant
augeas { 'ssh_config':
  context => "/files/etc/ssh/ssh_config",
  changes => [
    "set Host *",
    "set Host[.='*']/StrictHostKeyChecking no",
    "set Host[.='*']/User $vagrant_ssh_user",
  ],
  require => File['/usr/share/augeas/lenses/ssh.aug'],
}

# vagrant boxes don't need iptables
service { 'iptables':
  ensure => stopped,
  enable => false,
}
