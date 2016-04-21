#!/usr/bin/env python

import subprocess
import os
import socket
import requests
from lxml import etree
import re
import sys

HOST="localhost"
PORT="8085"
PATH="Snh_ItfReq"
TIMEOUT=10

def get_routeIp():
        cmd='route'
        cmdout = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE).communicate()[0]
	#routeIp store all the link local route
        routeIp=[] 
        for x in cmdout.splitlines():
           if re.match(r"169.254.*", str(x)):
            routeIp.append(x.split(' ', 1)[0])
        return routeIp

def get_dict():
    route= get_routeIp()
    #eVm_id store vm_name for which link local route are not installed
    eVm_id= []
    url='http://%s:%s/%s' %(HOST, PORT, PATH)
    try:
	#fetching introspect xmp information in resp 
        resp = requests.get(url,timeout=TIMEOUT)
        if resp.status_code == requests.codes.ok:
                root= etree.fromstring(resp.text)
                for neighbor in root.iter('ItfSandeshData'):
                    tap=0
                    for child in neighbor:
                       if child.tag == 'name':
		       	   #check tap information from xml tree
                           if re.match(r"tap-*", child.text) is not None:
                                tap=1
                       if child.tag == 'vm_name':
                                if tap == 1:
                                     vm_id=child.text
                       if child.tag == 'mdata_ip_addr':
                                if tap == 1:
				      #check link local route
                                      if child.text == '0.0.0.0' or  (child.text not in route):
                                            eVm_id.append(vm_id)
                return eVm_id
        else:
                status=1
                print status, 'link_local_status - WARNING  %s' %(str(resp.status_code))
                sys.exit(0)
    except requests.ConnectionError, e:
        status=1
        print status, 'link_local_status - WARNING  %s' %(str(e))
        sys.exit(0)
    except (requests.Timeout, socket.timeout) as te:
        status=1
        print status, 'Link_local_status - WARNING  %s' % (str(te))
        sys.exit(0)

def get_status():
        link= get_dict()
        if not link:
           return None
        else:
           return link

def service_status(svc):
    cmd = 'service ' + svc + ' status'
    cmdout = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE).communicate()[0]
    if cmdout.find('running') != -1:
        return 0
    else:
        return 2
# status for contrail-vrouter-agent service
status=service_status("contrail-vrouter-agent")
if status == 0:
        msg_fmt="OK contrail-vrouter-agent is Running"
else:
        msg_fmt="CRITICAL contrail-vrouter-agent service is inactive"
print status, "vrouter_agent_status - ", msg_fmt

#status for link local
vm_name=[]
vm_name=get_status()
if vm_name is None:
        status=0
        msg_fmt="OK all link local route are correct"
else:
        status=1
        msg_fmt='Warning link local not created for vm ids %s' % (str(vm_name))
print status, "link_local_status - ", msg_fmt

