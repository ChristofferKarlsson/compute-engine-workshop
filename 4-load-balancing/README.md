# Load balancing
There are two types of load balancing in GCP.
Network load balancing and HTTP(S) load balancing.
A load balancer gives you an external IP.
Can balance between multiple regions. (Only HTTP?) (Sends traffic to nearest)
Setting up a load balancer is not the easiest thing to do, as it require a few things to work.

https://cloud.google.com/compute/docs/load-balancing/images/basic-http-load-balancer.svg

In this part, we will setup a load balancer that splits the traffic between the instances in the instance groups, to share the load.

We will also setup another instance group in another availability zone.
This is good practice and prevents your site from going down if the data center in one zone goes down.
(To have it even more robust, you can set it up in multiple regions.)

## The parts of a load balancer

To setup load balancing, you will need the following parts (and we will go through them all):
* [Global forwarding rules](https://cloud.google.com/compute/docs/load-balancing/http/global-forwarding-rules)
* [Target proxies](https://cloud.google.com/compute/docs/load-balancing/http/target-proxies)
* [URL mapping](https://cloud.google.com/compute/docs/load-balancing/http/url-map) (split traffic depending on URL)
* [Backend services](https://cloud.google.com/compute/docs/load-balancing/http/backend-service)
    * [Health check](https://cloud.google.com/compute/docs/load-balancing/health-checks)
    * Backend(s)
        * Instance group


### Forwarding rules
A forwarding rule routes traffic to a target proxy of the load balancer.

A forwarding rule provides you with a single global IP address.

### Target proxies
A target proxy terminates the HTTP(S) connection from the client and routes the traffic to the URL map.

### URL maps
A series of URL maps can be setup to redirect traffic to different backend services.

For example, if you want a specific pool of servers handling everything behind `/static` you setup a specific URL map for that URL.

A `default` URL map is also set up, which is where all traffic that does not match any specific rule is routed.
(There is no need to define specific rules, everything can go to the default backend service.)

### Backend services
A backend service routes traffic to your backends.
You can have one or more backends per backend service.

### Backend
A backend consists of an instance group, a set of rules that define the capacity of the instance group, and a health checks.

### Health checks
A check that is used to see if an instance is healthy (up and able to receive traffic).



## Creating a load balancer
To see these parts in the Console, go to Network Services > Load balancing.
Here you also have a small link in the bottom to the `advanced menu` where you can inspect more parts of the load balancer.

### Add another instance group
First, to have better availability of your site, lets add another instance group, in another zone in your region.

* Create a second instance group, equal to your first one but in a different zone (adjust the values below to match your first instance group)
```
gcloud compute instance-groups managed create webservers-managed-2 \
--base-instance-name webserver \
--size 1 \
--template webserver-template-1 \
--zone europe-west3-b
```

* List your instance groups and make sure you have two, using the same template but in different zones
```
gcloud compute instance-groups managed list
```

Your output should be very similar to the following
```
NAME                  LOCATION        SCOPE  BASE_INSTANCE_NAME  SIZE  TARGET_SIZE  INSTANCE_TEMPLATE     AUTOSCALED
webservers-managed-2  europe-west3-b  zone   webserver           1     1            webserver-template-1  no
webservers-managed-1  europe-west3-a  zone   webserver           1     1            webserver-template-1  no
```



### Named ports
A load balancer uses something called [named ports](https://cloud.google.com/compute/docs/instance-groups/creating-groups-of-unmanaged-instances#assign_named_ports).

A named port is a key-value that maps a service name to a port (i.e. http:8080).

The load balancer is setup to send traffic to the _name_ of the service, that is `http`.
Which in practice means it will send traffic to port 8080.

Named ports are set on instance groups, using the sub-command `set-named-ports`.

* Create a named port for both your instance groups that maps `http` to port `80`.
(Hint: Check out the `set-named-ports` option on the `instance-groups managed` command.

Solution
```
gcloud compute instance-groups managed set-named-ports webservers-managed-1 \
--named-ports http:80 \
--zone europe-west3-a

gcloud compute instance-groups managed set-named-ports webservers-managed-2 \
--named-ports http:80 \
--zone europe-west3-b
```

You also need to setup new autoscaling rules for your instance group, that scales depending on the load balancer.
(TODO: More about the load balancing target utilization)

* Setup auto-scaling for both your instance groups with the following properties

| Option | Value |
|--------|-------|
| Min instances | 1 |
| Max instances | 3 |
| Target load balancing utilization | 0.6 |
| zone | Your zone |

```
gcloud compute instance-groups managed set-autoscaling webservers-managed-1 \
--min-num-replicas 1 \
--max-num-replicas 3 \
--target-load-balancing-utilization 0.6 \
--zone europe-west3-a

gcloud compute instance-groups managed set-autoscaling webservers-managed-2 \
--min-num-replicas 1 \
--max-num-replicas 3 \
--target-load-balancing-utilization 0.6 \
--zone europe-west3-b
```


### Backend services and backends
As stated earlier, a backend service consists of a health check and one or more backends.

For our backend service to know if the instances in the backends are healthy and ready to receive traffic, you use [health checks](https://cloud.google.com/compute/docs/load-balancing/health-checks).
You use different health checks depending on your instances.

The health check that you are going to use is the HTTP health check.
The HTTP health check determines the health of the instance by the returned status code, where a standard `200` is considered healthy.
The HTTP health check can be setup on a specific path on the server, such as `/status`.

(TODO: Write more about how health checks affect instances and traffic.)

The health check command is located under `gcloud compute health-checks`

* Create an HTTP health check with the name `http-basic-check`

Solution
```
gcloud compute health-checks create http http-basic-check
```

The backend services are managed with the `gcloud compute backend-services` command.

* Create a global backend service, on `http` protocol that uses your `http-basic-check` health check

(TODO: Global vs. not global?)

Solution
```
gcloud compute backend-services create webservers-backend-service \
--protocol http \
--health-checks http-basic-check \
--global
```
(TODO: Can be `global`)

With the backend service in place, you can now add [backends](https://cloud.google.com/compute/docs/load-balancing/http/backend-service) to it.

A backend contains an instance group, a balancing mode and a capacity setting.
The balancing mode is either CPU utilization or the request rate (number of requests per second),
and is used by the backend service together with the capacity setting, to determine whether or not there is capacity for more requests in the backend.

* Create a global backend for your instance groups with the following properties

(TODO: Why global?)

| Option | Value |
|--------|-------|
| Instance group | webservers-managed-[1,2] |
| Instance group zone | Your zones for respective instance group |
| Balancing mode | RATE |
| Max rate per instance | 100 |

Solution
```
gcloud compute backend-services add-backend webservers-backend-service \
--instance-group webservers-managed-1 \
--instance-group-zone europe-west3-a \
--balancing-mode RATE \
--max-rate-per-instance 100 \
--global

gcloud compute backend-services add-backend webservers-backend-service \
--instance-group webservers-managed-2 \
--instance-group-zone europe-west3-b \
--balancing-mode RATE \
--max-rate-per-instance 100 \
--global
```



### The rest/Frontend
You are not going to use any special URL mappings in this workshop, so lets just create a default one, that maps all traffic to your only backend service.

The URL maps are configured using the `gcloud compute url-maps` command.

* Create a default URL map that sends everything to your backend service

Solution
```
gcloud compute url-maps create webservers-mapping \
--default-service webservers-backend-service
```

Then you will need a target HTTP proxy, that receives all traffic from a global forwarding rule and redirects it to your URL mapping.

The target proxies are configured using the `gcloud compute target-http-proxies` command.

* Create a target HTTP proxy, that redirects traffic to your URL map

(TODO: Write why using this: SSL termination f.e.)

Solution
```
gcloud compute target-http-proxies create webservers-target-proxy \
--url-map webservers-mapping
```

Finally, you need a global forwarding rule.
A forwarding rule is a single, global IP address that you can use to receive traffic to your load balancer.
The forwarding rule receives traffic on its IP address and routes it to your target proxy.

The forwarding rules are configured using the `gcloud compute forwarding-rules` command.

* Create a global forwarding rule that receives traffic on port 80 and sends it to your target proxy
```
gcloud compute forwarding-rules create webservers-forwarding-rules \
--global \
--target-http-proxy webservers-target-proxy \
--ports 80
```

* List your forwarding rules to get the global IP address of your load balancer.

It may take some time for everything to be setup.
So, now is the time to celebrate a bit with a cup of coffee or tea, or water, or something else :)

When it is done setting up, reload the site a couple of times to be sure that there are multiple servers that are handling your requests.

## Stress testing/Testing the autoscaler


When you are done, you can go to [Part 5 - Final touches](../5-final-touches).