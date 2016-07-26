# == Type sympa::domain
#
# Creates a new mail domain in Sympa.
#
# === Parameters
#
# [*title*]
#   (Namevar) The fully-qualified domain name of the mail domain.
#
# [*vhost_name*]
#   (Required) The domain name of the virtual host that runs Sympa.
#
# [*vhost_title*]
#   (Required) The title of the Sympa site.
#
# === Authors
#
# David McNicol <david@mcnicks.org>
#

define sympa::domain (
  $vhost_name,
  $vhost_title
) {

  # Create the list data directory for the domain.

  file { "/var/lib/sympa/list_data/${title}":
    ensure => 'directory',
    owner  => 'sympa',
    group  => 'sympa',
    mode   => '0750'
  }

  # Create the config directory for the domain.

  file { "/etc/sympa/${title}":
    ensure => 'directory',
    owner  => 'sympa',
    group  => 'sympa',
    mode   => '0750'
  }

  # Create the config file for the domain.

  file { "/etc/sympa/${title}/robot.conf":
    ensure  => 'present',
    owner   => 'sympa',
    group   => 'sympa',
    mode    => '0640',
    content => template('sympa/robot.conf.erb'),
    require => File["/etc/sympa/${title}"]
  }

  # Create fragment apache configuration.

  concat::fragment { "${vhost_name}-${title}":
    target  => "25-${vhost_name}.conf",
    order   => 55,
    content => template('sympa/sympa_vhost_fragment.erb')
  }
}
