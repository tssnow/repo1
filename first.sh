#!/bin/bash

if [ $(whoami) != root ] ; then
	echo "User must be root"
	exit 1
else
	echo "Success"
fi
exit 0
