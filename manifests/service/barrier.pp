class nest::service::barrier {
  nest::lib::package { 'x11-misc/barrier':
    ensure => installed,
    use    => '-gui',
  }

  firewall { '100 barrier':
    proto   => tcp,
    dport   => 24800,
    iniface => 'virbr0',
    state   => 'NEW',
    action  => accept,
  }

  # XXX: Cleanup from previous dependency on avahi
  file { [
    '/etc/systemd/system/avahi-daemon.service',
    '/etc/systemd/system/avahi-daemon.socket',
  ]:
    ensure => absent,
    notify => Nest::Lib::Systemd_reload['barrier'],
  }

  ::nest::lib::systemd_reload { 'barrier': }
}
