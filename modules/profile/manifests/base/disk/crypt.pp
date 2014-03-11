class profile::base::disk::crypt inherits profile::base::disk::base {
    dracut::conf { 'devices':
        boot_devices => ["${disk_id}-part3", "${disk_id}-part4"],
    }

    crypt::device { 'keyfile':
        device => "${disk_id}-part3",
        target => 'keyfile',
        order  => 1,
    }

    crypt::device { 'rpool-crypt0':
        device  => "${disk_id}-part4",
        target  => 'rpool-crypt0',
        keyfile => '/dev/mapper/keyfile',
        order   => 2,
    }

    file { '/etc/local.d/keyfile.start':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/base/disk/keyfile.start',
    }
}
