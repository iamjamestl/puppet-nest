class nest::base::zfs {
  nest::lib::package { 'sys-fs/zfs':
    ensure => installed,
    use    => 'kernel-builtin'
  }

  $zfs_mount_override = @(EOF)
    [Service]
    ExecStart=
    ExecStart=/sbin/zfs mount -al
    | EOF

  file {
    default:
      mode  => '0644',
      owner => 'root',
      group => 'root',
    ;

    '/etc/systemd/system/zfs-mount.service.d':
      ensure => directory,
    ;

    '/etc/systemd/system/zfs-mount.service.d/10-load-key.conf':
      content => $zfs_mount_override,
      notify  => Nest::Lib::Systemd_reload['zfs'],
    ;
  }

  nest::lib::systemd_reload { 'zfs': }

  unless $facts['is_container'] or $facts['running_live'] {
    exec { 'zgenhostid':
      command => '/sbin/zgenhostid `hostid`',
      creates => '/etc/hostid',
      require => Package['sys-fs/zfs'],
      notify  => Class['::nest::base::dracut'],
    }
  }

  # On systems without ZFS root, the zfs module doesn't get loaded by dracut
  file { '/etc/modules-load.d/zfs.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => "zfs\n",
  }

  # See: https://github.com/zfsonlinux/zfs/blob/master/etc/systemd/system/50-zfs.preset.in
  service { [
    'zfs-import-cache.service',
    'zfs-mount.service',
    'zfs-share.service',
    'zfs-zed.service',
    'zfs.target',
  ]:
    enable  => true,
    require => Package['sys-fs/zfs'],
  }

  unless $facts['is_container'] or $facts['running_live'] {
    exec { 'generate-zpool-cache':
      command => "/sbin/zpool set cachefile= ${trusted['certname']}",
      creates => '/etc/zfs/zpool.cache',
    }

    # Manage swap volume properties for experimenting with workarounds listed in
    # https://github.com/openzfs/zfs/issues/7734
    zfs { "${facts['rpool']}/swap":
      compression    => 'off',
      sync           => 'standard',
      primarycache   => 'metadata',
      secondarycache => 'none',
      logbias        => 'throughput',
    }
  }
}
