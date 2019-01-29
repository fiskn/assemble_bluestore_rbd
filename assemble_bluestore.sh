#!/bin/bash
rbd_name=$1
# dd Block Size
bsize=512
rbdsize=$2
imgfile=$3
# Rados Object size (4MB)
obj_size=4194304

echo "The output file will be created as a file of size $rbdsize Bytes"
echo "The blocksize is $bsize"
echo $delm
echo "Creating Image file..."
dd if=/dev/zero of=${imgfile} bs=1 count=0 seek=${rbdsize} 2>/dev/null
echo "Starting reassembly..."
curr=1
echo -ne "0%\r"
find ./osds -type f | grep $rbd_name | grep head#/data > objects.txt
for i in $(cat objects.txt); do
        ver=$(echo $i | rev | cut -d "/" -f 2 | rev | cut -d "." -f 3 | cut -d ":" -f 1)
        num=$((16#$ver))
        offset=$(($obj_size * $num / $bsize))
        res=$(dd if=$i of=$imgfile bs=$bsize conv=notrunc seek=${offset} status=none)
        #perc=$((($curr*100)/$count))
        perc=$((($num*obj_size*100)/$rbdsize))
        bar="$perc % ["
        for j in {1..100}; do
                if [ $j -gt $perc ]; then
                        bar=$bar"_"
                else
                        bar=$bar"#"
                fi
        done
        bar=$bar"]\r"
        echo -ne $bar
        curr=$(($curr+1))
done
echo -ne "100%"
echo ""
echo "Image written to $imgfile"
