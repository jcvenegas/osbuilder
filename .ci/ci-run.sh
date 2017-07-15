#!/bin/bash

sudo -E make rootfs USE_DOCKER=true
sudo -E make image USE_DOCKER=true
