class profile::base::disk::base {
    $disk_id        = $profile::base::disk_id
    $disk_mirror_id = $profile::base::disk_mirror_id

    class { 'profile::base::disk::zfs': }

    if $virtual == 'physical' {
        class { 'smart': }
    }

    fstab::fs { 'boot':
        device     => "${disk_id}1",
        mountpoint => '/boot',
        type       => 'ext2',
        options    => 'noatime',
        dump       => 1,
        pass       => 2
    }

    fstab::fs { 'swap':
        device     => '/dev/zvol/rpool/swap',
        mountpoint => 'none',
        type       => 'swap',
        options    => 'discard',
    }

    grub::install { $disk_id: }
}
