class nest::role::workstation::sway {
  nest::lib::package_use { 'gui-wm/sway':
    use => ['-swaybar'],
  }

  package { [
    'gui-wm/sway',
    'gui-apps/waybar',
    'app-misc/jq',            # for interacting with swaymsg
    'gui-apps/wl-clipboard',  # for tmux-yank
    'gui-apps/wtype',         # for simulating keyboard input
  ]:
    ensure => installed,
  }

  # Sway will scale the display to our gui_scaling_factor, but we need
  # to change the DPI to effect our text_scaling_factor
  $gui_scaling_factor  = $::nest::gui_scaling_factor
  $text_scaling_factor = $::nest::text_scaling_factor
  $dpi       =   0 + inline_template('<%= ((@text_scaling_factor / @gui_scaling_factor) * 96.0).round %>')
  $dpi_scale = 0.0 + inline_template('<%= (@text_scaling_factor / @gui_scaling_factor).round(3) %>')

  $sway_wrapper_content = @("END_WRAPPER"/$)
    #!/bin/bash
    # Workaround https://github.com/swaywm/sway/issues/3109
    exec "\$SHELL" -c "env GDK_DPI_SCALE=${dpi_scale} QT_FONT_DPI=${dpi} XDG_CURRENT_DESKTOP=sway /usr/bin/sway \${*@Q}"
    | END_WRAPPER

  file { '/usr/local/bin/sway':
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => $sway_wrapper_content,
  }

  $xresources_content = @("XRESOURCES")
    Xft.dpi: $dpi
    | XRESOURCES

  file { '/etc/sway/Xresources':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => $xresources_content,
    require => Package['gui-wm/sway'],
  }

  $xkb_variant = $::nest::dvorak ? {
    true    => "input type:keyboard xkb_variant dvorak\n",
    default => '',
  }

  $xkb_options = $::nest::swap_alt_win ? {
    true    => "input type:keyboard xkb_options ctrl:nocaps,altwin:swap_alt_win",
    default => "input type:keyboard xkb_options ctrl:nocaps",
  }

  $input_conf = @("INPUT_CONF")
    input type:keyboard xkb_layout us
    ${xkb_variant}${xkb_options}
    input type:touchpad tap enabled
    input 9011:26214:ydotoold_virtual_device xkb_variant basic
    | INPUT_CONF

  # XXX: According to sway-output(5), this needs to account for scaling
  $monitors_conf = $::nest::monitor_layout.reduce("") |$memo, $monitor| {
    if $monitor =~ /([^@]+)@(\d+)$/ {
      "${memo}output ${1} position ${2} 0\n"
    } else {
      $memo
    }
  }

  $output_conf = @("OUTPUT_CONF")
    output * scale $::nest::gui_scaling_factor
    output * subpixel rgb
    ${monitors_conf}
    | - OUTPUT_CONF

  file {
    default:
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    ;

    '/etc/sway/config.d':
      ensure => directory,
      require => Package['gui-wm/sway'],
    ;

    '/etc/sway/config.d/10-cursor':
      content => "seat seat0 xcursor_theme breeze_cursors 24\n",
    ;

    '/etc/sway/config.d/10-input':
      content => $input_conf,
    ;

    '/etc/sway/config.d/10-output':
      content => $output_conf,
    ;

    '/etc/sway/config.d/10-xwayland':
      content => epp('nest/sway/xwayland.epp', { 'dvorak' => $::nest::dvorak }),
    ;
  }
}
