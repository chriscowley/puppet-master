node basenode {
  hiera_include('classes')
}

node default inherits basenode {
}

