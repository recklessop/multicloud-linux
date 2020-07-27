sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& console=tty0 console=ttyS0,115200n8/' /etc/default/grub
sed -i 's/GRUB_TERMINAL="[^"]*/& console serial/' /etc/default/grub
sed -i '/^GRUB_TERMINAL=.*/a GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"\n' /etc/default/grub

echo 'add_drivers+=" nvme ena "' > /etc/dracut.conf.d/50-zerto.conf

cat << 'EOF' >> /etc/sysconfig/network/ifcfg-eth99
BOOTPROTO='dhcp'
STARTMODE='auto'
DHCLIENT_SET_DEFAULT_ROUTE='yes'
EOF

cat << 'EOF' >> /etc/udev/rules.d/70-persistent-net.rules
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="ena", ATTR{type}=="1", KERNEL=="eth*", NAME="eth99"
EOF

dracut -f -v
grub2-mkconfig -o /boot/grub2/grub.cfg
