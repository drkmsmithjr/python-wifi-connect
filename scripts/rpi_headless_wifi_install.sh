#!/usr/bin/env bash

echo "This script is will install NetworkManager on a headless (wifi) connected >"
echo "It verifies NetworkManager is installed."
echo "If not, installs it (and in the process disables the dhcpcd service)"
echo " This script will work with raspbian 11 (bullseye) version"

check_os_version () {
    if [[ "$OSTYPE" != "linux"* ]]; then
        echo "ERROR: This application only runs on Linux."
        exit 1
    fi

    local _version=""
    if [ -f /etc/os-release ]; then
        _version=$(grep -oP 'VERSION="\K[^"]+' /etc/os-release)
    fi
    if [ "$_version" != "11 (bullseye)" ] && [ "$_version" != "12 (bookworm)" ]; then
        echo "ERROR: Distribution not based on Raspbian 11 (bullyeye)."
        exit 1
    fi
    echo $_version
}

# install manager enables the Network Manager but does not start until reboot.   

install_network_manager () {
    echo "Updating Raspberry pi package list..."
    apt-get -y update

    echo "Downloading and installing NetworkManager..."
    apt-get install -y network-manager
    
    echo "enabling Network Manager"
    systemctl enable NetworkManager
    echo "disabling dhcpcd..."
    systemctl disable dhcpcd

    # sleeping for 30 seconds
    #echo "Sleeping 30 seconds to push process into background"
    #echo " and allow wifi to drop: use ctrl+z (get job#), bg %job#, disown %job#"
    #/bin/sleep 30

    #echo "Stopping dhcpcd..."
    #systemctl stop dhcpcd
    
    #echo "starting Network Manager"
    #systemctl start NetworkManager
    #echo " sleeping 15 seconds to allow Network Manager to collect SSID"
    #/bin/sleep 15
    #echo "now add the wifi command"
    #nmcli dev wifi connect SSID password "SSID password"
    
    # logging into 

    #echo "Installing NetworkManager..."
    #apt-get install -y network-manager
    #apt-get clean
}

# check if we're on debian 11 or 12, all other are not accepted.
VERSION=$(check_os_version)

# Confirm the user wants to install...
#read -r -p "Do you want to install? [y/N]: " response
#response=${response,,}  # convert to lowercase
#if [[ ! $response =~ ^(yes|y)$ ]]; then
#    exit 0
#fi

# Update packages and install
install_network_manager

# Save the path to THIS script (before we go changing dirs)
# need to run script from the Script Directory
TOPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# The top of our source tree is the parent of this scripts dir
TOPDIR+=/..
cd $TOPDIR
echo $VERSION
if [ "$VERSION" == "12 (bookworm)" ]; then
    apt-get install -y libglib2.0-dev python-dbus-dev libdbus-1-dev
fi;
# Installing pip3 and venv..  Raspberry lite does not have them
echo "Installing python3-pip ... pip3 required"
apt-get install -y python3-pip
rm /etc/pip.conf
echo "Installing python3-venv ... vend required" 
apt-get install -y python3-venv

# Check if python3 and pip installed correctly
echo "Checking that python3 and pip are installed..."
INSTALL_PATH=`which python3`
if [[ ! -f "$INSTALL_PATH" ]]; then
    echo "ERROR: python3 is not installed."
    exit 1
fi
INSTALL_PATH=`which pip3`
if [[ ! -f "$INSTALL_PATH" ]]; then
    echo "ERROR: pip3 is not installed."
    exit 1
fi

# Remove any existing virtual environment
rm -fr $TOPDIR/venv

# Create a virtual environment (venv)
echo "Creating a python virtual environment..."
python3 -m venv $TOPDIR/venv

# Only install python modules on Linux (they are OS specific).
if [[ "$OSTYPE" == "linux"* ]]; then
    # Use the venv
    source $TOPDIR/venv/bin/activate

    # Install the python modules our app uses into our venv
    echo "Installing python modules..."
    pip3 install -r $TOPDIR/config/requirements.txt --trusted-host www.piwheels.org 

    # Deactivate the venv
    deactivate
fi

echo "crontab replacement"

# Define the filename
tmpfile='tempfile.txt'

#echo $TOPDIR

# read the current crontab (run in sudo mode)
crontab -l > $tmpfile

# test if the crontab does not already have run.sh script 
# if the install script was performed twice, the crontab may already have the script installed. 
cat $tmpfile | grep run.sh

if [[ $? == 1 ]]; then
    echo "updating the crontab with this line:"
    # create the string
    String='@reboot sleep 15 && '
    String+=$TOPDIR
    String+='/scripts/run.sh'

    # print the line
    echo $String

    echo $String >> $tmpfile
 
    crontab $tmpfile
else
    echo "crontab already updated"
fi

rm  $tmpfile

echo "Done. Reboot and use wifi-connect-headless-rpi to attach to local wifi"
echo "Look for SSID Rpi-"$(hostname)" on local wifi rounter" 





