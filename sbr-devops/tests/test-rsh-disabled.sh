#!/bin/bash
# DESCRIPTION: Check if RSH/Rlogin/Rexec ports (512-514) are closed

! ss -tuln | grep -Eq ":(512|513|514) "
exit $?