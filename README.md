README
------

Uses vagrant to build a 64-bit Ubuntu box and install influxdb
http://influxdb.com


Vagrant can be got from:
https://www.vagrantup.com

Installation
------------

Go to a directory in your machine where you plan to install the operating system image and run the following command:
`vagrant init`

This will create a Vagrantfile and prepare the directory. Then copy the contents of this project into that directory

Look over the `Vagrantfile` and make any changes. These might be:
* changing the shared file mount point under synced_folder
* rebind things to different ports becuz

Look over the `provision-influxdb.vagrant.sh` file and make any changes. These might be:
* add new packages in the `add_basic_apps_fn`

Running
-------

To start the box run go to the directory on your mahcine that you have installed in the image in and type:

`vagrant up`

The first time this will provision the box using the provision script. Influxdb will automatically started on all subsequent occassions

To log in type:

`./login`

The `username` and `password` are both `vagrant`

First time logged start Influxdb on the box by typing:

`sudo /etc/init.d influx start`

Then fireup firefox:

`firefox 127.0.0.1:8083 &`

To close down logout back to the host shell and type

`vagrant halt`

Grafana
-------

The grafana dashboard for Influx is also installed and configured. You can look at it using Firefox

`firefox 127.0.0.1:7777 &`
