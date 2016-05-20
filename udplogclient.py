#!/usr/bin/env python

import sys

import socket
import time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

for i in range(5):
	sock.sendto("hello %d" % i, ('172.31.0.212', 9998))
	time.sleep(1)

sock.close()
