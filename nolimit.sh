#!/bin/bash
echo "No no"
sleep 1
echo "No no no no"
sleep 2 
echo "No no no no"
sleep 1
echo "No no"
sleep 1
echo "There's no limit"

echo Hello $USER
echo Theres $# limits
echo first limit was $1
echo second limit was $2
echo third lmiit was $3

function add {
	echo $[$1+$2]
}
add $1 10
add 100 $2


echo $0
