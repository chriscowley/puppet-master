node basenode {
  hiera_include('classes')
}

node default inherits basenode {
}

node 'monitor.chriscowley.lan' {
  class { 'sensu':
    rabbitmq_password => 'secret',
    server            => true,
    dashboard         => true,
    api               => true,
    plugins           => [
      'puppet:///data/sensu/plugins/ntp.rb',
    ]
  }
  sensu::handler { 'default':
    command => 'mail -s \'sensu alert\' chris@localhost'
  }
}
