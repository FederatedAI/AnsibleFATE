#!/bin/bash

#check open files and max user process
ulimit  -a |egrep 'open files|max user processes'|awk '{ if($1$2 == "openfiles") { if(  $4 <  64000 ) print "Warning: now open files is "$4", and need to turn up to 64000";} if( $1$2$3 == "maxuserprocesses" ) { if(  $5 < 65535 ) print "Warning: now max user processes is "$5", and need to turn up to 65535";} }'

#check swap
mem=$(free -g|grep 'Mem:'|awk '{ print $2; }' )
free -g|grep 'Swap'|awk '{ if( int($2) < '"$(( 128-$mem))"' ) print "Warning: now swap is "$2", need to turn up"; }'
