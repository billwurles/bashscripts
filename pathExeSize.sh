#!/bin/bash

for thePath in $(echo $PATH | tr ":" "\n"); do
	result=`du $thePath -ch | tail -1 | awk '{print $1}'`
	echo The size of $thePath is $result
done
