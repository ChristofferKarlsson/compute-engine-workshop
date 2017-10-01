# Part 3 - Instance groups
Instance groups are for handling groups of instances (doh!).
With an instance group, you can handle things such as monitoring and rebooting of all instances in the group.
Instance groups are also one of the base components when building a load balancer.

There are two type of instance groups:
* [Managed](https://cloud.google.com/compute/docs/instance-groups/)
    * All instances are created using an [instance template](https://cloud.google.com/compute/docs/instance-templates)
    * Can automatically be resized using an autoscaler
    * Can have faulty or crashed instances recreated
* [Unmanaged](https://cloud.google.com/compute/docs/instance-groups/#unmanaged_instance_groups)
    * Group of possibly different instances

In this part, we are only looking at managed instance groups.

## Managed instance groups
In a managed instance group, all instances are the same and are created using an instance template.
An instance template is like a blueprint for instances.
If you want to change the template, you have to create a new template, and then apply that new template to the instance group, to get new instances.

### Creating an instance template
Instance templates are managed under the `instance-templates` command.

* Examine the instance templates `create` sub-command.

Solution:
```
gcloud compute instance-templates create --help
```

As you can see, it has pretty much the same options as the instances.

* Create an instance template with the following properties

|Option | Value |
|-------|-------|
| Name | webserver-template-1 |
| Machine type | f1-micro |
| Image | Your custom disk|
| Tags | http, ssh |
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
As with the instances, when executing the command surround the startup-script with a starting and ending `"`.

Solution
```
gcloud compute instance-templates create webserver-template-1 \
--machine-type f1-micro \
--image ubuntu-1604-webserver-base \
--tags http,ssh \
--region europe-west3 \
--subnet webservers \
--metadata startup-script="#! /bin/bash
echo 'Hostname: <!--# echo var=\"hostname\" default=\"unknown_host\" --><br/>IP address: <!--# echo var=\"host\" default=\"unknown_host\" -->' > /var/www/html/index.html
sed -i '/listen \[::\]:80 default_server/a ssi on;' /etc/nginx/sites-available/default
service nginx reload
"
```


### Creating a managed instance group
When creating a managed instance group, you define the template to be used and the size of the group (i.e., the number of instances).
Instance groups can be used as both a regional or zonal resource.
In this part, we will create a zonal instance group.

* Create an instance group, that uses your instance template, and the following properties (hint: use the `instance-groups managed` sub-command to create)

|Option | Value | Description |
|-------|-------|-------------|
| Name | webservers-managed-1 ||
| Base instance name | webserver | Instances are named `webserver-<random>` |
| Size |1 | |
| Zone | A zone in your region | |
| Template | Your template | |

Solution
```
gcloud compute instance-groups managed create webservers-managed-1 \
--base-instance-name webserver \
--size 1 \
--template webserver-template-1 \
--zone europe-west3-a
```

* List all your instances. What do you see?

Solution
```
gcloud compute instances list
```


### Resize the instance group
In the [Cloud Console](https://console.cloud.google.com) you can go to Compute Engine > Instance groups > webservers-managed-1 and see graphs of some metrics in your instance group.
These graphs are the resource usages among all instances in your group.

* Go and check out the graphs

Lets add another web server, by adjusting the size of the instance group.

* Use the `resize` sub-command and set the size to `2`

```
gcloud compute instance-groups managed resize webservers-managed-1 \
--size 2 \
--zone europe-west3-a
```

Manually scaling the instance group is probably not something you want to do.
A more convenient way of resizing it would be to have it automatically resize itself depending on the actual load of the instances.

* Set the size of the instance group back to `1`

Solution
```
gcloud compute instance-groups managed resize webservers-managed-1 \
--size 1 \
--zone europe-west3-a
```

### Autoscaling
To have the group automatically scale depending on the load on the instances, you can setup an [autoscaler](https://cloud.google.com/compute/docs/autoscaler/) for the instance group.
An autoscaler can be setup to scale depending on some chosen metrics, which you can read more about in the documentation.
In this part, you are will set it to scale on CPU usage.
The threshold value that is set, is for the _entire_ group of instances.

To setup an autoscaler, you use the sub-command `set-autoscaling`, under `instance-groups managed`.


* Examine the `set-autoscaling` sub-command

Solution
```
gcloud compute instance-groups managed set-autoscaling --help
```

* Setup autoscaling for your instance group, using the following properties

| Option | Value |
|--------|-------|
| Min instances | 1 |
| Max instances | 4 |
| Target cpu utilization | 0.7 |
| zone | Your zone |

Solution
```
gcloud compute instance-groups managed set-autoscaling webservers-managed-1 \
--min-num-replicas 1 \
--max-num-replicas 4 \
--target-cpu-utilization 0.7 \
--zone europe-west3-a
```

* Use the `describe` sub-command to check your instance group

Solution
```
gcloud compute instance-groups managed describe webservers-managed-1 \
--zone europe-west3-a
```



#### Stress test
Lets put the one, lonely instance under some load, to see the autoscaler in action!
To put it under load, you will install and run a CPU stressing program on the instance.

* SSH to the instance in your instance group


Install the Linux stress testing program [stress](https://linux.die.net/man/1/stress):
```
sudo apt-get install stress
```

Before starting the stress test, open up the [Cloud Console](https://console.cloud.google.com) and go to your instance group (Cloud Console > Compute Engine > Instance groups > webservers-managed-1).
When starting, you can check out the utilization graphs and also see the number of instances grow.

Start stress on the machine and watch the graphs and the number of instances in your instance group
```
stress --cpu 2 --timeout 60
```


#### Clean up
You will not use this autoscaling policy in later parts of the workshop, so you should remove it.

* Use the `stop-autoscaling` sub-command to remove the autoscaling policy

Solution
```
gcloud compute instance-groups managed stop-autoscaling webservers-managed-1 \
--zone europe-west3-a
```

You may need to set the size to `1` again after stopping the autoscaling, or you might end up with 4 instances.
```
gcloud compute instance-groups managed resize webservers-managed-1 \
--size 1 \
--zone europe-west3-a
```

When you are done, you can go to [Part 4 - Load balancing](../4-load-balancing).