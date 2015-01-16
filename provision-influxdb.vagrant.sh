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
readonly GRAFANA_URL="http://grafanarel.s3.amazonaws.com/"
readonly GRAFANA_FILE="grafana-1.9.1.tar.gz"

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

install_grafana_fn() {
    wget ${GRAFANA_URL}${GRAFANA_FILE} >> ${LOGFILE}
    PWD=`pwd`
    # has to be hardcoded becuz of the startup script
    mdkir -p grafana
    cd grafana
    tar -xvf /home/vagrant/${GRAFANA_FILE}
    cd ${PWD}
}

setup_webserver_fn() {
    cat > /etc/init.d/grafana <<"EOF"
#!/bin/bash
case "$1" in
   start)
      PWD=`pwd`
      cd /home/vagrant/grafana/grafana-1.9.1
      python -m SimpleHTTPServer 7777 &
      cd ${PWD}
      ;;
   *)
     echo "you can start simpleHTTPServer for grafana with start - but after that yer on yer own"
esac
EOF
    chmod +x /etc/init.d/grafana
    sudo update-rc.d influxdb defaults
}

configure_grafana_to_use_influxdb_fn() {
cat > /home/vagrant/grafana/grafana-1.9.1/config.js <<"EOF"
// == Configuration
// config.js is where you will find the core Grafana configuration. This file contains parameter that
// must be set before Grafana is run for the first time.

define(['settings'], function(Settings) {
  

  return new Settings({

      /* Data sources
      * ========================================================
      * Datasources are used to fetch metrics, annotations, and serve as dashboard storage
      *  - You can have multiple of the same type.
      *  - grafanaDB: true    marks it for use for dashboard storage
      *  - default: true      marks the datasource as the default metric source (if you have multiple)
      *  - basic authentication: use url syntax http://username:password@domain:port
      */

      // InfluxDB example setup (the InfluxDB databases specified need to exist)
      
      datasources: {
        influxdb: {
          type: 'influxdb',
          url: "http://my_influxdb_server:8086/db/testing",
          username: 'root',
          password: 'root',
        },
        grafana: {
          type: 'influxdb',
          url: "http://my_influxdb_server:8086/db/grafana",
          username: 'root',
          password: 'root',
          grafanaDB: true
        },
      },
      

      // Graphite & Elasticsearch example setup
      /*
      datasources: {
        graphite: {
          type: 'graphite',
          url: "http://my.graphite.server.com:8080",
        },
        elasticsearch: {
          type: 'elasticsearch',
          url: "http://my.elastic.server.com:9200",
          index: 'grafana-dash',
          grafanaDB: true,
        }
      },
      */

      // OpenTSDB & Elasticsearch example setup
      /*
      datasources: {
        opentsdb: {
          type: 'opentsdb',
          url: "http://opentsdb.server:4242",
        },
        elasticsearch: {
          type: 'elasticsearch',
          url: "http://my.elastic.server.com:9200",
          index: 'grafana-dash',
          grafanaDB: true,
        }
      },
      */

      /* Global configuration options
      * ========================================================
      */

      // specify the limit for dashboard search results
      search: {
        max_results: 100
      },

      // default home dashboard
      default_route: '/dashboard/file/default.json',

      // set to false to disable unsaved changes warning
      unsaved_changes_warning: true,

      // set the default timespan for the playlist feature
      // Example: "1m", "1h"
      playlist_timespan: "1m",

      // If you want to specify password before saving, please specify it below
      // The purpose of this password is not security, but to stop some users from accidentally changing dashboards
      admin: {
        password: ''
      },

      // Change window title prefix from 'Grafana - <dashboard title>'
      window_title_prefix: 'Grafana - ',

      // Add your own custom panels
      plugins: {
        // list of plugin panels
        panels: [],
        // requirejs modules in plugins folder that should be loaded
        // for example custom datasources
        dependencies: [],
      }

    });
});
EOF
}

function configure_vagrant_fn() {
    touch /var/vagrant_provision
}

function main {
    should_provision_fn
    add_basic_apps_fn
    install_influxdb_fn
    configure_influxdb_fn
    install_grafana_fn
    setup_webserver_fn
    configure_grafana_to_use_influxdb_fn
    configure_vagrant_fn
    echo "Installation finished" >> ${LOGFILE}
}

main
 
