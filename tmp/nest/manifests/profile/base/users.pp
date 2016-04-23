class nest::profile::base::users {
  file { '/bin/zsh':
    ensure => file,
  }

  package { 'app-shells/zsh':
    ensure => installed,
  }

  group { 'users':
    gid => '1000',
  }

  user {
    'root':
      shell   => '/bin/zsh',
      require => File['/bin/zsh'];

    'james':
      uid     => '1000',
      gid     => 'users',
      groups  => ['wheel'],
      home    => '/home/james',
      comment => 'James Lee',
      shell   => '/bin/zsh',
      require => Package['app-shells/zsh'];
  }

  file {
    '/root/.keep':
      ensure => absent;

    '/home/james':
      ensure => directory,
      mode   => '0755',
      owner  => 'james',
      group  => 'users';
  }

  vcsrepo {
    default:
      ensure   => latest,
      provider => git,
      source   => 'https://github.com/MrStaticVoid/profile.git',
      revision => 'master';

    '/root':
      require  => File['/root/.keep'];

    '/home/james':
      user     => 'james',
      require  => File['/home/james'];
  }

  file {
    default:
      mode      => '0600',
      content   => $::nest::ssh_private_key,
      show_diff => false;

    '/root/.ssh/id_rsa':
      owner     => 'root',
      group     => 'root',
      require   => Vcsrepo['/root'];

    '/home/james/.ssh/id_rsa':
      owner     => 'james',
      group     => 'users',
      require   => Vcsrepo['/home/james'];
  }

  file {
    default:
      mode    => '0644',
      content => "${::nest::ssh_public_key}\n";

    '/root/.ssh/id_rsa.pub':
      owner   => 'root',
      group   => 'root',
      require => Vcsrepo['/root'];

    '/home/james/.ssh/id_rsa.pub':
      owner   => 'james',
      group   => 'users',
      require => Vcsrepo['/home/james'];
  }
}
