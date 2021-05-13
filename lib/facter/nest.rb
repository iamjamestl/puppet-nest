Facter.add('nest.is_container') do
  confine :kernel => 'Linux'
  setcode do
    Facter.value(:virtual) == 'lxc' or File.exist? '/run/.containerenv'
  end
end

Facter.add('nest.machine_id') do
  confine :kernel => 'Linux'
  setcode do
    if File.exist?('/etc/machine-id')
      File.readlines('/etc/machine-id').map(&:chomp).first
    end
  end
end

Facter.add('nest.podman_version') do
  confine :kernel => 'Linux'
  setcode do
    if File.exist?('/usr/bin/podman')
      $1 if Facter::Core::Execution.execute('/usr/bin/podman --version') =~ /podman version (\S+)/
    end
  end
end

Facter.add('nest.profile') do
  confine :osfamily => 'Gentoo'
  setcode do
    profile = Facter::Core::Execution.execute('/usr/bin/eselect --brief profile show')
    case profile
    when %r{nest:(\S+)/(\S+)/(\S+)}
      { :cpu => $1, :platform => $2, :role => $3 }
    when %r{nest:(\S+)/(\S+)}
      { :cpu => $1, :platform => $1, :role => $2 }
    end
  end
end

Facter.add('nest.profile') do
  confine :osfamily => 'windows'
  setcode do
    { :role => 'workstation' }
  end
end

Facter.add('nest.rpool') do
  confine :kernel => 'Linux'
  setcode do
    hostname = Facter.value('hostname')
    if File.exist?('/sbin/zfs')
      ["#{hostname}/crypt", hostname].each do |name|
        Facter::Core::Execution.execute("/sbin/zfs list #{name}")
        break name if $? == 0
      end
    else
      hostname
    end
  end
end

Facter.add('nest.running_live') do
  confine :kernel => 'Linux'
  setcode do
    Facter.value(:mountpoints)['/']['device'] == 'LiveOS_rootfs'
  end
end
