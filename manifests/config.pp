# == Class: sympa::config
#
# Configures Sympa.
#
# === Parameters
#
# [*db_password*]
#   (Required) The password to use for the MySQL sympa user.
#
# [*listmasters*]
#   (Required) Array of email addresses that are administrators.
#
# [*list_domains*]
#   Array of mail domains handled by Sympa.
#
# [*admin_domain*]
#   (Required) The primary mail domain used by Sympa for internal comms.
#
# [*vhost_name*]
#   (Required) The domain name of the virtual host that runs Sympa.
#
# [*vhost_title*]
#   The title of the Sympa site.
#
# [*key_file*]
#   The private key that the Apache VirtualHost will use.
#
# [*cert_file*]
#   The certificate that the Apache VirtualHost will use.
#
# [*ca_file*]
#   The CA certificate that the Apache VirtualHost will use.
#
# === Authors
#
# David McNicol <david@mcnicks.org>
#

class sympa::config (
  $db_password,
  $listmasters,
  $list_domains,
  $admin_domain,
  $vhost_name,
  $vhost_title,
  $key_file,
  $cert_file,
  $ca_file
) {

  # Start the Sympa service.

  service { 'sympa':
    ensure  => 'running',
    require => Package['sympa']
  }

  # Configure Sympa.

  file { '/etc/sympa/sympa.conf':
    ensure  => 'present',
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0640',
    content => template('sympa/sympa.conf.erb'),
    notify  => Service['sympa']
  }

  file { '/etc/sympa/wwsympa.conf':
    ensure  => 'present',
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0640',
    content => template('sympa/wwsympa.conf.erb'),
    notify  => Service['apache2']
  }

  # Configure Sympa web site.

  class { 'apache':
    user         => 'sympa',
    group        => 'sympa',
    manage_user  => false,
    manage_group => false
  }

  file { '/var/run/sympa_fcgid_sock':
    ensure => 'directory',
    owner  => 'sympa',
    group  => 'sympa',
    mode   => '0755'
  }

  include 'apache::mod::rewrite'
  include 'apache::mod::ssl'

  class { 'apache::mod::fcgid':
    options => {
      'FcgidIPCDir' => '/var/run/sympa_fcgid_sock'
    },
    require => File['/var/run/sympa_fcgid_sock']
  }

  $sympa_content = '/var/lib/sympa/static_content'
  $sympa_fcgi = '/usr/lib/cgi-bin/sympa/wwsympa-wrapper.fcgi'

  apache::vhost { $vhost_name:
    ensure      => 'present',
    docroot     => '/var/www',
    ssl         => true,
    port        => '443',
    ssl_key     => $key_file,
    ssl_cert    => $cert_file,
    ssl_ca      => $ca_file,
    aliases     => [
      {
        alias => '/static-sympa',
        path  => $sympa_content
      }
    ],
    directories => [
      {
        provider => 'directory',
        path     => '/var/www'
      },
      {
        provider   => 'locationmatch',
        path       => '/sympa/([^/]+)',
        sethandler => 'fcgid-script',
        options    => [ 'ExecCGI' ]
      }
    ],
    notify      => Service['apache2']
  }

  # Create an index.html linking to each of the Sympa domains.

  file { '/var/www/index.html':
    ensure  => 'present',
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    content => template('sympa/index.html.erb')
  }

}
