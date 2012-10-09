#!/bin/sh

# Copyright (C) 2012 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing to use,
# modify, copy, or redistribute it subject to the terms and conditions
# of the GNU General Public License v.2.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

. lib/test

#
# Main
#
aux target_at_least dm-thin-pool 1 0 0 || skip

aux prepare_pvs 4 64

# disable thin_check if not present in system
which thin_check || aux lvmconf 'global/thin_check_executable = ""'

clustered=
test -e LOCAL_CLVMD && clustered="--clustered y"

vgcreate $clustered $vg -s 64K $(cat DEVICES)

# create mirrored LVs for data and metadata volumes
lvcreate -l8 -m1 --mirrorlog core -n $lv1 $vg
lvcreate -l4 -m1 --mirrorlog core -n $lv2 $vg

lvconvert -c 64K --thinpool $vg/$lv1 --poolmetadata $vg/$lv2

lvcreate -V10M -T $vg/$lv1 --name $lv3

# check lvrename work properly
lvrename $vg/$lv1  $vg/pool
check lv_field $vg/pool name "pool"

lvrename $vg/$lv3  $vg/$lv4
check lv_field $vg/$lv4 name "$lv4"

# not yet supported conversions
not lvconvert -m 1 $vg/pool
not lvconvert -m 1 $vg/$lv3

vgremove -ff $vg
