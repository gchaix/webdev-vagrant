# == Define: squishy_v1::drupal_site
#
# A defined type for setting up Drupal sites. This type does many things, but
# does not do a git checkout.
#
# Currently very limited in scope; this is all we do:
# - Ensure pear and drush are installed (via drupal_deps)
# - Manage the database by using puppetlabs/mysql
# - Create a matching settings.php
# - Ensure the files directory is writable
#
# === Parameters
#
# *title*:: The name of the puppet resource. Used as the default value for many parameters.
# *root*:: Filesystem path to Drupal root (containing index.php and sites/). No default.
# *site_name*:: The name of the Drupal site (name of the directory under sites/). Defaults to *title*.
# *db_user*:: MySQL database username. Defaults to *title*.
# *db_pass*:: MySQL database password. Defaults to *title*.
# *db_host*:: MySQL database server hostname. Defaults to *localhost*.
# *db_name*:: MySQL database name. Defaults to *title*.
# *update_free_access*:: Whether to allow non-authenticated access to update.php. Defaults to *false*.
# *settings_file*:: Filesystem path to settings.php. Defaults to *root*/sites/*site_name*/settings.php.
# *writable_dirs*:: Array of directories to ensure are apache-writable. Defaults to [ "*root*/sites/*site_name*/files" ].
# *manage_mysql*:: Whether to create a MySQL database and user. Defaults to *true*
#
define squishy_v1::drupal_site(
  $root      = undef,
  $site_name = $title,
  $db_user   = $title,
  $db_pass   = $title,
  $db_host   = 'localhost',
  $db_name   = $title,
  $update_free_access = false,
  $settings_file = undef,
  $writable_dirs = undef,
  $manage_mysql = true,
){
  include squishy_v1::drupal_deps

  if ! $root {
    fail("You must specify a Drupal root for Squishy_v1::Drupal_site[$site_name]")
  }

  if $settings_file {
    $_settings_file = $settings_file
  }
  else {
    $_settings_file = "$root/sites/$site_name/settings.php"
  }

  if $writable_dirs {
    $_writable_dirs = $writable_dirs
  }
  else {
    $_writable_dirs = [ "$root/sites/$site_name/files" ]
  }

  ###

  # TODO: chmod doesn't work from inside vagrant; the user has to
  # do it manually. Figure out why and see if it can be fixed.
  if ! $vagrant {
    file { $_writable_dirs:
      ensure => directory,
      owner => 'apache',
      group => 'dev',
      mode => 'ug+w,o-w',
      # recurse => true, # this really punishes the server recursively chmodding on every puppet run
      recurse => false,
    }
  }

  # make the database (requires puppetlabs/mysql)
  if ($manage_mysql) {
    mysql::db { $db_name:
      user     => $db_user,
      password => $db_pass,
    }
  }

  # create settings.php using the database credentials specified
  file { $_settings_file:
    content => template('squishy_v1/settings.php.erb'),
    group => $vagrant ? { 1 => undef, default => 'dev' },
    ensure  => 'present',
    mode => 'ug+w,o-w',
  }

  # Add a cronjob to run Drupal's cron once an hour
  cron { "drush_${title}_cron":
    command => "/usr/bin/drush --root=$root --uri=$site_name core-cron 2>&1 > /dev/null",
    user => 'apache',
    minute => fqdn_rand(60),
  }
}
