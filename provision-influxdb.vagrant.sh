#!/bin/bash

## Try and make the bash work safely
# Terminate on unitiialised variables
set -u
# Terminate on error
set -e
# Terminate if any part of a pipeline fails
set -o pipefail

# Uncomment for debugging
set -x

## Define the global variables
readonly LOGFILE="/root/vagrant.provision.log"
readonly INFLUXDB_URL="http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb"

function should_provision_fn () {
    if [ -f  "/var/vagrant_provision" ]; then
	   exit 0
    fi
}

function log_fn() {
    String=$1
    echo $String >> ${LOGFILE}
}

function add_basic_apps_fn() {

    log_fn "Adding basic apps"

    sed -i 's/#deb/deb/g' /etc/apt/sources.list 
    sed -i 's/deb cdrom/# deb cdrom/g' /etc/apt/sources.list
    sudo apt-get -y update >> ${LOGFILE}
    sudo apt-get -y install emacs24 ntp git-core lynx-cur dbus-x11 gnome-icon-theme firefox chromium-browser >> ${LOGFILE}
}

function install_influxdb_fn() {
    echo "getting and building influxdb" >> ${LOGFILE}
    wget ${INFLUXDB_URL} >> ${LOGFILE}
    sudo dpkg -i influxdb_latest_amd64.deb  >> ${LOGFILE}
}


function configure_influxdb_fn() {
    sudo echo "influxdb soft nofile 65536" >> /etc/security/limits.conf
    sudo echo "influxdb hard nofile 65536" >> /etc/security/limits.conf
    # make influxdb start on boot
    sudo update-rc.d influxdb defaults
}


function configure_vagrant_fn() {
    touch /var/vagrant_provision
}

function main {
    should_provision_fn
    add_basic_apps_fn
    install_influxdb_fn
    configure_influxdb_fn
    configure_vagrant_fn
    echo "Installation finished" >> ${LOGFILE}
}

main
 