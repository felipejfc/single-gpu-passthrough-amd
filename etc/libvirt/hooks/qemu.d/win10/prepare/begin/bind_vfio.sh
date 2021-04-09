#!/bin/bash

source "/etc/libvirt/hooks/kvm.conf"

## Kill the display manager
echo "Killing display manager"
systemctl stop display-manager.service

sleep 3

## Kill the console
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind
# You might need to uncomment the line below or to add video=efifb:off to your kernel arguments with grub. I didn't need either
#echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

sleep 2

echo "Unloading AMD driver and binding devices to VFIO"
## Unload amd
modprobe -r amdgpu

## Load vfio
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci

## Unbind gpu from nvidia and bind to vfio
virsh nodedev-detach pci_0000_${VIRSH_GPU_VIDEO//[:.]/_}
virsh nodedev-detach pci_0000_${VIRSH_GPU_AUDIO//[:.]/_}
virsh nodedev-detach pci_0000_${VIRSH_GPU_USB//[:.]/_}

# This step is very important, not only it prevends AMD reset bug and code 49 bug, it also makes it possible for the host to rebind successfully to the GPU
# Beware this is a fix to some AMD GPUs only, the ones that suffers with reset bug
# Try to successfully run the VM without this at first, if you get a black screen or a error code 43 in windows, then put it back
echo "Reseting AMD GPU so that we prevent a log of bugs in both host and vm"
echo "disconnecting amd graphics"
echo "1" | tee -a /sys/bus/pci/devices/0000\:${VIRSH_GPU_VIDEO}/remove
echo "disconnecting amd sound counterpart"
echo "1" | tee -a /sys/bus/pci/devices/0000\:${VIRSH_GPU_AUDIO}/remove
echo "will go to sleep now for 5 seconds"
rtcwake -m mem -s 5
echo "reconnecting amd gpu and sound counterpart"
echo "1" | tee -a /sys/bus/pci/rescan
echo "AMD graphics card sucessfully reset"
