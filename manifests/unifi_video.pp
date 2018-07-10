class nest::unifi_video {
  include '::nest'
  include '::nest::docker'

  nest::srv { 'unifi-video': }

  file {
    default:
      owner  => 'ubnt',
      group  => 'ubnt',
    ;

    '/srv/unifi-video':
      ensure  => directory,
      mode    => '0775',
      require => Nest::Srv['unifi-video'],
    ;

    '/srv/unifi-video/system.properties':
      ensure  => file,
      mode    => '0664',
      content => "is_default=true\n",
      replace => false,
    ;
  }

  file_line { 'unifi-video-app.http.port':
    path    => '/srv/unifi-video/system.properties',
    line    => 'app.http.port=80',
    match   => '^app\.http\.port=',
    require => File['/srv/unifi-video/system.properties'],
    notify  => Docker::Run['unifi-video'],
  }

  docker_network { 'video':
    ensure  => present,
    driver  => 'macvlan',
    subnet  => '172.22.3.0/24',
    gateway => '172.22.3.1',
    options => "parent=bond0.1003",
  }

  $cpuset = $::nest::availcpus_expanded.join(',')

  docker::run { 'unifi-video':
    image            => 'pducharme/unifi-video-controller',
    net              => 'video',
    dns              => '172.22.3.1',
    env              => [
      'PUID=1002',
      'PGID=1002',
      'TZ=America/New_York',
    ],
    volumes          => [
      '/srv/unifi-video:/var/lib/unifi-video',
      '/nest/cameras:/var/lib/unifi-video/videos',
    ],
    extra_parameters => [
      "--cpuset-cpus=${cpuset}",
      '--ip=172.22.3.2',
      '--cap-add=SYS_ADMIN',
      '--cap-add=DAC_READ_SEARCH',
      '--sysctl net.ipv4.ip_unprivileged_port_start=0',
    ],
    service_provider => 'systemd',
    require          => [
      Docker_network['video'],
      File['/srv/unifi-video'],
    ],
  }
}