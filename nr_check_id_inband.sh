#!/bin/sh
#************************************************************
# Description: Check HNR Routing ID and Mgt ID
# Author: Cao Jijun @641
# Created: Tue Sep  8 23:53:08 CST 2015
#************************************************************

if [ $# -ne 2 ]
then
        echo "should input 2 parameter"
        echo "para1: Location of PCB Boad, for example by physical position C00,C01...C15;R0S00..R0S72;I0S00..I0S03"
        echo "para2: HNR Local id in the PCB Board, for example 0, 1"
        exit -1
fi

function set_mask_seg()
{
        reg=$1
        start=$2
        end=$3
        val=$4

        let 'mask=(1<<(end+1))-(1<<start)'
        let 'mask=~mask'

        let 'reg&=mask'

        let 'val<<=start'

        let 'reg|=val'

        echo `printf "%x" $reg`
}

function calc_inm_id()
{
        chip=$1

        if [ ${chip:0:2} == "0x" ]; then
                chip=`printf "%d" $chip`
        fi

        INM_FIRST_ID=0xeeeee

        val=0xc350004f1d000000

        if [ $chip -eq 0 ] ; then
                val=0x`set_mask_seg $val 0 19 $INM_FIRST_ID`
        else
                val=0x`set_mask_seg $val 0 19 $chip`
        fi

        echo $val
}

startnum=`cat ../Config/net-hnr.id  | grep $1 | awk '{print $3}'`

if [ $startnum == 0xeeeee ] ; then
        let 'startnum=0'
fi

temp=$2

let 'serialnum=startnum + temp'

hnrrtid=`cat ../Config/net-hnr.id  | grep $1 | awk '{print $2}'`
hnrmgtid=`calc_inm_id $serialnum`

cd ../Bin

val0=`./inm_read_reg -t hnr -o $serialnum -a 0x0   | tail -n 1 | cut -d "=" -f 3`
val1=`./inm_read_reg -t hnr -o $serialnum -a 0x600 | tail -n 1 | cut -d "=" -f 3`

echo "$val0"
echo "$val1"

if [ $val0 != $hnrrtid ]; then
        echo "$1-NR$2, the HNR RtID is Wrong:Shoud be "$hnrrtid", is NOT "$val0!""
else
        echo "$1-NR$2, the HNR RtID is Right!"
fi

if [ $val1 != $hnrmgtid ]; then
        echo "$1-NR$2, the HNR MgtID is Wrong:Shoud be "$hnrmgtid", is NOT "$val1!""
else
        echo "$1-NR$2, the HNR MgtID is Right!"
fi

cd .
