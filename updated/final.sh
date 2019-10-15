#!/bin/bash
#rr=`jq '.diamond.ip | .[]' /root/black.json`
#echo ${#rr}
#exit
config=/root/black.json
var=101
rav=1001

lanfun(){
	
	echo "tc class add dev $1 parent 1:1 classid 1:$2 hfsc sc rate $3Mbit ul rate $3Mbit"
	echo "tc qdisc add dev $1 parent 1:$2 handle $4: fq_codel limit 800 quantum 300 noecn"

}

filterfun(){
	echo "tc filter add dev $1 protocol ip parent 1:0 prio 1 u32 match ip $2 $3 flowid 1:$4"
}


for i in $(jq 'keys | .[]' $config);do
	#echo $i
	iplist=$(jq '.'$i'.ip | .[]' $config)
	int=$(jq .$i.int $config | tr -d '"')
	egressint=`tc filter show dev $int parent ffff: | grep "ifb" | awk '{print $9}' | tr -d ")"`
	#echo $egressint
	if [ ${#iplist} == 0 ] || [ "$egressint" == "" ]; then
		continue
	fi
	#echo $egressint
	#echo $var
	#echo $i
	up=$(jq .$i.up $config | tr -d '"')
	down=$(jq .$i.down $config | tr -d '"')
	#echo $up
	#echo $down
	#echo $int
	#lanfun $int $var $up $rav
	#lanfun $egressint $var $down $rav
	for j in $(jq '.'$i'.ip | .[]' $config | tr -d '"');do
		#echo $j
		lanfun $int $var $up $rav                                     
        	lanfun $egressint $var $down $rav
		filterfun $int dst $j $var
		filterfun $egressint src $j $var
		var=$((var+=1))                                               
        	rav=$((rav+=1))
	done
done
#i="ace"
#echo $(jq .${i}.up /root/black.json)
