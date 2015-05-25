# README #

The Wren class is a very straightforward singleton.
You simply set its *AuthToken*, and start the services of Geolocation and/or Beacons.
That's it.

### What is this repository for? ###

* This is a simple objC library for integrating with WrenSys Api

### Setup ###

This library requires two other libraries for properly working:
* AFNetworking
* iAppInfos

I recommend using the CocoaPod spec:
pod "AFNetworking", "~> 2.0"
pod "iAppInfos"