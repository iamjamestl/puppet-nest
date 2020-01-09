class nest::profile::base::bootloader {
  $kernel_cmdline = [
    'init=/usr/lib/systemd/systemd',
    'quiet',
    'fbcon=scrollback:1024k',
    $::nest::isolcpus ? {
      undef   => [],
      default => [
        "isolcpus=${::nest::isolcpus}",
        "nohz_full=${::nest::isolcpus}",
        "rcu_nocbs=${::nest::isolcpus}",
      ],
    },
    $::nest::kernel_cmdline,
  ].flatten.join(' ').strip

  case $::nest::bootloader {
    systemd: { contain 'nest::profile::base::bootloader::systemd' }
    default: { contain 'nest::profile::base::bootloader::grub' }
  }
}