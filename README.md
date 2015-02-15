In order to avoid writing temporary files to the SD card, I write out all of my files to a ramdisk

Add the following to your /etc/fstab file to setup a 64MB ramdisk:

`none /ramdisk tmpfs defaults,size=64m,mode=777 1 2`

Heat Tweet requires:

* [nest-api](https://github.com/gboudreau/nest-api)

* [tweepy](https://github.com/tweepy/tweepy)

Tree Lights requires:

* [ouimeaux](https://github.com/iancmcc/ouimeaux)

