#!/bin/bash

# Build image
sudo -E make rootfs USE_DOCKER=true
sudo -E make image USE_DOCKER=true

# Build kernel
sudo -E make kernel-src USE_DOCKER=true
sudo -E make kernel USE_DOCKER=true
