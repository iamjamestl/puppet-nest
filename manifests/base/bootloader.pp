class nest::base::bootloader {
  # Either due to kernel version or hardware implementation,
  # z3fold hangs on Pinebook Pro
  $zswap_zpool = $::platform ? {
    'pinebookpro' => 'zbud',
    default       => 'z3fold',
  }

  $kernel_cmdline = [
    'init=/lib/systemd/systemd',
    'quiet',
    'loglevel=3',
    'fbcon=scrollback:1024k',

    # Compress memory and take pressure off of swap-on-zvol,
    # which is otherwise prone to hanging under load
    'zswap.enabled=1',
    'zswap.compressor=lzo-rle',
    "zswap.zpool=${zswap_zpool}",

    $::nest::isolcpus ? {
      undef   => [],
      default => [
        "isolcpus=${::nest::isolcpus}",
        "nohz_full=${::nest::isolcpus}",
        "rcu_nocbs=${::nest::isolcpus}",
      ],
    },

    $::nest::kernel_cmdline_hiera,
  ].flatten.join(' ').strip

  case $::nest::bootloader {
    systemd: {
      contain 'nest::base::bootloader::systemd'
    }

    default: {
      contain 'nest::base::bootloader::grub'

      exec { 'dracut':
        command     => 'version=$(ls /lib/modules | sort -V | tail -1) && dracut --force --kver $version',
        refreshonly => true,
        timeout     => 0,
        provider    => shell,
        notify      => Class['nest::base::bootloader::grub'],
      }
    }
  }
}
