# Compute Engine Workshop

## Prerequisites
An account on Google Cloud.

All steps have been tested using the [Cloud Shell](https://cloud.google.com/shell/docs/) in [Console](https://console.cloud.google.com).
It should also work using the latest version of the [Google Cloud SDK](https://cloud.google.com/sdk/), but it has not been tested.


### Initialize
Create a new project and connect your SDK to it.
If you are using the Cloud Shell, just open it from your new project.
If you are using the local SDK, you connect to it with
```
gcloud init
```

### Enable the Compute Engine API
Before you can do anything, you must enable the Compute Engine API.
The simplest way of doing that, is by browsing to the Compute Engine tab in the Console.

The first time you go there, you will get a message like:
`Compute Engine is getting ready. This may take a minute or more. Compute Engine documentation `


## Parts
This workshop is split up in separate parts.
Each of the parts builds on the previous part, so be sure to do them in order.

1. [Instances](1-instances)
2. [Networks](2-networks)
3. [Instance groups](3-instance-groups)
4. [Load balancing](4-load-balancing)
5. [Final touches](5-final-touches)

### Extra
If you are done early, here are som tasks you could try

* Play around with the [Metadata API](https://cloud.google.com/compute/docs/storing-retrieving-metadata)
* Setup a SQL server and connect the app to it
* Setup in multiple regions