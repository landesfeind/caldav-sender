caldav-sender
=============

Fetch ICS data from sources and push to caldav server

Dependencies
============

On Debian Jessie you need to install the following packages:
apt-get install libmoose-perl libmoosex-params-validate-perl libwww-perl libdata-ical-perl libconfig-tiny-perl

Execution
======

cp config.sample config
#edit config
perl -Ilib bin/caldav-sender config