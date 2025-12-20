#!/bin/bash
# DESCRIPTION: Check if FTP port (21) is closed

# If grep finds nothing, we return 0 (success = port is closed)
! ss -tuln | grep -q ":21 "
exit $?