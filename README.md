These scripts were written and tested on a Raspberry Pi running * [Raspbian](http://www.raspbian.org/). They should run on any linux host without issue.

In order to avoid writing transient data to the SD card on the Raspberry Pi, a ramdisk is used to store it.

Add the following to your /etc/fstab file to setup a 64MB ramdisk:

`none /ramdisk tmpfs defaults,size=64m,mode=777 1 2`

Heat Tweet requires:

* [nest-api](https://github.com/gboudreau/nest-api)

* [tweepy](https://github.com/tweepy/tweepy)

Tree Lights requires:

* [ouimeaux](https://github.com/iancmcc/ouimeaux)
