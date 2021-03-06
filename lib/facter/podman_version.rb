Facter.add('podman_version') do
  confine kernel: 'Linux'
  setcode do
    if File.exist?('/usr/bin/podman')
      Regexp.last_match(1) if Facter::Core::Execution.execute('/usr/bin/podman --version') =~ %r{podman version (\S+)}
    end
  end
end
