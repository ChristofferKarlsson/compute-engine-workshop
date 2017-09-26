# Final touches

## Set up a bastion host
As it is setup now, the SSH port on the webservers are open to the world.
This is generally not a good idea.

A better solution would be to add a [bastion host](https://cloud.google.com/compute/docs/instances/connecting-to-instance#bastion_host) (or jump host) to our management subnet, through which you access the webservers.

In the networks part, you already set up a firewall rule that allows all traffic from your management subnet to anywhere.

* Create an instance in the management subnet, with the `ssh` tag

Solution
```
gcloud compute instances create bastion \
--zone europe-west3-a \
--machine-type f1-micro \
--subnet management \
--tags ssh
```

To remove the `ssh` tag from the webservers, you must create a new template for them.
Unfortunately, it is not possible to just change the one you created earlier.

* Create a new template for the webservers with the same properties as before, but without the `ssh` tag

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

* Update both your instance groups to use the new template

Solution
```
gcloud beta compute instance-groups managed rolling-action start-update webservers-managed-1 \
--version template=webserver-template-2 --zone europe-west3-a

gcloud beta compute instance-groups managed rolling-action start-update webservers-managed-2 \
--version template=webserver-template-2 --zone europe-west3-b
```

(Pleaase note that it takes some time for the load balancer to mark them both as healthy and use them.)

* When at least one of the instances are created, try to SSH to it.

* SSH to the bastion and SSH again from the bastion to one of the webservers (TODO: Broken ... Must pre-populate with SSH keys.)


## Only allow http from load balancer

* Only allow network traffic from load balancer
* Remove external IP from instance template
* Only allow SSH from management subnet
* Only allow webservers to talk through a NAT gateway


When you are done, you can feel satisfied :)

If you still have time left and want to play around some more, there are some [extra tasks](../).