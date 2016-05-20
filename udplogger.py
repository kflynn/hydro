#!/usr/bin/env python

import sys

import socket
import time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(( '0.0.0.0', 9998 ))

print("listening on 9998")

while True:
	data, address = sock.recvfrom(128)

	print("%d: %s %d => '%s'" % (int(time.time()), address, len(data), data))
	
