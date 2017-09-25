# Part 1 - Instances
In this part, you will learn about creating instances, running startup scripts and building disk images.

## Creating an instance
First, do it in the [Console](https://console.cloud.google.com).
Go to Compute Engine > VM Instances in the console.

Click **Create**

To minimize the lag, choose a **Zone** that is close to us, which should be any of the european zones.
(Different zones may also have different hardware.)
You can read more about the zones [in the documentation](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

Choose a micro **Machine type**

Under **Firewall**, choose *Allow HTTP traffic*.

Leave the rest of the options as they are.
You can expand the **Management, disks, networking, SSH keys** option though to check what is available.

### Install some software
When the machine is ready, it will automatically have received an internal and external IP.
Click the machine name to examine the details.

Click the external IP and verify that there is no server there serving anything.

When done, go back to the list of machines and connect by SSH to the machine.
By clicking the **SSH** button, you will launch an SSH session in the browser. Be aware: Chrome might block the popup window.

When connected to the instance, install nginx to try it out
```
sudo apt-get update
sudo apt-get install nginx -y
```

Make sure nginx is running
```
sudo service nginx status
```
```
...
Active: active (running) ...
...
```

Now click the external IP again and verify that nginx is up and running.


## Creating an instance using the Cloud SDK
Now you will redo the steps above, but this time, you will use the Cloud SDK (which we will be using for the rest of the workshop).

All the commands for handling instances are under `gcloud compute instances`.
Remember that you can use autocomplete (if you have set it up or are using the Cloud Console) to find the available commands, and that you always can prepend `--help` to find more info the available flags.

* Find the command to list instances and make sure you the previously created instance there

Solution
```
gcloud compute instances list
```

* Now create an instance similar to the previous one, using the the following properties
(Tip: Use the `gcloud compute instances create --help` to find the flags you need.)

| Option | Value | Description |
| ------ | ----- | ----------- |
| name   | instance-2 | Just the name of your instance |
| zone   | \<any-zone\> | You can list the zones using `gcloud compute zones list` |
| tags   | http-server | This associates the server with the firewall rule `http-server`, more about this in the next part |
| machine-type | f1-micro | To list the machine types, use `gcloud compute machine-types list` |
| boot-disk-type | pd-ssd | See disk types using `gcloud compute disk-types list` |

Solution
```
gcloud compute instances create instance-2 \
--zone europe-west3-a \
--tags http-server \
--machine-type f1-micro \
--boot-disk-type pd-ssd
```

When you have created the machine:
* List the instances and make sure your new instance is there
* Use the `describe` sub-command to examine the properties of the new machine

### Install nginx
SSH to the instance, using the Cloud SDK SSH wrapper.
```
gcloud compute ssh <instance-name>
```

Install nginx as before, make sure it runs and the verify by connecting to `http://<external-ip/` (which you can find by listing the instances).
```
sudo apt-get update
sudo apt-get install nginx -y
```

Make sure nginx is running
```
sudo service nginx status
```
```
...
Active: active (running) ...
...
```


Now modify the nginx server so that we can see the hostname of the current machine
```
sudo su -
echo 'Hostname: <!--# echo var="hostname" default="unknown_host" --><br/>IP address: <!--# echo var="host" default="unknown_host" -->' > /var/www/html/index.html
```
Enable SSI on the server by
```
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
```

Then reload nginx
```
service nginx reload
```

## Startup scripts
Not having to do this manually every time would we create a new instance would be nice.
This can be done through start-up scripts.
Startup scripts are run when a machine is booted and run as root.


Create an instance with the following as a startup script:
```
#! /bin/bash
apt-get update
apt-get install nginx -y
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
```
When sending it in, surround the script with a starting " and ending ".

Solution
```
gcloud compute instances create instance-34 \
--zone europe-west3-a \
--tags http-server \
--machine-type f1-micro \
--boot-disk-type pd-ssd \
--metadata startup-script="#! /bin/bash
apt-get update
apt-get install nginx -y
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
"
```

Wait a few seconds after the machine is created and verify that it displays a page.

### Extra tasks
* SSH to the instance and check the logs. `/var/log/daemon.log`.
* [Shut down scripts](https://cloud.google.com/compute/docs/shutdownscript) - What use can they have? Try setting one up and make sure it has run.
* [Startup scripts can also be stored in Cloud Storage](https://cloud.google.com/compute/docs/startupscript#cloud-storage)



## Images
Startup scripts to install everything is time consuming and we will be needing Java later.
Make an image with Java and nginx installed.

[Documentation](https://cloud.google.com/compute/docs/images/create-delete-deprecate-private-images)
[Documentation2](https://cloud.google.com/compute/docs/images)

* List all available images
```
gcloud compute images list
```

* Create an instance that is built on the Ubuntu 16.04 LTS image (use the flags `--image` and `--image-project`).

Solution
```
gcloud compute instances create java-base \
--zone europe-west3-a \
--machine-type f1-micro \
--image ubuntu-1604-xenial-v20170919 \
--image-project ubuntu-os-cloud
```

SSH to the image and update the system
```
sudo apt-get update && sudo apt-get -y upgrade
```

Install nginx and java
```
sudo apt-get install nginx default-jre -y
```

Verify the installations
```
java -version
service nginx status
```

#### Creating the image
(Disks are Zone based)
The image you will create, are based on the boot disk that is attached to the instance.
Before creating an image from the disk, you need to stop the instance.

* Stop image

Solution
```
gcloud compute instances stop java-base \
--zone europe-west3-a
```

The instance should now be **TERMINATED** ([more about instance states](https://cloud.google.com/compute/docs/instances/checking-instance-status))

Normally, the boot disk is automatically deleted when deleting an instance.

* Delete the instance but keep the _boot_ disk (hint: there is a flag for it)

Solution
```
gcloud compute instances delete java-base \
--zone europe-west3-a \
--keep-disks boot
```

Examine the `gcloud compute images`, especially the `create` sub-command.

* Create an image by using the disk

Solution
```
gcloud compute images create ubuntu-1604-webserver-base \
--source-disk java-base \
--source-disk-zone europe-west3-a
```

* List the disks and find your old boot disk
* Delete the disk

Solution
```
gcloud compute disks list
```

Solution
```
gcloud compute disks delete java-base \
--zone europe-west3-a
```

### Create a new instance using the image
Create an instance using the new image, also apply the `http-server` tag to it
```
gcloud compute instances create instance-4 \
--zone europe-west3-a \
--machine-type f1-micro \
--tags http-server \
--image ubuntu-1604-webserver-base
```

Verify that your new instance is created and that it has an nginx server up and running.

## Clean up
Remove all instances that you have created
```
gcloud compute instances delete instance-1 instance-2 instance-3 instance-4
```


When you are done, you can go to [Part 2 - Networks](../2-networks).