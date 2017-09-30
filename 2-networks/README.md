# Part 2 - Networks
A network in Compute Engine is a [Virtual Private Cloud (VPC) network](https://cloud.google.com/compute/docs/vpc/).
Like the instances are virtual machines, the VPC is a virtual network where the instances are run and in which they communicate with each other.
Instances within the same network does not need any external IP, as they can communicate through their internal IPs.

A network is a global resource, meaning it can spread across multiple regions, but belongs to only one project.
A subnet on the other hand, is a regional resource, that can span over multiple availability zones in that region.

If you want to view the networks in the Console, you go to **VPC network** in the menu.

## Explore the default network
When enabling the Compute Engine API, a default `auto` mode network is created with subnets for all regions.

Networks are managed using the `gcloud compute networks` command.

* Find and execute the command to list all networks

Solution
```
gcloud compute networks list
```

* List the subnets

Solution
```
gcloud compute networks subnets list
```

### Routes
The default network is setup with [routes](https://cloud.google.com/compute/docs/vpc/routes) for each subnet, as well as a default route to the internet.
It is thanks to the routes that the traffic from an instance in one subnet can be routed to another subnet, or to the internet.

* List routes

Solution
```
gcloud compute routes list
```

### Firewall rules
[Firewall rules](https://cloud.google.com/compute/docs/vpc/firewalls) are used to control access to instances in the network.
The default rule is that all ingress (incoming) traffic is blocked, and the egress (outgoing) traffic is permitted.
Without setting up any firewall rules, you will not be able to access your instances.
The default network, however, comes with default firewall rules for http, icmp (ping), rdp, ssh and internal traffic between instances.

Firewall rules are applied to instances.
They are defined by a set of rules:
* Direction of traffic (ingress or egress)
* Action (Allow or deny)
* Source (instances with a specific *tag*, IP range, instances in a subnet, or instances with a service account)
* Destination (all instances, instances with a specific *tag*,  or instances with a service account)
* Priority (rules are evaluated in the order of priority)
* Protocols and ports


Firewall rules are managed using the `gcloud compute firewall-rules` command.

* List the firewall rules

Solution
```
gcloud compute firewall-rules list
```

* Describe the `default-allow-http` firewall rule
  * Do you see anything familiar here? That we used then setting up machines earlier?



## Setup your own custom network
To have more control over your network structure and subnets, you can setup a custom network.


### Create the network
Check out the manual for how to create a network, in which you have to manually create the subnets.
```
gcloud compute networks create --help
```

* Create a custom network named `my-network` (hint: you must use a flag for it)

Solution
```
gcloud compute networks create my-network \
--mode custom
```


### Create subnets
In this workshop, we will have two types of servers: webservers and management servers.
To have them logically separated, you will put them in different subnets.
You will have one subnet where the webservers will be places, and one where your management servers will be placed.

Subnets must use one of the [private network address ranges](https://en.wikipedia.org/wiki/Private_network).
But all subnets does not have to belong to the same range, you can mix as you want (e.g. have a `10.0.1.0/24` subnet and a `192.168.1.0/24` subnet).

* Create two subnets with the following properties:

| Name       | Network    | Region       | Range            |
|------------|------------|--------------|------------------|
| webservers | my-network | europe-west3 | 192.168.1.0/24   |
| management | my-network | europe-west3 | 192.168.100.0/24 |

Solution
```
gcloud compute networks subnets create webservers \
--network my-network \
--region europe-west3 \
--range 192.168.1.0/24

gcloud compute networks subnets create management \
--network my-network \
--region europe-west3 \
--range 192.168.100.0/24
```


### Create firewall rules
When creating a custom network, you do not get any automatic firewall rules set up.
So, there are no firewall rules for your new network, and since the default rule on ingress traffic is deny, no created instance will be accessible.

To allow traffic to your instances in your new network, you must specify a couple of firewall rules.

* Create a firewall rule that allows for ssh connection to all instances with an `ssh` tag

|Option|Value|Description|
|------|-----|-----------|
|Allow| TCP 22| SSH traffic goes over port 22|
|Network| my-network| |
|Source| 0.0.0.0/0 | `0.0.0.0/0` means all IP addresses|
|Tags| ssh| The tags to use on your instances to apply this rule|

Solution
```
gcloud compute firewall-rules create allow-ssh \
--network my-network \
--allow tcp:22 \
--target-tags ssh \
--source-ranges 0.0.0.0/0
```


* Create a firewall rule that allows HTTP to any instance with the `http` tag, using the following properties

|Option|Value|
|------|-----|
|Allow| TCP 80|
|Network| my-network|
|Source| Anywhere|
|Tags| http|

Solution
```
gcloud compute firewall-rules create allow-http \
--network my-network \
--allow tcp:80 \
--target-tags http \
--source-ranges 0.0.0.0/0
```

* Create a firewall that allows all internal traffic from the `management` subnet to any server (no need for tags)

Hints: Specify multiple ports by using `tcp:x-y` and multiple protocols and ports by using `tcp:x-y,udp:i-j`

|Option|Value|Description|
|------|-----|-----------|
|Allow| All TCP and UDP ports, and icmp | Hint: Ports ranges from 1-65535 |
|Network| my-network||
|Source| 192.168.100.0/24 |The management subnet IP range|

Solution
```
gcloud compute firewall-rules create internal-traffic \
--network my-network \
--allow tcp:1-65535,udp:1-65535,icmp \
--source-ranges 192.168.100.0/24
```


* List and check the firewall rules.

Solution
```
gcloud compute firewall-rules list
```

* Use the filter flag to only show the relevant rules (hint: `--filter "network=<network-name>"`)

Filters can be used on all commands to limit the result list.

Solution
```
gcloud compute firewall-rules list --filter "network=my-network"
```

### Create an instance
Now you are done setting up the network, for this time.
Lets try out if it actually works by creating an instance in your webservers subnet!

* Create an instance in your `webservers` subnet, using your previously created image, and add the `ssh` tag to it

Solution
```
gcloud compute instances create webserver-1 \
--zone europe-west3-a \
--machine-type f1-micro \
--subnet webservers \
--tags ssh \
--image ubuntu-1604-webserver-base
```

* Go to the ip of the instance in the browser. Can you reach it? If not, why?

* SSH into the instance and try the nginx server there
```
curl localhost
```

It seems like the server is running... What could be the problem?

* Identify the problem, fix it and try again on the external IP.

Hint (click to expand): There is a certain tag for reaching the server on the HTTP port missing.


Solution: Add the `http` tag to the server
```
gcloud compute instances add-tags webserver-1 \
--tags http \
--zone europe-west3-a
```


## Clean up
* Remove the instance you just created

Solution
```
gcloud compute instances delete webserver-1 \
--zone europe-west3-a
```

When you are done, you can go to [Part 3 - Instance groups](../3-instance-groups).