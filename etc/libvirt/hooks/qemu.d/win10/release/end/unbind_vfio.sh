#!/bin/bash

source "/etc/libvirt/hooks/kvm.conf"

echo "Unloading VFIO so that amdgpu can bind into the GPU again"
## Unbind gpu from vfio and bind to nvidia
virsh nodedev-reattach $VIRSH_GPU_VIDEO
virsh nodedev-reattach $VIRSH_GPU_AUDIO
virsh nodedev-reattach $VIRSH_GPU_USB

## Unload vfio
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

# This step is very important, not only it prevends AMD reset bug and code 49 bug, it also makes it possible for the host to rebind successfully to the GPU
# Read the comments in the prepare bind vfio script about this part, it might not be needed for you
echo "Reseting AMD GPU so that we prevent a log of bugs in both host and vm"
echo "disconnecting amd graphics"
# Replace ids with your GPU PCI ids
echo "1" | tee -a /sys/bus/pci/devices/0000\:28\:00.0/remove
echo "disconnecting amd sound counterpart"
echo "1" | tee -a /sys/bus/pci/devices/0000\:28\:00.1/remove
echo "will go to sleep now for 5 seconds"
rtcwake -m mem -s 5
echo "reconnecting amd gpu and sound counterpart"
echo "1" | tee -a /sys/bus/pci/rescan
echo "AMD graphics card sucessfully reset"

sleep 5

systemctl start display-manager.service
