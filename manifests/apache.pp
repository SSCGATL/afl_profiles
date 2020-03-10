# Main Apache profile Class
class afl_profiles::apache {

  class { 'apache': }
  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => '/var/run/wsgi',
  }

}
