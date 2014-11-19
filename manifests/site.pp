node basenode {
  hiera_include('classes')
}

node default inherits basenode {
}

node 'puppet.chriscowley.lan' inherits basenode {
  class { 'hiera':
    hierarchy => [
      '%{environment}/%{calling_class}',
      "nodes/%{clientcert}",
      "virtual/%{::virtual}",
      '%{environment}',
      '"%{::osfamily}"',
      'common',
    ],
    datadir => '/etc/puppet/environments/%{::environment}/hieradata'
  }
}

node 'monitor.chriscowley.lan' inherits basenode {
  sensu::handler { 'default':
    command => 'mail -s \'sensu alert\' ops@foo.com',
  }
  sensu::check { 'check_cron':
    command => '/etc/sensu/plugins/check-procs.rb -p crond -C 1',
    handlers => 'default',
    subscribers => 'webservers',
  }
#
#  sensu::check { 'check_ntp':
#    command     => 'PATH=$PATH:/usr/lib/nagios/plugins check_ntp_time -H pool.ntp.org -w 30 -c 60',
#    handlers    => 'default',
#    subscribers => 'sensu-test'
#  }
}

node 'ext.chriscowley.lan' inherits basenode {
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

