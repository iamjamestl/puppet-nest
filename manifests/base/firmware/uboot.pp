class nest::base::firmware::uboot {
  # For nest::base::portage::makeopts
  include '::nest::base::portage'

  Nest::Lib::Kconfig {
    config => '/usr/src/u-boot/.config',
  }

  $uboot_branch = $facts['profile']['platform'] ? {
    'pinebookpro' => 'pinebookpro',
    default       => 'main',
  }

  vcsrepo { '/usr/src/u-boot':
    ensure   => latest,
    provider => git,
    source   => 'https://gitlab.james.tl/nest/forks/u-boot.git',
    revision => $uboot_branch,
  }
  ~>
  exec { '/bin/rm -f /usr/src/u-boot/.config':
    refreshonly => true,
  }

  $defconfig = $facts['profile']['platform'] ? {
    'beagleboneblack' => 'am335x_evm_defconfig',
    'pinebookpro'     => 'pinebook-pro-rk3399_defconfig',
    'raspberrypi'     => 'rpi_arm64_defconfig',
    'sopine'          => 'sopine_baseboard_defconfig',
  }

  exec { 'uboot-defconfig':
    command => "/usr/bin/make ${defconfig}",
    cwd     => '/usr/src/u-boot',
    creates => '/usr/src/u-boot/.config',
    require => Vcsrepo['/usr/src/u-boot'],
  }

  nest::lib::kconfig {
    # Always use default environment to avoid divergence
    'CONFIG_ENV_IS_NOWHERE':
      value => y;
    'CONFIG_ENV_IS_IN_FAT':
      value => n,
    ;
  }

  case $facts['profile']['platform'] {
    'pinebookpro': {
      $build_options = 'BL31=/usr/src/arm-trusted-firmware/build/rk3399/release/bl31/bl31.elf'

      nest::lib::kconfig {
        # May want to use SPI for other things
        'CONFIG_ENV_IS_IN_SPI_FLASH':
          value => n,
        ;

        # Disable unstable USB 1.1 support
        # See: https://lists.denx.de/pipermail/u-boot/2020-November/433070.html
        # See: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=973323
        # See: https://gitlab.manjaro.org/manjaro-arm/packages/core/uboot-rockpro64/-/issues/4
        'CONFIG_USB_OHCI_HCD':
          value => n,
        ;
      }
    }

    'raspberrypi': {
      # Fails with "Unknown partition table type 0"
      nest::lib::kconfig { 'CONFIG_MMC_SDHCI_SDMA':
        value => n,
      }
    }

    'sopine': {
      $build_options = 'BL31=/usr/src/arm-trusted-firmware/build/sun50i_a64/release/bl31.bin SCP=/dev/null'
    }
  }

  exec { 'uboot-olddefconfig':
    command     => '/usr/bin/make olddefconfig',
    cwd         => '/usr/src/u-boot',
    refreshonly => true,
  }
  ~>
  exec { 'uboot-build':
    command     => "/usr/bin/make ${::nest::base::portage::makeopts} ${build_options}",
    cwd         => '/usr/src/u-boot',
    path        => ['/usr/lib/distcc/bin', '/usr/bin', '/bin'],
    environment => 'HOME=/root',  # for distcc
    timeout     => 0,
    # just attempt once per config change
    refreshonly => true,
    noop        => !$facts['build'],
  }

  Exec['uboot-defconfig']
  -> Nest::Lib::Kconfig <| config == '/usr/src/u-boot/.config' |>
  ~> Exec['uboot-olddefconfig']
}
