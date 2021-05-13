Facter.add('_nest_is_container') do
  confine :kernel => 'Linux'
  setcode do
    Facter.value(:virtual) == 'lxc' or File.exist? '/run/.containerenv'
  end
end

Facter.add('_nest_machine_id') do
  confine :kernel => 'Linux'
  setcode do
    if File.exist?('/etc/machine-id')
      File.readlines('/etc/machine-id').map(&:chomp).first
    end
  end
end

Facter.add('_nest_podman_version') do
  confine :kernel => 'Linux'
  setcode do
    if File.exist?('/usr/bin/podman')
      $1 if Facter::Core::Execution.execute('/usr/bin/podman --version') =~ /podman version (\S+)/
    end
  end
end

Facter.add('_nest_profile') do
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

Facter.add('_nest_profile') do
  confine :osfamily => 'windows'
  setcode do
    { :role => 'workstation' }
  end
end

Facter.add('_nest_rpool') do
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

Facter.add('_nest_running_live') do
  confine :kernel => 'Linux'
  setcode do
    Facter.value(:mountpoints)['/']['device'] == 'LiveOS_rootfs'
  end
end

# XXX: Remove after upgrade to Facter 4 which can aggregate
# facts automatically with dot notation
Facter.add('nest', :type => :aggregate) do
  chunk(:is_container) do
    is_container = Facter.value(:_nest_is_container)
    defined?(is_container) ? { 'is_container' => is_container } : {}
  end

  chunk(:machine_id) do
    machine_id = Facter.value(:_nest_machine_id)
    defined?(machine_id) ? { 'machine_id' => machine_id } : {}
  end

  chunk(:podman_version) do
    podman_version = Facter.value(:_nest_podman_version)
    defined?(podman_version) ? { 'podman_version' => podman_version } : {}
  end

  chunk(:profile) do
    profile = Facter.value(:_nest_profile)
    defined?(profile) ? { 'profile' => profile } : {}
  end

  chunk(:rpool) do
    rpool = Facter.value(:_nest_rpool)
    defined?(rpool) ? { 'rpool' => rpool } : {}
  end

  chunk(:running_live) do
    running_live = Facter.value(:_nest_running_live)
    defined?(running_live) ? { 'running_live' => running_live } : {}
  end
end
