#!/usr/bin/python

import os
import boto.ec2
from pprint import pprint

def cloudconfig():
 base_path = os.path.dirname(os.path.realpath(__file__))
 cloud_config = open(os.path.join(base_path, 'cloud-config'))
 return cloud_config.read()
 close(os.path.join(base_path, 'cloud-config'))

conn = boto.ec2.connect_to_region("eu-west-1")

from boto.ec2.blockdevicemapping import BlockDeviceMapping, BlockDeviceType
block_device_map = BlockDeviceMapping()
block_dev_type = BlockDeviceType()
block_dev_type.delete_on_termination = True
#block_dev_type.snapshot_id = snapshot_id
block_device_map['/dev/sda'] = block_dev_type


i = conn.run_instances(
#    'ami-1c2e8b6b',
    'ami-0c10417b',
    key_name = 'jpazdyga',
    user_data = cloudconfig(),
    instance_type = 't1.micro',
    security_groups = ['automat'],
    block_device_map = block_device_map)

print(i.instances)
