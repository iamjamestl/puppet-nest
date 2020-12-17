class nest::base::systemd {
  # This exists to ensure other resources that expect to write into this
  # directory come after systemd is installed, which is guaranteed when
  # this class is evaluated because it comes after the portage configuration.
  # Complicated, I know, but it leads to cleaner code overall (without
  # dependencies on the systemd class everywhere).
  file { '/etc/systemd':
    ensure  => directory,
  }

  file { '/etc/hostname':
    content => "${::trusted['certname']}\n",
  }

  # /etc/localtime is just a regular file in the Gentoo stage tarballs.  In
  # that case, remove it and allow it to be set by the File['/etc/localtime']
  # resource; otherwise, this lets me set the timezone manually when I travel
  # without Puppet resetting it back.
  exec { '/bin/rm -f /etc/localtime':
    unless => '/usr/bin/test -L /etc/localtime',
    before => File['/etc/localtime'],
  }

  file { '/etc/localtime':
    ensure  => link,
    target  => '/usr/share/zoneinfo/America/New_York',
    replace => false,
  }

  $nsswitch_id_changes = ['passwd', 'shadow', 'group'].map |$database| {
    [
      "rm database[. = '${database}']/service",
      "set database[. = '${database}']/service files",
    ]
  }

  $nsswitch_hosts_changes = [
    'rm database[. = "hosts"]/*',
    'set database[. = "hosts"]/service[1] files',
    'set database[. = "hosts"]/service[2] resolve',
    'set database[. = "hosts"]/reaction/status UNAVAIL',
    'touch database[. = "hosts"]/reaction/status/negate',
    'set database[. = "hosts"]/reaction/status/action return',
    'set database[. = "hosts"]/service[3] dns',
    'set database[. = "hosts"]/service[4] myhostname',
  ]

  augeas { 'nsswitch':
    context => '/files/etc/nsswitch.conf',
    changes => flatten($nsswitch_id_changes + $nsswitch_hosts_changes),
  }

  unless $::is_container {
    file { '/etc/resolv.conf':
      ensure => link,
      target => '/run/systemd/resolve/stub-resolv.conf',
    }
  }

  file {
    default:
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
    ;

    '/etc/dnssec-trust-anchors.d':
      ensure => directory,
    ;

    '/etc/dnssec-trust-anchors.d/local.negative':
      source => 'puppet:///modules/nest/systemd/dnssec-trust-anchors-local.negative',
      notify => Service['systemd-resolved'],
    ;
  }

  service { 'systemd-resolved':
    enable => true,
  }

  file_line { 'locale.gen-en_US.UTF-8':
    path  => '/etc/locale.gen',
    line  => 'en_US.UTF-8 UTF-8',
    match => '^#?en_US.UTF-8 UTF-8$',
  }

  exec { '/usr/sbin/locale-gen':
    timeout     => 0,
    refreshonly => true,
    subscribe   => File_line['locale.gen-en_US.UTF-8'],
  }

  file { '/etc/locale.conf':
    content => "LANG=en_US.utf8\n",
    require => Exec['/usr/sbin/locale-gen'],
  }

  package { 'media-fonts/terminus-font':
    ensure => installed,
  }

  file {
    default:
      mode  => '0644',
      owner => 'root',
      group => 'root';

    '/usr/share/keymaps/i386/dvorak/dvorak-nocaps.map.gz':
      source => 'puppet:///modules/nest/keymaps/dvorak-nocaps.map.gz';

    '/usr/share/keymaps/i386/dvorak/dvorak-nocaps-swap_alt_win.map.gz':
      ensure => absent;

    '/usr/share/keymaps/i386/qwerty/us-nocaps.map.gz':
      source => 'puppet:///modules/nest/keymaps/us-nocaps.map.gz';

    '/usr/share/keymaps/i386/qwerty/us-nocaps-swap_alt_win.map.gz':
      ensure => absent;
  }

  $keymap = $::nest::dvorak ? {
    true    => 'dvorak-nocaps',
    default => 'us-nocaps',
  }

  $vconsole_conf_content = @("EOT")
    FONT=ter-v${::nest::console_font_size}b
    KEYMAP=${keymap}
    | EOT

  file { '/etc/vconsole.conf':
    content => $vconsole_conf_content,
  }

  file { '/etc/issue':
    content => "\nThis is \\n (\\s \\m \\r) \\t\n\n",
  }

  $availcpus_formatted = $::nest::availcpus_expanded.join(' ')

  $cpu_affinity = $::nest::isolcpus ? {
    undef   => '#CPUAffinity=1 2',  # the default
    default => "CPUAffinity=${availcpus_formatted}",
  }

  $suspend_state = $::platform ? {
    'pinebookpro' => 'SuspendState=freeze',   # TF-A doesn't support deep sleep yet
    default       => '#SuspendState=mem standby freeze',
  }

  file_line {
    default:
      notify => Nest::Lib::Systemd_reload['systemd'],
    ;

    'system.conf-CPUAffinity':
      path  => '/etc/systemd/system.conf',
      line  => $cpu_affinity,
      match => '^#?CPUAffinity=',
    ;

    # Kill all user processes at end of session.
    # This is the default in systemd-230.
    'logind.conf-KillUserProcesses':
      path  => '/etc/systemd/logind.conf',
      line  => 'KillUserProcesses=yes',
      match => '^#?KillUserProcesses=',
    ;

    # There's no real swap on which to hibernate
    'sleep.conf-DisallowHibernation':
      path  => '/etc/systemd/sleep.conf',
      line  => 'AllowHibernation=no',
      match => '^#?AllowHibernation=',
    ;

    'sleep.conf-SuspendState':
      path  => '/etc/systemd/sleep.conf',
      line  => $suspend_state,
      match => '^#?SuspendState',
    ;
  }

  nest::lib::systemd_reload { 'systemd': }

  # Keep james's systemd services (like tmux) running
  file {
    default:
      owner => 'root',
      group => 'root',
      mode  => '0644',
    ;

    '/var/lib/systemd/linger':
      ensure => directory,
    ;

    '/var/lib/systemd/linger/james':
      ensure => file,
    ;
  }

  $kexec_tools_ensure = "${::nest::bootloader}-${facts['architecture']}" ? {
    'systemd-amd64' => installed,
    default         => absent,
  }

  package { 'sys-apps/kexec-tools':
    ensure => $kexec_tools_ensure,
  }
}
