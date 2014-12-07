node basenode {
  hiera_include('classes')
}

node default inherits basenode {
  staging::deploy { 'sensu-community-plugins.tar.gz':
    source => 'https://github.com/sensu/sensu-community-plugins/archive/master.zip',
    target =>  '/opt/sensu-plugins',
  }
  sensu::handler { 'default':
    command => 'mail -s \'sensu alert\' ops@foo.com',
  }
  sensu::check { 'check_cron':
    command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/processes/check-procs.rb -p crond -C 1',
    handlers    => 'default',
    subscribers => 'base',
    require     => Staging::Deploy['sensu-community-plugins.tar.gz'],
  }
  sensu::check { 'check_dns':
    command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/system/check-disk.rb -d google-public-dns-a.google.com -s 192.168.1.2 -r 8.8.8.8',
    handlers    => 'default',
    subscribers => 'base',
    require     => Staging::Deploy['sensu-community-plugins.tar.gz'],
  }
  class { 'rabbitmq':
    port =>  '5672',
  }
}

node 'puppet.chriscowley.lan' inherits basenode {
  class { 'hiera':
    hierarchy => [
      'secure',
      'defaults',
      '%{environment}/%{calling_class}',
      "nodes/%{clientcert}",
      "virtual/%{::virtual}",
      '%{environment}',
      '%{::osfamily}',
      'common',
    ],
    datadir => '/etc/puppet/environments/%{::environment}/hieradata',
    eyaml   => true,
  }
}

node 'monitor.chriscowley.lan' inherits default {
  rabbitmq_user { 'sensu':
    admin    => false,
    password => 'password',

  }
  rabbitmq_vhost { '/sensu':
    ensure => present,
  }
}


node 'ext.chriscowley.lan' inherits default {
  php::ini { '/etc/php.ini':
    memory_limit   => '256M',
    upload_max_filesize => '1G',
    post_max_size       => '1G',
    output_buffering    => '0',
  }

  include php::cli
  php::module { [ 'mbstring', 'gd', 'xml', 'pecl-sqlite', 'pdo']: }
  include php::fpm::daemon
  php::fpm::conf { 'www':
    listen  => '127.0.0.1:9000',
    user    => 'nginx',
  }
}

