# Part 1 - Instances
In this part, you will learn about creating [instances](https://cloud.google.com/compute/docs/instances/), running startup scripts and building disk images.

An instance in Compute Engine is a virtual machine, that is run in your Google Cloud project.


## Creating an instance
First, you will do it in the [Console](https://console.cloud.google.com).

* Go to Compute Engine > VM Instances in the console.
* Click **Create**.
* To minimize the lag, choose a **Zone** that is close to us, which should be any of the european zones.
  (Different zones may also have different hardware.)
  You can read more about the zones [in the documentation](https://cloud.google.com/compute/docs/regions-zones/regions-zones).
* Choose the smallest **Machine type**, wich is a *micro*.
* Under **Firewall**, choose *Allow HTTP traffic*.

Leave the rest of the options as they are.
You can expand the **Management, disks, networking, SSH keys** option though to check what is available.

Finish the creation by clicking **Create**.


### Install some software
When the instance is ready, it will automatically have received an internal and external IP.

* Click the instance name to examine the details.

Here you also see some utilization graphs of the instance's resources.

* Click the external IP and verify that there is no server there serving anything.

When done, go back to the list of instances and connect by SSH to the instance.
By clicking the **SSH** button, you will launch an SSH session in the browser. Be aware: Chrome might block the popup window.

When connected to the instance, install nginx to try it out.
It is running a Debian operating system, and the commands are
```
sudo apt-get update
sudo apt-get install nginx -y
```

Make sure nginx is running
```
sudo service nginx status
```
Output should be contain
```
...
Active: active (running) ...
...
```

Now click the external IP again and verify that nginx is up and running.


## Creating an instance using the Cloud SDK
Now you will redo the steps above, but this time, you will use the Cloud SDK (which we will be using for the rest of the workshop).

In the Cloud SDK, all commands are sub-commands to the `gcloud` command.
There are multiple level of sub-commands, and to handle instances, the sub-commands are located under `gcloud compute instances`.
You can use autocomplete to find the next level of commands (if you have set it up or are using the Cloud Console).

For most commands, you will need to send some data to it.
This is done by using the appropriate flag for the option.
Flags are appended to the command by using `--<flag>`.
To find the available flags (and the one you are interested in), you can append `--help` to and get more information.

All this command documentation is also available in the [online documentation](https://cloud.google.com/sdk/gcloud/reference/).

<details>
<summary><strong>Find the command to list instances and make sure you see the previously created instance there</strong></summary>

```
gcloud compute instances list
```
</details>

<details>
<summary><strong>Now create an instance similar to the previous one, using the the following properties.</strong></summary>
```
gcloud compute instances create instance-2 \
--zone europe-west3-a \
--tags http-server \
--machine-type f1-micro \
--boot-disk-type pd-ssd
```
</details>
(Tip: Use the `gcloud compute instances create --help` to find the flags you need.)

| Option | Value | Description |
| ------ | ----- | ----------- |
| name   | instance-2 | Just the name of your instance. |
| zone   | \<any-zone\> | You can list the zones using `gcloud compute zones list`. |
| tags   | http-server | This associates the server with the firewall rule `http-server`, more about this in the next part. |
| machine-type | f1-micro | To list the machine types, use `gcloud compute machine-types list`. |
| boot-disk-type | pd-ssd | Using an SSD disk. See disk types using `gcloud compute disk-types list`. |

When you have created the machine:
* List the instances and make sure your new instance is there
* Use the `describe` sub-command to examine the properties of the new machine

Solution
```
gcloud compute instances describe instance-2
```

### Install nginx
* SSH to the instance, this time using the Cloud SDK SSH wrapper (Tip: `gcloud compute ssh`)

Solution
```
gcloud compute ssh instance-2
```

Install nginx as before
```
sudo apt-get update
sudo apt-get install nginx -y
```
Make sure nginx is running
```
sudo service nginx status
```
Output
```
...
Active: active (running) ...
...
```

* Open the `http://<external-ip/` in your browser to verify that you can connect to it


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

* Verify the result (you might need to wait a few seconds and do a hard refresh)

## Startup scripts
There are not an awful amount of manual steps that you need to replicate to have one more machine setup with nginx that show your IP and hostname.
But this is just a small example, and in the real world, there would probably be a lot more!
And with a larger setup, not having to do this manually every time would you create a new instance would be very nice!

Instances in Google Cloud can run something called [startup scripts](https://cloud.google.com/compute/docs/startupscript).
A startup script is run as root when a machine is booted, and can be use to automate setups like the one you did manually.

Startup scripts are added to an instance using [metadata](https://cloud.google.com/compute/docs/storing-retrieving-metadata).

* Create an instance with a startup script, with the following properties

| Option | Value |
| ------ | ----- |
| name   | instance-3 |
| zone   | \<any-zone\> |
| tags   | http-server |
| machine-type | f1-micro |
| boot-disk-type | pd-ssd |
| metadata | startup-script (see the actual startup script below) |

The startup script. Does everything we did before: update the system, install nginx, create a page that shows your instance's info, change nginx settings and finally reload nginx config.

```
#! /bin/bash
apt-get update
apt-get install nginx -y
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
```
When executing the command surround the startup-script with a starting and ending `"`.

Solution
```
gcloud compute instances create instance-3 \
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

* Wait a few seconds after the machine is created, then open your browser and verify that it runs the same page as before, showing your IP and hostname.


## Images
In a scenario where you are using some autoscaling mechanism for creating instances, you want the instances to be created fast.
While the startup scripts are convenient to use, they are not very fast, having to update the system and install the same software every time.
What if you could have the software already installed when creating the instance?

This is where [images]https://cloud.google.com/compute/docs/images) come in handy!
You have already used images, as each instance you have created have used the default Debian image.
(Imagine the time it would take if you actually had to install the OS every time?!)

Google Cloud provides a lot of different images for different operating systems (CentOS, Debian, Windows Server, etc.).
It also lets you create your own images, which can be based on already existing images.
This allows you to create a custom image that has the OS updated (well, updated at the time you create the image) and all the software you need already installed.

We will use both nginx and Java later, and in this part we will create an image with the software installed.

* Find the command and list all available images (hint: it is under `gcloud compute`)
```
gcloud compute images list
```

* Create an instance that is built on the Ubuntu 16.04 LTS image (hint: use the flags `--image` and `--image-project`) and has the following other properties

 Option | Value |
| ------ | ----- |
| name   | webserver-base |
| zone   | \<any-zone\> |
| machine-type | f1-micro |

Solution
```
gcloud compute instances create webserver-base \
--zone europe-west3-a \
--machine-type f1-micro \
--image ubuntu-1604-xenial-v20170919 \
--image-project ubuntu-os-cloud
```

SSH to the instance and update the system
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

### Creating the image
Now that the system is updated and has the software you need, you are ready to create an image of it.

Images are created using a disk that has an OS and software installed on it.
In your case, it will be the *boot* disk that is attached to the instance (each instance has a 10 GB boot disk attached, unless anything else is specified).


Before creating an image from the disk, you need to stop the instance.

* Stop your instance

Solution
```
gcloud compute instances stop webserver-base \
--zone europe-west3-a
```

The instance should now be **TERMINATED** ([more about instance states](https://cloud.google.com/compute/docs/instances/checking-instance-status))

You can now delete the instance, as you will only need its disk.
Normally, the boot disk is automatically deleted when deleting an instance.
To prevent this, you can either provide a flag when creating an instance, or when you delete it.

* Delete the instance but keep the *boot* disk (hint: there is a flag for it)

Solution
```
gcloud compute instances delete webserver-base \
--zone europe-west3-a \
--keep-disks boot
```


* Examine the `gcloud compute images` command, especially the `create` sub-command.

* Create an image named `ubuntu-1604-webserver-base`, using your disk (hint: you need two flags)

Solution
```
gcloud compute images create ubuntu-1604-webserver-base \
--source-disk webserver-base \
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
gcloud compute disks delete webserver-base \
--zone europe-west3-a
```

### Create a new instance using the image
It is now time to try out your newly created image!

* Create an instance using the new image, also apply the `http-server` tag to it
```
gcloud compute instances create instance-4 \
--zone europe-west3-a \
--machine-type f1-micro \
--tags http-server \
--image ubuntu-1604-webserver-base
```

* Verify that your new instance is created and that it has an nginx server up and running.

## Clean up
You will not need the instances created here in later parts of the workshop, so go ahead and delete them.

* Delete all instances that you have created
```
gcloud compute instances delete instance-1 instance-2 instance-3 instance-4
```


When you are done, you can go to [Part 2 - Networks](../2-networks).