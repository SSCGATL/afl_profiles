# Main PuppetBaord Profile
class afl_profiles::puppetboard {

  include apache
  include epel

  $puppetboard_certname = $trusted['certname']
  $ssl_dir = '/etc/httpd/ssl'

  file { $ssl_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${ssl_dir}/certs":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${ssl_dir}/private_keys":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  file { "${ssl_dir}/certs/ca.pem":
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "${::settings::ssldir}/certs/ca.pem",
    before => Class['::puppetboard'],
  }

  file { "${ssl_dir}/certs/${puppetboard_certname}.pem":
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "${::settings::ssldir}/certs/${puppetboard_certname}.pem",
    before => Class['::puppetboard'],
  }

  file { "${ssl_dir}/private_keys/${puppetboard_certname}.pem":
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "${::settings::ssldir}/private_keys/${puppetboard_certname}.pem",
    before => Class['::puppetboard'],
  }

  class { '::puppetboard':
    groups              => 'root',
    manage_git          => true,
    manage_virtualenv   => true,
    manage_selinux      => true,
    puppetdb_host       => 'puppetdb.alliancecontrolprogram.com',
    puppetdb_port       => 8081,
    puppetdb_key        => "${ssl_dir}/private_keys/${puppetboard_certname}.pem",
    puppetdb_ssl_verify => "${ssl_dir}/certs/ca.pem",
    puppetdb_cert       => "${ssl_dir}/certs/${puppetboard_certname}.pem",
    reports_count       => 100,
    revision            => 'v1.0.0',
  }

  class { '::puppetboard::apache::vhost':
    vhost_name               => 'puppetboard.alliancecontrolprogram.com',
    port                     => 80,
    custom_apache_parameters => {
      directories => {
        provider       => 'directory',
        path           => '/srv/puppetboard',
        options        => ['Indexes','FollowSymLinks','MultiViews'],
        allow_override => ['None'],
        directoryindex => '',
      }
    }
  }

}
