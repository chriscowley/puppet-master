node basenode {
  hiera_include('classes')
}

node default inherits basenode {
  package { 'wget':
    ensure => installed,
  }
  package { 'bind-utils':
    ensure => installed,
  }
  file { '/opt/sensu-plugins':
    ensure  => directory,
    require => Package['wget']
  }
  staging::deploy { 'sensu-community-plugins.tar.gz':
    source  => 'https://github.com/sensu/sensu-community-plugins/archive/master.tar.gz',
    target  => '/opt/sensu-plugins',
    require => File['/opt/sensu-plugins'],
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
    command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/dns/check-dns.rb -d google-public-dns-a.google.com -s 192.168.1.2 -r 8.8.8.8',
    handlers    => 'default',
    subscribers => 'base',
    require     => Staging::Deploy['sensu-community-plugins.tar.gz'],
  }
  sensu::check { 'check_disk':
    command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/system/check-disk.rb',
    handlers    => 'default',
    subscribers => 'base',
    require     => Staging::Deploy['sensu-community-plugins.tar.gz'],
  }
}

node 'puppet.chriscowley.lan' inherits default {
  class { 'hiera':
    hierarchy => [
      'secure',
      'defaults',
      '%{environment}/%{calling_class}',
      'nodes/%{clientcert}',
      'virtual/%{virtual}',
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
  $uchiwa_api_config = [{
    host    => 'monitor.chriscowley.lan',
    name    => 'Site 1',
    port    => '4567',
    timeout => '5',
  }]

  class { 'uchiwa':
    install_repo        => false,
    sensu_api_endpoints => $uchiwa_api_config,
    user                => 'admin',
    pass                => 'secret',
  }
}

node 'ci.chriscowley.lan' inherits default {
  class {'network::global':
    gateway => '192.168.1.1',
  }
  network::if::static { 'eth0':
    ensure     => 'up',
    ipaddress  => '192.168.1.10',
    netmask    => '255.255.255.0',
    dns1       => '192.168.1.1',
    macaddress => $::macaddress_eth0,
    domain     => 'chriscowley.lan',
  }
}

node 'ext.chriscowley.lan' inherits default {
  php::ini { '/etc/php.ini':
    memory_limit        => '256M',
    upload_max_filesize => '1G',
    post_max_size       => '1G',
    output_buffering    => '0',
  }

  include php::cli
  php::module { [ 'mbstring', 'gd', 'xml', 'pecl-sqlite', 'pdo']: }
  include php::fpm::daemon
  php::fpm::conf { 'www':
    listen                    => '/var/run/php5-fpm.sock',
    user                      => 'nginx',
    request_terminate_timeout => '300',
    listen_owner              => 'nginx',
    listen_group              => 'nginx',
  }
}

node 'store.chriscowley.lan' inherits default {
  docker::image { 'base':
    ensure => 'absent',
  }
  docker::image { 'centos':
    image_tag => 'centos7',
  }
  docker::image { 'ubuntu':
    image_tag => 'trusty',
  }
}
