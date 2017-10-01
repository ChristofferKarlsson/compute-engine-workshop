# Part 5 - Secure the SSH access
As it is setup now, the SSH port on the webservers are open to the world.
This is generally not a good idea.

A better solution would be to deny any external ssh access, and instead add a [bastion host](https://cloud.google.com/compute/docs/instances/connecting-to-instance#bastion_host) (jump host) to your management subnet, through which you access the webservers.

## Create a bastion host
In the networks part, you already set up a firewall rule that allows all traffic from your management subnet to anywhere.
With that rule, any any instance in the management subnet will be able to access your webservers.

* Create a bastion host instance in the management subnet, with the `ssh` tag

Solution
```
gcloud compute instances create bastion \
--zone europe-west3-a \
--machine-type f1-micro \
--subnet management \
--tags ssh
```


## Update webservers config
To update and change the configuration on the webservers, you can not just change the template you created earlier.
Instead, you must create a new template and update your instance group to use this new template.

* Create a new template for the webservers, with the same properties as before, but without the `ssh` tag

|Option | Value |
|-------|-------|
| Name | webserver-template-1 |
| Machine type | f1-micro |
| Image | Your custom disk|
| Tags | http |
| Subnet | webservers |
| Region | Your subnet region |
| Metadata | startup-script (see below) |

```
#! /bin/bash
apt-get update
apt-get install nginx -y
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
```
When executing the command, surround the startup-script with a starting and ending `"`.

Solution
```
gcloud compute instance-templates create webserver-template-2 \
--machine-type f1-micro \
--image ubuntu-1604-webserver-base \
--tags http \
--region europe-west3 \
--subnet webservers \
--metadata startup-script="#! /bin/bash
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
"
```

To update an instance group to use a new template, there is support for [rolling updates](https://cloud.google.com/compute/docs/instance-groups/updating-managed-instance-groups#starting_a_basic_rolling_update).
However, this service is only in beta, so you need to access it through `gcloud beta compute instance-groups managed rolling-action start-update`.
This command will update roll out new machines, using your new template, while deleting the old ones.

(Please note that it takes some time for the load balancer to mark the new servers as healthy and use them.)

* Update both your instance groups to use the new template

Solution
```
gcloud beta compute instance-groups managed rolling-action start-update webservers-managed-1 \
--version template=webserver-template-2 \
--zone europe-west3-a

gcloud beta compute instance-groups managed rolling-action start-update webservers-managed-2 \
--version template=webserver-template-2 \
--zone europe-west3-b
```


## SSH through the bastion host
* When at least one of the instances are created, try to SSH to it both on the internal and external IP and verify that it does not work

To make the commands a bit easier, make your Cloud Shell Compute Engine SSH key the default SSH key (or else, you have to specify it each time you run `ssh`).

Create a `.ssh/config` file in the Cloud Shell and add the following to it
```
IdentityFile ~/.ssh/google_compute_engine
```

* SSH to one of the webservers, using the bastion as a jump host and the internal IP of the webserver
```
ssh -o ProxyCommand="ssh -W %h:%p <bastion-external-ip>" <webserver-internal-ip>
```

There is a simpler command for this (where you can just apply the `-J` flag), but that requires a newer version of `OpenSSH`.
If you want to know more about this, [you can read about it here](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts#Passing_Through_a_Gateway_Using_stdio_Forwarding_.28Netcat_Mode.29).


Want to do another extra part and secure your instances even more? Go to [Part 6 - Secure the HTTP access](../6-secure-http-access).

If not, make sure you remember to [clean up after you are done](../README.md#clean-up).