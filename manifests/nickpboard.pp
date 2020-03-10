# Manifest for puppetboard using puppet/puppetboard
# link https://forge.puppet.com/puppet/puppetboard
class afl_profiles::nickpboard {
  # Define the URL for the puppetboard server
  $hiera_vhost_name = lookup('encore::puppet_board::vhost')

  # configure apache
  class { '::apache':
    purge_configs => false,
    mpm_module    => 'prefork',
    default_vhost => false,
    default_mods  => false,
  }

  contain ::apache
  class { '::apache::mod::wsgi':
    wsgi_socket_prefix => '/var/run/wsgi',
  }

  contain ::apache::mod::wsgi

  # Create mime.types to prevent apache startup failure
  file { '/etc/httpd/conf/mime.types':
    ensure  => file,
    path    => '/etc/httpd/conf/mime.types',
    content => '# Default',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  include ::puppetdb::params
  # configure PuppetBoard
  class { '::puppetboard':
    default_environment => '*',
    enable_catalog      => true,
    # add the puppetboard user to the puppet group so it can read the SSL certs below
    groups              => ['puppet'],
    manage_git          => true,
    manage_selinux      => false,
    manage_virtualenv   => true,
    reports_count       => 40,
    # allow to be used in isolated network environments
    offline_mode        => true,
    # use the FQDN instead of 'localhost' for ssl verification
    puppetdb_host       => $::fqdn,
    # auto convert string to integer
    puppetdb_port       => $::puppetdb::params::ssl_listen_port + 0,
    puppetdb_key        => "/etc/puppetlabs/puppet/ssl/private_keys/${::fqdn}.pem",
    puppetdb_ssl_verify => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    puppetdb_cert       => "/etc/puppetlabs/puppet/ssl/certs/${::fqdn}.pem",
  }

  contain ::puppetboard
  # enable LDAP auth
  class { '::puppetboard::apache::vhost':
    vhost_name               => $hiera_vhost_name,
    port                     => 443,
    ssl                      => true,
    ssl_cert                 => '/etc/pki/tls/certs/puppetboard.crt',
    ssl_key                  => '/etc/pki/tls/private/puppetboard.key',
    # setup this whole block just to add
    # LDAPReferrals off
    custom_apache_parameters => {
      directories => {
        provider        => 'directory',
        path            => "${puppetboard::params::basedir}/puppetboard",
        options         => ['Indexes','FollowSymLinks','MultiViews'],
        allow_override  => ['None'],
        directoryindex  => '',
        custom_fragment => 'LDAPReferrals off',
      },
    },

    enable_ldap_auth         => true,
    ldap_url                 => $hiera_ldap_url,
    ldap_bind_dn             => $hiera_ldap_bind_dn,
    ldap_bind_password       => $hiera_ldap_bind_password,
    ldap_require_group       => true,
    ldap_require_group_dn    => $hiera_ldap_group,
  }

  # when Puppetboard changes, make sure to refresh the Apache service
  Class['::puppetboard']
  ~> Class['::apache::service']
}
