define nest::lib::systemd_reload {
  unless $facts['nest']['is_container'] {
    exec { "systemd-daemon-reload-${name}":
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true,
    }
  }
}
