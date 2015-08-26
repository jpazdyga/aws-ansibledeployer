#!/usr/bin/python

from pprint import pprint
import boto.ec2
import sys, getopt

givenid = sys.argv[2]
ipreq = sys.argv[1]

conn = boto.ec2.connect_to_region("eu-west-1")

reservations = conn.get_all_instances()
instances = [i for r in reservations for i in r.instances]
for i in instances:
    instid = i.id
    if instid.find(givenid) != -1:
     if ipreq in "private":
      print(i.private_ip_address);
     elif ipreq in "public":
      print(i.ip_address);

    #pprint(i.__dict__)
    #break # remove this to list all instances
