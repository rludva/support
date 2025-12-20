#!/bin/bash
# DESCRIPTION: Check if Telnet port (23) is closed

! ss -tuln | grep -q ":23 "
exit $?