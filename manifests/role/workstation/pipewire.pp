class nest::role::workstation::pipewire {
  nest::lib::package_use { 'media-video/pipewire':
    use => ['aptx', 'ldac'],
  }

  package { 'media-video/pipewire':
    ensure => installed,
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
      creates => '/etc/systemd/user/default.target.wants/pipewire-media-session.service',
    ;
  }

  file_line { 'pulse-client.conf-disable-autospawn':
    path  => '/etc/pulse/client.conf',
    match => '^(; )?autospawn = ',
    line  => 'autospawn = no',
  }


  #
  # XXX: Cleanup PulseAudio
  #
  exec { 'systemd-disable-pulseaudio':
    command => '/bin/systemctl --user --global disable pulseaudio.socket',
    onlyif  => '/usr/bin/test -e /etc/systemd/user/sockets.target.wants/pulseaudio.socket',
  }

  package { 'media-sound/pulseaudio-modules-bt':
    ensure => absent,
  }

  file_line { 'pulse-default.pa-include-nest.pa':
    ensure => absent,
    path   => '/etc/pulse/default.pa',
    line   => '.include /etc/pulse/nest.pa',
  }

  file { '/etc/pulse/nest.pa':
    ensure => absent,
  }
}
