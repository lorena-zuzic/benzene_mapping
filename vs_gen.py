#!/usr/bin/env python
import sys

nbenz=int(sys.argv[1])
print "[ virtual_sitesn ]"
for i in range(nbenz):
	dmid=(i+1)*13
	vsline=str(dmid) + " " + "2"
	for j in range(6):
		caid=(i*13)+(j*2)+1
		vsline=vsline + " " + str(caid)
	print vsline

#print "%6d 2 %6d "%(dmid,caid)

	
