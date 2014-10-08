node basenode {
  hiera_include('classes')
}

node default inherits basenode {
}

node 'ext.chriscowley.lan' inherits badenode {
   include php::fpm::daemon
  php::fpm::conf { 'www':
    listen  => '127.0.0.1:9000',
    user    => 'nginx',
    # For the user to exist
    require => Package['nginx'],
  }
}
