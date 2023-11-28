#!/bin/bash

# Script is responsible for checking if any forever processes have been stopped
# If so, it will then reboot the system, so that we don't have to do it ourselves
# Sometimes, processes are just stopped for a number of reasons at random times

STOPPED=$(sudo forever list 2>/dev/null | grep "STOPPED")

# If string isn't empty
if [[ -n "$STOPPED" ]]; then
  sudo reboot
fi
