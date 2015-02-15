#!/usr/bin/python
import tweepy, sys

CONSUMER_KEY = "" 
CONSUMER_SECRET = ""
ACCESS_KEY = ""
ACCESS_SECRET = ""

auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_KEY, ACCESS_SECRET)
api = tweepy.API(auth)

try:
 if len(sys.argv[1]) <= 140:
  api.update_status(sys.argv[1])
 else:
  raise IOError
except:
 print "Something went wrong: either your tweet was too long or you didn't pass in a string argument at launch."
