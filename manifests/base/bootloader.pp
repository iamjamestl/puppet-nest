class nest::base::bootloader {
  # For nest::base::console::keymap
  include '::nest::base::console'

  $kernel_cmdline = [
    'init=/lib/systemd/systemd',
    'quiet',
    'loglevel=3',   # must come after 'quiet'

    $::nest::isolate_smt ? {
      true    => "nohz_full=${facts['processorcount'] / 2}-${facts['processorcount'] - 1}",
      default => [],
    },

    # Let I/O preferences be configurable at boot time
    "rd.vconsole.font=ter-v${::nest::console_font_size}b",
    "rd.vconsole.keymap=${::nest::base::console::keymap}",

    # Let kernel swap to compressed memory instead of a physical volume, which
    # is slow and, currently, prone to hanging.  max_pool_percent=100 ensures
    # the OOM killer is invoked before zswap sends pages to physical swap.
    # Physical swap is still useful for hibernation.
    #
    # See: https://github.com/openzfs/zfs/issues/7734
    # See also: nest::base::zfs for workarounds
    'vm.swappiness=100',
    'zswap.enabled=1',
    'zswap.compressor=lzo-rle',
    'zswap.zpool=z3fold',
    'zswap.max_pool_percent=100',

    $::nest::kernel_cmdline,
  ].flatten.join(' ').strip

  case $::nest::bootloader {
    systemd: {
      contain 'nest::base::bootloader::systemd'
    }

    default: {
      contain 'nest::base::bootloader::grub'
    }
  }
}
