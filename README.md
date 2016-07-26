# The Sympa module

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
4. [Usage](#usage)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

Installs and configures Sympa.

## Module Description

This Puppet module installs and configures the Sympa mailing list service.

### Dependencies

* [puppetlabs/apache](https://forge.puppetlabs.com/puppetlabs/apache)
* [puppetlabs/mysql](https://forge.puppetlabs.com/puppetlabs/mysql)
* [puppetlabs/stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib)

### Recommended modules

* [dmcnicks/postfix](https://forge.puppetlabs.com/dmcnicks/postfix)

### Tested on

* Debian 7 (wheezy)

## Setup

### What the Sympa module affects

* Installs MySQL and creates a Sympa database.
* Configures nightly backups of the Sympa database.
* Installs the Sympa package.
* Installs Apache, running as the Sympa user.
* Connects Apache to wwsympa using mod_fcgid.
* Creates virtual mail domains and separate wwsympa apps for each domain.
* Creates an index file that links to each wwsympa app.

This module **does not** configure the node to accept mail. Puppet must
configure a mail service separately. See the 
[working with Postfix](#working-with-postfix) section for an example of how
this can be done.

### Beginning with the Sympa module

The basic usage of the Sympa module requires three parameters: a root password
for MySQL; a password for the Sympa MySQL user and a list of email addresses
that will be administrators (listmasters in Sympa terms).

    class { 'sympa':
      mysql_root_password => 'apassword',
      db_password         => 'anotherpassword',
      listmasters         => [ 'an@email.address', 'another@email.address' ]
    }

In this configuration, the module will use the fully-qualified domain name of
the node as the mail domain and Apache virtual host name.

Multiple mail domains can be specified:

    class { 'sympa':
      mysql_root_password => 'apassword',
      db_password         => 'anotherpassword',
      listmasters         => [ 'an@email.address', 'another@email.address' ],
      mail_domains        => [ 'lists.domain.com', 'announce.domain.com' ]
    }

Note that Sympa uses the fully-qualified domain name for administrative
emails. If you are not routing email to the fully-qualified domain name using
an MX record, you should specify an administrative domain that is routed to
the node:

    class { 'sympa':
      mysql_root_password => 'apassword',
      db_password         => 'anotherpassword',
      listmasters         => [ 'an@email.address', 'another@email.address' ],
      mail_domains        => [ 'lists.domain.com', 'announce.domain.com' ],
      admin_domain        => 'lists.domain.com'
    }

A separate Apache virtual host name can also be specified:

    class { 'sympa':
      mysql_root_password => 'apassword',
      db_password         => 'anotherpassword',
      listmasters         => [ 'an@email.address', 'another@email.address' ],
      mail_domains        => [ 'lists.domain.com', 'announce.domain.com' ],
      admin_domain        => 'lists.domain.com',
      vhost_name          => 'mailinglists.company.com'
    }

By default the Apache virtual host will use self-signed certificates for
SSL. You can specify your own key and certificate:

    class { 'sympa':
      mysql_root_password => 'apassword',
      db_password         => 'anotherpassword',
      listmasters         => [ 'an@email.address', 'another@email.address' ],
      mail_domains        => [ 'lists.domain.com', 'announce.domain.com' ],
      admin_domain        => 'lists.domain.com',
      vhost_name          => 'mailinglists.company.com'
      key_file            => 'path/to/private.key',
      cert_file           => 'path/to/certificate.crt',
      ca_file             => 'path/to/ca.crt'
    }

If you do not specify a `ca_file` the module will use the system CA file,
which should include most of the common certificate authorities.

### Working with Postfix

This module does not configure the node to accept mail. You can use my
Postfix module to configure Postfix to handle mail for Sympa:

* [dmcnicks/postfix](https://forge.puppetlabs.com/dmcnicks/postfix)

With this module you can define the mail domains you want the node to
handle and specify a separate aliases file for Sympa:

    class { 'postfix':
      smarthost     => 'smtp.isp.com',
      username      => 'username@isp.com',
      password      => 'NNNNNNNN',
      admin_email   => 'admin@email.address',
      mail_domains  => [ 'lists.domain.com', 'announce.domain.com' ],
      alias_files   => [ '/etc/postfix/sympa_aliases' ]
    }

### Automatic routing with Postfix

To do more complex automatic routing you can use the defined types in the
Postfix module to define generic aliases and virtual regexp mappings for
Sympa. First the virtual regexp mappings:

    postfix::regexp { '/^(postmaster|root|abuse)@mail\.domain$/':
      to => '$1'
    }

    postfix::regexp { '/^(sympa-owner|sympa-request)@mail\.domain$/':
      to => '$1'
    }

    postfix::regexp { '/^(.*)-(request|editor|owner)@mail\.domain$/':
      to => 'mail.domain-$2+$1'
    }

    postfix::regexp { '/^(.*)-(subscribe|unsubscribe)@mail\.domain$/':
      to => 'mail.domain-$2+$1'
    }

    postfix::regexp { '/^(.*)@mail\.domain$/':
      to => 'mail.domain+$1'
    }

These map mailing list addresses, subscribe and unsubscribe addresses and
various other addresses for every mailing list under the `mail.domain` domain.
The following aliases map the right-hand side of these regexp mappings onto
the correct Sympa executables:

    postfix::alias { 'mail.domain in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/queue $EXTENSION@mail.domain'
    }

    postfix::alias { 'mail.domain-request in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/queue $EXTENSION-request@mail.domain'
    }

    postfix::alias { 'mail.domain-editor in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/queue $EXTENSION-editor@mail.domain'
    }

    postfix::alias { 'mail.domain-subscribe in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/queue $EXTENSION-subscribe@mail.domain'
    }

    postfix::alias { 'mail.domain-unsubscribe in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/queue $EXTENSION-unsubscribe@mail.domain'
    }

    postfix::alias { 'mail.domain-owner in /etc/postfix/sympa_aliases':
      to => '| /usr/lib/sympa/bin/bouncequeue $EXTENSION@mail.domain'
    }

These aliases use the Postfix recipient delimiter (`+`) to map aliases for
every list onto a single set of aliases. The regexp mappings place the name
of each list into the address extension (`+listname`) which is removed from
the recipient address and placed in the `$EXTENSION` variable.

The result of these mappings is that every mailing list defined in Sympa
for `mail.domain` will automatically be routed through Postfix to Sympa
without any further configuration.

## Usage

### The `sympa` class

The module's primary class. 

#### Parameters

##### `mysql_root_password`

(Required) The password to use for the MySQL root user.

##### `db_password`

(Required) The password to use for the MySQL Sympa user.

##### `listmasters`

(Required) An array of email addresses that are administrators.

##### `list_domains`

(Optional) An array of mail domains handled by Sympa (defaults to FQDN).

##### `admin_domain`

(Optional) The primary mail domain used by Sympa for internal communications
(defaults to FQDN).

##### `vhost_name`

(Optional) The domain name of the virtual host that runs Sympa (defaults
to FQDN).

##### `vhost_title`

(Optional) The title of the Sympa web site (defaults to Mailing List Service).

##### `key_file`

(Optional) The private key that the Apache virtual host will use (defaults to
/etc/ssl/private/ssl-cert-snakeoil.key).

##### `cert_file`

(Optional) The certificate that the Apache virtual host will use (defaults to
/etc/ssl/certs/ssl-cert-snakeoil.crt).

##### `ca_file`

(Optional) The CA certificate that the Apache virtual host will use (defaults
to /etc/ssl/certs/ca-certificate.crt).

## Limitations

There may be incompatibilities with other OS versions, packages and
configurations.

## Development

We are happy to receive pull requests. 
