# Part 2 - Networks
Networks are global resources.

Networks must use the private network ranges.

## Explore the default network
A default network is created with subnets for all regions.

Instances in a network can communicate through internal IPs.
Between networks requires external IPs.

Networks are managed using the `gcloud compute networks` command.

* Find and execute the command to list networks

Solution
```
gcloud compute networks list
```

* List subnets

Solution
```
gcloud compute networks subnets list
```

### Routes
The default subnet has routes for all subnets.

(TODO: Keep this?)

List routes
```
gcloud compute routes list
```

### Firewall rules
INGRESS = Incoming, EGRESS = Outgoing

The default network comes with default firewall rules for http, icmp (ping), rdp, ssh and internal traffic between instances.

Networks are managed using the `gcloud compute firewall-rules` command.

* List rules

Solution
```
gcloud compute firewall-rules list
```

## Setup your own custom network

### Create the network
Check out the manual for how to create a network where you manually create the subnets.
```
gcloud compute networks create --help
```

* Create a custom network named `my-network`

Solution
```
gcloud compute networks create my-network \
--mode custom
```

There are no firewall rules for your new network, yet.
The default rule is DENY and you won't be able to access any instance on the network.


### Create subnets
Subnetworks are regional resources. Can span across multiple zones.

Create two subnets with the following properties:

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
To allow traffic to your instances in your new network, you must specify a couple of firewall rules.

* Create a firewall rule that allows for ssh connection to all instances with an `ssh` tag

|Option|Value|
|------|-----|
|Ports| TCP 22|
|Network| my-network|
|Source| Anywhere|
|Tags| ssh|

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
|Ports| TCP 80|
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

|Option|Value|
|------|-----|
|Ports| TCP 22|
|Network| my-network|
|Source| 192.168.100.0/24 |

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

You can use the filter to only show the firewall rules for your network
```
gcloud compute firewall-rules list --filter "network=my-network"
```

### Create an instance
* Create an instance in your subnet, using your previously created image and add the `ssh` tag to it

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

* SSH into the instance and try the nginx server there:
```
curl localhost
```

It seems like the server is running... What could be the problem?

Identify the problem, fix it and try again on the external IP.

Solution: Add the `http` tag to the server
```
gcloud compute instances add-tags webserver-1 \
--tags http \
--zone europe-west3-a
```


## Clean up
Remove the instance
```
gcloud compute instances delete webserver-1 \
--zone europe-west3-a
```

When you are done, you can go to [Part 3 - Instance groups](../3-instance-groups).