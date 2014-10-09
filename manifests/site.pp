node basenode {
  hiera_include('classes')
}

node default inherits basenode {
}

node 'ext.chriscowley.lan' inherits basenode {
  php::ini { '/etc/php.ini':
    memory_limit   => '256M',
  }

  include php::cli
  php::module { [ 'mbstring', 'gd' ]: }
  include php::fpm::daemon
  php::fpm::conf { 'www':
    listen  => '127.0.0.1:9000',
    user    => 'nginx',
  }
}
