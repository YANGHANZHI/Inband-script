#!/bin/sh
#*******************************************************
# Description: Find the Peer Port of the Port
#*******************************************************

function usage()
{
        echo "should input 2 parameter"
        echo "para1: Local HNR ID"
        echo "para2: Local HNR PORT"
        echo "Usage: $0 NRID NRPT"
}


llp_status_reg3e=(
0x063e 0x06be
0x073e 0x07be
0x083e 0x08be
0x093e 0x09be
0x0a3e 0x0abe
0x0b3e 0x0bbe
0x0c3e 0x0cbe
0x0d3e 0x0dbe
0x0e3e 0x0ebe
0x0f3e 0x0fbe
0x103e 0x10be
0x113e 0x11be
0x123e 0x12be
0x133e 0x13be
0x143e 0x14be
0x153e 0x15be
0x163e 0x16be
0x173e 0x17be
);

port2mtp=(
8 8 8 9 9 9
4 4 4 5 5 5
10 10 10 11 11 11
6 6 6 7 7 7
0 0 0 1 1 1
2 2 2 3 3 3
)

nr1mtp=(
7 7 7
6 6 6
5 5 5
4 4 4
)

nr0mtp=(
3 3 3
2 2 2
1 1 1
0 0 0
)


function get_mask_seg()
{
        val=$1
        start=$2
        end=$3
        val=`printf "0x%x" $((val>>start))`

        let 'val2=(1<<(end-start+1))-1'
        val2=`printf "0x%x" $val2`

        let 'val=val&val2'

        echo $val
}

function get_hnr_pos()
{
        val=$1
        port=$2
        if [ $val -lt 360 ]; then
                let "val10=val/2*2"
        elif [ $val -gt 366 ] && [ $val -lt 521 ]; then
                val10=$val
        else
                val10=$val
        fi

        let "offset=val-val10"
        val16=`printf "0x%05x\n" $val10`

        #if [ $val16 == 0x00000 ]; then
         #       val16=`printf "0x%05x\n" 0xeeeee`
        #fi
                echo $val16
        str=`cat ../Config/net-hnr.id | awk '{print $1,$3}' |grep  $val16 |awk '{print $1}'`
        #str=`grep $val16 ../Config/net-hnr.id | awk '{print $1}'`
        #echo ${str}
       # if [ "${str:0:1}" == "C" ] ;then
                #echo $str"-NR"${offset}"-P"$2
        #       echo $str"-NR"${offset}"-MTP"${port2mtp[port]}"-P"$2
            if [ "${str:0:1}" == "P" ] ;then
                     if [ ${offset} == 1 ] ; then
                           # echo $str"-NR"${offset}"-P"$2
                      if [ $port -gt 16 ]  && [ $port -lt 29 ] ;then
                            let "port=port-17"
                            echo $str"-NR"${offset}"-MTP"${nr1mtp[port]}"-P"$2
                          else echo $str"-NR"${offset}"-P"$2
                           fi
                    else
                            #echo $str"-NR"${offset}"-P"$2
                         if [ $port -gt 18 ] && [ $port -lt 31 ] ;then
                            let "port=port-19"
                            echo $str"-NR"${offset}"-MTP"${nr0mtp[port]}"-P"$2
                                else  echo $str"-NR"${offset}"-P"$2
                           fi

                        fi
         else   echo $str"-NR"${offset}"-MTP"${port2mtp[port]}"-P"$2
            fi
}

if [ $# -lt 2 ]; then
        usage
        exit
fi

cd ../Bin

NRID=$1
NRPT=$2

echo ${NRID}.${NRPT}
get_hnr_pos ${NRID} ${NRPT}

val=`../Bin/inm_read_reg -t hnr -o ${NRID} -a ${llp_status_reg3e[NRPT]}  | tail -n 1 | cut -d "=" -f 3`
NRID=`get_mask_seg $val 20 39`
NRPT=`get_mask_seg $val 48 63`
echo ${NRID}.${NRPT}
if [ $NRPT -lt 36 ]; then
get_hnr_pos ${NRID} ${NRPT}
else
echo "IO_PORT"
fi
exit
