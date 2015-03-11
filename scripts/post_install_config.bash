#!/bin/bash

. /root/eucarc

i=0
acctname="ui-test-acct-00"
acctdir="/root/$acctname"
imagedir="/root/images"
urls=( "http://images.walrus.cloud.qa1.eucalyptus-systems.com:8773" "http://mirror.eucalyptus-systems.com/images/windows_images/windows_euca3.2/kvm" )
images=( "precise-server-cloudimg-amd64-disk1.img" "windowsserver2003r2_ent_x64.kvm.img" )

check_ubu_image=$(euca-describe-images -a | grep ${images[0]} | wc -l)
check_win_image=$(euca-describe-images -a | grep ${images[1]} | wc -l)
check_ui_acct=$(euare-accountlist | grep $acctname | wc -l)

if [ ! -d $acctdir ] ; then
    mkdir -p $acctdir
fi

if [ ! -d $imagedir ] ; then
    mkdir -p $imagedir
fi

for img in ${images[@]} ; do
    if [ ! -f $imagedir/$img ] ; then
        wget ${urls[$i]}/$img --output-document=$imagedir/$img
        (( i++ ))
    fi
done

euare-useraddloginprofile -u admin -p mypassword0

if [ "$check_ui_acct" -eq "0" ] ; then
    if [ -f $acctdir/admin.zip ] ; then
        rm -f $acctdir/admin.zip
    fi
    euare-accountcreate -a $acctname
    euare-useraddloginprofile -u admin -p mypassword0 --as-account $acctname
    euca-get-credentials -a $acctname -u admin $acctdir/admin.zip
    unzip -o $acctdir/admin.zip -d $acctdir/
fi

. $acctdir/eucarc

if [ "$check_ubu_image" -eq "0" ] ; then
    euca-install-image -n ui-ubuntu00 -b ubuntu00-ui -i $imagedir/precise-server-cloudimg-amd64-disk1.img -r x86_64 --virtualization-type hvm
fi
if [ "$check_win_image" -eq "0" ] ; then
    euca-install-image -n ui-winserv2003 -b winserv2003-ui --platform windows -i $imagedir/windowsserver2003r2_ent_x64.kvm.img -r x86_64 --virtualization-type hvm
fi
