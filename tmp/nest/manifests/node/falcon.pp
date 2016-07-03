class nest::node::falcon {
  include '::nest::apache'
  include '::nest::docker'

  zfs { 'srv':
    name       => "${::trusted['certname']}/srv",
    mountpoint => '/srv',
  }

  zfs { 'srv/plex':
    name       => "${::trusted['certname']}/srv/plex",
    mountpoint => '/srv/plex',
    require    => Zfs['srv'],
  }

  file {
    default:
      ensure  => directory,
      mode    => '0755',
      owner   => 'plex',
      group   => 'media';

    '/srv/plex':
      require => Zfs['srv/plex'];

    '/srv/plex/config':
      # use defaults
      ;
  }

  Docker::Run {
    service_provider => 'systemd',
    after            => 'remote-fs.target',
  }

  docker::run { 'couchpotato':
    image   => 'linuxserver/plex',
    ports   => '32400:32400',
    env     => ['PUID=32400', 'PGID=1001'],
    volumes => [
      '/srv/plex/config:/config',
      '/nest/movies:/movies',
      '/nest/tv:/tv',
    ],
    require => File['/srv/plex/config'],
  }

  apache::vhost { 'plex.nest':
    port       => '32400',
    docroot    => '/var/www/plex.nest',
    proxy_pass => [
      { 'path' => '/', 'url' => 'http://localhost:32400/' },
    ],
  }

  firewall { '012 multicast':
    proto   => udp,
    pkttype => 'multicast',
    action  => accept,
  }

  firewall { '100 crashplan':
    proto  => tcp,
    dport  => 4242,
    state  => 'NEW',
    action => accept,
  }

  firewall { '100 plex':
    proto  => tcp,
    dport  => 32400,
    state  => 'NEW',
    action => accept,
  }
}
