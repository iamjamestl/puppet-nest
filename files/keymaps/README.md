## Generate custom console and GRUB keymaps

See: https://wiki.archlinux.org/index.php/Talk:GRUB#Custom_keyboard_layout
See: http://www.kaufmann.no/roland/dvorak/linux.html

```
./ckbcomp -layout us -option ctrl:nocaps | gzip > us-nocaps.map.gz
./ckbcomp -layout us -variant dvorak -option ctrl:nocaps | gzip > dvorak-nocaps.map.gz
gzip -dc dvorak-nocaps.map.gz | grub-mklayout -o dvorak.gkb
```

The Linux console treats Alt and Super the same, so there is no need to make a
separate swap_alt_win keymap for that option.

GRUB doesn't manage the caps lock key, so there is no point in making a US
keymap for it.
