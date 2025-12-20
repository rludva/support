#!/bin/bash
# DESCRIPTION: Check if firewalld is active and enabled

systemctl is-active --quiet firewalld && systemctl is-enabled --quiet firewalld
exit $?