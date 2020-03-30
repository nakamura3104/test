#!/bin/bash

IP=`jq -r '.prefixes[] | select(.region=="ap-northeast-1") | .ip_prefix' < ip-ranges.json`

while read line
do
        echo $line |
                awk -F'/' '{print $(cidr2mask $2)}';
        echo "push \"route $line \" "
done <<END
$IP
END


cidr2mask() {
  local i mask=""
  local full_octets=$(($1/8))
  local partial_octet=$(($1%8))

  for ((i=0;i<4;i+=1)); do
    if [ $i -lt $full_octets ]; then
      mask+=255
    elif [ $i -eq $full_octets ]; then
      mask+=$((256 - 2**(8-$partial_octet)))
    else
      mask+=0
    fi
    test $i -lt 3 && mask+=.
  done

  echo $mask
}
