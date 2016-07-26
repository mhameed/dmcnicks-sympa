# == Class: sympa::install
#
# Installs the Sympa package.
#
# === Parameters
#
# [*mysql_root_password*]
#   (Required) The password to use for the MySQL root user.
#
# [*db_password*]
#   (Required) The password to use for the MySQL sympa user.
#
# === Authors
#
# David McNicol <david@mcnicks.org>
#

class sympa::install (
  $mysql_root_password,
  $db_password
) {

  # Install MySQL and create Sympa database.

  class { 'mysql::server':
    root_password => $mysql_root_password
  }

  mysql::db { 'sympa':
    user     => 'sympa',
    password => $db_password,
  }
  
  # Backup the sympa database.

  class { 'mysql::server::backup':
    backupuser        => 'backups',
    backuppassword    => $db_password,
    backupdir         => '/srv/mysqlbackups',
    backupdatabases   => [ 'sympa' ],
    backupcompress    => false,
    file_per_database => true,
    time              => [ '23', '45' ]
  }

  # Install Sympa.

  file { '/etc/sympa.responsefile':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => template('sympa/sympa.responsefile.erb')
  }

  package { 'sympa':
    ensure       => 'present',
    responsefile => '/etc/sympa.responsefile',
    require      => [
      Mysql::Db['sympa'],
      File['/etc/sympa.responsefile']
    ]
  }

}
