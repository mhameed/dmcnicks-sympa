# == Class: sympa
#
# Configures Sympa for SGP.
#
# === Parameters
#
# [*mysql_root_password*]
#   (Required) The password to use for the MySQL root user.
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
#   The primary mail domain used by Sympa for internal comms.
#
# [*vhost_name*]
#   The domain name of the virtual host that runs Sympa.
#
# [*vhost_title*]
#   The title of the Sympa site.
#
# [*key_file*]
#   (Optional) The private key that the Apache VirtualHost will use.
#
# [*cert_file*]
#   (Optional) The certificate that the Apache VirtualHost will use.
#
# [*ca_file*]
#   (Optional) The CA certificate that the Apache VirtualHost will use.
#
# === Authors
#
# David McNicol <david@mcnicks.org>
#

class sympa (
  $mysql_root_password,
  $db_password,
  $listmasters,
  $list_domains = [ $::fqdn ],
  $admin_domain = $::fqdn,
  $vhost_name   = $::fqdn,
  $vhost_title  = 'Mailing List Service',
  $key_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $cert_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ca_file = '/etc/ssl/certs/ca-certificates.crt'
) {

  # Install the Sympa package.

  class { 'sympa::install':
    mysql_root_password => $mysql_root_password,
    db_password         => $db_password
  }

  contain 'sympa::install'

  # Configure  MySQL, Sympa and Apache.

  class { 'sympa::config':
    db_password  => $db_password,
    listmasters  => $listmasters,
    list_domains => $list_domains,
    admin_domain => $admin_domain,
    vhost_name   => $vhost_name,
    vhost_title  => $vhost_title,
    key_file     => $key_file,
    cert_file    => $cert_file,
    ca_file      => $ca_file,
    require      => Class['sympa::install']
  }

  contain 'sympa::config'

  # Configure the list domains.

  sympa::domain { $list_domains:
    vhost_name  => $vhost_name,
    vhost_title => $vhost_title,
    require     => Class['sympa::install']
  }

}
