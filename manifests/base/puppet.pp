class nest::base::puppet {
  $dns_alt_names = $::nest::openvpn_server ? {
    true    => [$::nest::openvpn_hostname],
    default => [],
  }

  class { '::puppet':
    dns_alt_names => $dns_alt_names,
  }

  if $facts['osfamily'] == 'Gentoo' {
    $facter_conf = @(FACTER_CONF)
      global : {
          external-dir : [ "/etc/puppetlabs/facter/facts.d" ]
      }
      | FACTER_CONF

    file { '/etc/puppetlabs/facter/facter.conf':
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => $facter_conf,
    }

    $scaling_facts = @("SCALING_FACTS")
      ---
      scaling:
        gui: ${::nest::gui_scaling_factor}
        text: ${::nest::text_scaling_factor}
      | SCALING_FACTS

    file { '/etc/puppetlabs/facter/facts.d/scaling.yaml':
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      content => $scaling_facts,
    }
  }
}