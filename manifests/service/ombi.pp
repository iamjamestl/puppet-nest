class nest::service::ombi {
  # Required for ombi user
  include 'nest'

  nest::lib::srv { 'ombi':
    mode  => '0755',
    owner => 'ombi',
    group => 'media',
  }
  ->
  file { '/srv/ombi/config':
    ensure => directory,
    mode   => '0755',
    owner  => 'ombi',
    group  => 'media',
  }
  ->
  nest::lib::container { 'ombi':
    image   => 'linuxserver/ombi',
    dns     => '172.22.0.1',
    env     => ['PUID=3579', 'PGID=1001', 'TZ=America/New_York'],
    publish => ['3579:3579'],
    volumes => ['/srv/ombi/config:/config'],
  }
}
