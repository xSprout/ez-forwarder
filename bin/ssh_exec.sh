#!/bin/bash
echo "ssh -oStrictHostKeyChecking=no $@ && echo $?" &> lastrun.txt
ssh -oStrictHostKeyChecking=no "$@ && echo $?" &>> lastrun.txt
exit 0