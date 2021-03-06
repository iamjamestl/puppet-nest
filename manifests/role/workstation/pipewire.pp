class nest::role::workstation::pipewire {
  nest::lib::package { 'media-video/pipewire':
    ensure => installed,
    use    => ['aptx', 'ldac'],
  }
  ->
  exec {
    'systemd-enable-pipewire':
      command => '/bin/systemctl --user --global enable pipewire.socket',
      creates => '/etc/systemd/user/sockets.target.wants/pipewire.socket',
    ;

    'systemd-enable-pipewire-pulse':
      command => '/bin/systemctl --user --global enable pipewire-pulse.socket',
      creates => '/etc/systemd/user/sockets.target.wants/pipewire-pulse.socket',
    ;

    'systemd-enable-pipewire-media-session':
      command => '/bin/systemctl --user --global enable pipewire-media-session.service',
      creates => '/etc/systemd/user/pipewire.service.wants/pipewire-media-session.service',
    ;
  }

  nest::lib::package { 'media-sound/pulseaudio':
    ensure => installed,
    world  => false,
  }
  ->
  file_line { 'pulse-client.conf-disable-autospawn':
    path  => '/etc/pulse/client.conf',
    match => '^(; )?autospawn = ',
    line  => 'autospawn = no',
  }
}
