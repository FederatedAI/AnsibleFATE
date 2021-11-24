#!/bin/bash

#make swap file
function_make() {
  dest=$1
  size=$2
  mark=$3
  echo $dest $size $mark
  sudo dd if=/dev/zero of=$dest/swapfile${size}G_$mark bs=1M count=$(( $size * 1024 ))
  sudo chmod 0600 $dest/swapfile${size}G_$mark
  sudo mkswap $dest/swapfile${size}G_$mark
  sudo swapon $dest/swapfile${size}G_$mark
}

#deal with size
function_dealWithSize() {

  local tsize=$1
  num=$(( ${tsize/G/} / 32 ))
  left=$(( ${tsize/G/} % 32 ))
  if [ $left != 0 ]
  then
    local total=$(( $num + 1 ))
    echo "${total}:1"
  else
    if [ "${num}" == "0" ]
    then
      echo "1:0"
    else
      echo "${num}:0"
    fi
  fi
}

echo "Waring: please make sure has enough space of your disk first!!!"
echo -n "current user has sudo privilege(yes|no):"
read answer

if [ "$answer" != "yes" ]
then
  echo "Warning: current user has sudo privilege"
  exit 1
fi

echo -n "Enter store directory:"
read dest
echo -n "Enter the size of virtual disk(such as 64G/128G):"
read size

total=$(function_dealWithSize $size)
if [ ${total#*:} -eq 1 ]
then
  echo "Waring: the size must be 32G times"
  exit 1
fi

for num in $( seq 1 ${total%:*} )
do
  function_make $dest "32" $num
done



