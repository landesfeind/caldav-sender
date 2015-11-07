caldav-sender
=============

Fetch ICS data from sources and push to caldav server

Dependencies
============

On Debian Jessie you need to install the following packages:
apt-get install libmoose-perl libmoosex-params-validate-perl libwww-perl libdata-ical-perl libconfig-tiny-perl

Execution
======


Copy the sample configuration

```
cp config.sample config
```

and change it according to your needs. To import the listed calendars, execute:

```
perl -Ilib bin/caldav-sender config
```
