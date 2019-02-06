#!/bin/bash
# Multi-Cloud Linux Prep Script
#         For
# Redhat 7.x and CentOS 7.x
#
# Written by Justin Paul (@recklessop)
# https://jpaul.me
#
# Note that this script was designed on a new RHEL 7.x system. Inspect it before running it on a production system.


# Let's first add some color
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

# Define a few functions
get_script_dir () {
     SOURCE="${BASH_SOURCE[0]}"
     while [ -h "$SOURCE" ]; do
          DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     done
     $( cd -P "$( dirname "$SOURCE" )" )
     pwd
}

# Start the actual script 

echo "${green}Phase 1 - Verify OS Flavor and Verify RedHat Subscription${reset}"
ostype=0
if [ $(hostnamectl | grep -cE "Red Hat") -eq 1 ]
then
    ostype=1
    echo "${yellow}OS Type appears to be Red Hat${reset}"
elif [ $(hostnamectl | grep -cE 'CentOS') -eq 1 ]
then
    ostype=2
    echo "${yellow}OS Type appears to be CentOS${reset}"
else
    echo "${red}OS type doesn't appear to be RedHat or CentOS, exiting...${reset}"
    exit 1
fi

if [ $ostype -eq 1 ]
then
    echo "${yellow}Checking to see if system is subscribed to RHEL repos${reset}"
    if [ $(subscription-manager status | grep -c 'Current') -eq 0 ]
    then
        echo "${red}No valid subscription found, please register the system so we can get packages, exiting...${reset}"
    fi
    echo "${yellow}System appears to be under current Subscription${reset}"
fi

echo "${green}Phase 2 - Enable extra Package Repos${reset}"
if [ $ostype -eq 1 ]
then # enable repos for RHEL
    echo "${yellow}Enabling RHEL Optional and Extra RPM repos...${reset}"
    subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
    #rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
    echo "${yellow}Installing EPEL repo...${reset}"
    yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
    #rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
else
    # enable repos for CentOS
    echo "${yellow}Installing EPEL repo for CentOS...${reset}"
    yum install epel-release -y
    rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
fi

echo "${yellow}Adding Ngompa's Netplan epel repo...{$reset}"

cat > /etc/yum.repos.d/netplan.repo <<EOF
[ngompa-Netplan]
name=Copr repo for Netplan owned by ngompa
baseurl=https://copr-be.cloud.fedoraproject.org/results/ngompa/Netplan/epel-7-\$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/ngompa/Netplan/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1cd
EOF

echo "${green}Phase 3 - Install Required Packages${reset}"
echo "${yellow}Installing dependencies${reset}"
yum install python34 python34-PyYAML git -y
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

echo "${yellow}Installing Netplan and systemd-networkd and systemd-resolved{$reset}"
yum install netplan systemd-networkd systemd-resolved -y
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

echo "${green}Phase 4 - Get example netplan yaml files${reset}"
cd $(get_script_dir)
git clone https://github.com/recklessop/netplancfg.git $PWD/netplancfg 
cp $PWD/netplancfg/ubuntu/*.yaml /etc/netplan/
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi


echo "${green}Phase 5 - Enable Systemd services${reset}"
systemctl enable systemd-networkd
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
systemctl enable systemd-resolved
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
systemctl start systemd-networkd
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
systemctl start systemd-resolved
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

echo "${green}Phase 6 - Remove NetworkManager and replace resolv.conf${reset}"
echo "${yellow}Removing NetworkManager...${reset}"
yum erase NetworkManager -y
rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi

echo "${yellow}Symlinking /etc/resolv.conf to /run/systemd/resolv/resolv.conf"
echo "(which is configured from your Netplan YAML files)...${reset}"
rm /etc/resolv.conf
cd /etc
ln -s /run/systemd/resolve/resolv.conf


echo "${green}Phase 7 - Add Drivers to dracut and rebuild initramfs${reset}"
echo "${yellow}Adding drivers to dracut configuration file...${reset}"
cat >> /etc/dracut.conf <<EOF
add_drivers+=" hv_vmbus hv_netvsc hv_storvsc nvme ena xen_blkfront xen_netfront mptbase mptscsih mptspi "
EOF

echo "${yellow}Rebuilding Dracut${reset}"
dracut -f -v

echo "${green}Phase 9 - Update Grub options and rebuild Grub${reset}"
echo "${yellow}Replacing grub cmdline options...${reset}"
sed -i -e s/"rhgb quiet"/"rootdelay=300 console=ttyS0 console=tty0 earlyprintk=ttyS0"/ /etc/default/grub
echo "${yellow}Running update-grub${reset}"
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "${green}Congrats your system has been prepared!"
echo "${red}!Please! edit /etc/netplan/50-vmware-static.yaml with the correct mac address and ip information before doing anything else!!!{$reset}"
echo " "
echo "${yellow}Once you have edited your on-premises YAML config you need to run the following commands as root (or sudo)\n
sudo netplan --debug generate\n
sudo netplan --debug apply\n
\n
Failing to do this means your machine will get a bogus 172.16.1.x address.${reset}"




