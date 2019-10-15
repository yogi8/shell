#!/bin/bash
config=/root/black.json
gname=$2
up=$3
down=$4
int=$5
group_exists(){
	#echo $1
	#echo $2
	#echo $3
	#echo $#
	for i in $(jq 'keys | .[]' $config | tr -d '"');do
		#echo $i
		#echo "known"
		if [ $i == $1 ];then
			echo {'message': 'group exists'}
			return 0
		fi
	done
	return 1
}


value_exists(){                                                                                                                               
        #echo $1                                                                                                                              
        #echo $2                                                                                                                              
        for i in $(jq 'keys | .[]' $config | tr -d '"');do                                                                                    
                #echo $i                                                                                                                      
                #echo "known"                                                                                                                 
                if [ `jq .$i.up $config | tr -d '"'` == $1 ] && [ `jq .$i.down $config | tr -d '"'` == $2 ];then              
                        echo {'message': 'value exists'}                                                                                      
                        return 0                                                                                                              
                fi                                                                                                                            
        done                                                                                                                                  
        return 1                                                                                                                              
}


_create_group(){                                                                                                                
                if !(group_exists $gname || value_exists $up $down);then                                                                        
                        jq '.'$gname'.up = "'$up'"' $config > temp && mv temp $config                                           
                        echo "Added Succesfully"                                                                                
                        jq '.'$gname'.down = "'$down'"' $config > temp && mv temp $config                                       
                        jq '.'$gname'.ip = []' $config > temp && mv temp $config         
                        jq '.'$gname'.int = "'$int'"' $config > temp && mv temp $config  
                else                                                                     
                        echo "Already Exists"                                            
                fi                                                                       
                                                                                         
}


#_create_group(){
#	(group_exists $gname $up $down && echo "exists" || { str=$(jq \
#							--arg UP $up \
#							--arg DOWN $down \
#							--arg INT $int  \
#							'{"up": $UP, "down": $DOWN, "ip": [], "int": $INT }' $config)
#
#						    echo $str
#						    rr=$( jq -n --argjson ss "$str" '{ '$gname' : $ss }')
#						    echo $rr
#						    jq --argjson obj "$rr" '. + $obj' $config > temp && mv temp $config
#						
#						}) && echo "Added Successfully"
#}


_delete_group(){
	echo "hi"
	(group_exists $gname && `jq 'del(.'$gname')' $config > temp && mv temp $config` && echo "Deleted Successfully") || echo "no group with $gname to delete"
}


_update_group() {
	key=$up                                                                                                                               
        value=$down
	group_exists $gname && { up=`jq '.'$gname'.up' $config | tr -d '"'`
				down=`jq '.'$gname'.down' $config | tr -d '"'`
				echo "$up"
				echo "$down"
				if [ $key == up ];then
					up=$value
					echo $up
					echo $down
					if !(value_exists $up $down);then
						echo "1st trap"
						jq '.'$gname'.'$key' = "'$value'"' $config > temp && mv temp $config
					else
						echo "value with up=$up and down=$down already exists"
					fi
				elif [ $key == down ];then
					echo "down"
					down=$value
					if !(value_exists $up $down);then
						jq '.'$gname'.'$key' = "'$value'"' $config > temp && mv temp $config
					else
						echo "value with up=$up and down=$down already exists"
					fi
				else
					jq '.'$gname'.'$key' = "'$value'"' $config > temp && mv temp $config
				fi
				}
}


ip_exists(){
	#totalip=()
	for i in $(jq 'keys | .[]' $config | tr -d '"');do                                                                                    
        	echo $i                                               
        	for j in $(jq '.'$i'.ip | .[]' $config | tr -d '"');do
        		echo $j
			#totalip+=($i)
                	if [ $j == $1 ];then
                        	echo "ip exists"
                        	return 0
                	fi
        	done
	done
	return 1
}

ip_in_group(){
	totalip=()
	inc=0
	for i in $(jq '.'$1'.ip | .[]' $config | tr -d '"');do
		totalip+=($i)
                if [ ! -z "$2" ] && [ $i == $2 ];then
			index=$inc
			#echo $index
                fi
		inc=$((inc+=1))
        done
}



_add_ip(){
	ip=$up
	if (group_exists $gname);then
		if (ip_exists $ip);then
			echo "ip already exists"
		else
			ip_in_group $gname    #$ip
			totalip+=($ip)
			render=`printf '%s\n' "${totalip[@]}" | jq -R . | jq -s .`
			echo $render
			jq '.'$gname'.'ip' = '"$render"'' $config > temp && mv temp $config
			echo "ip added successfully"
			#echo $total
		fi
	else
		echo "group doesn't exists"
	fi
}


_remove_ip(){
	ip=$up
        if (group_exists $gname);then
                if (ip_exists $ip);then
                        echo "ip exists"
			ip_in_group $gname $ip
			if [ ! -z "$index" ];then
                        	#echo "initial"
				#echo $totalip
				unset totalip[$index]
				#echo $totalip
				echo "final"
				echo ${#totalip[@]}
				render=`printf '%s\n' "${totalip[@]}" | jq -R . | jq -s .`
				echo "initial"
                        	echo $render
				if [ ${#totalip[@]} -eq 0 ];then
					jq '.'$gname'.'ip' = []' $config > temp && mv temp $config
				else
                        		jq '.'$gname'.'ip' = '"$render"'' $config > temp && mv temp $config
				fi
                        	echo "ip deleted successfully"
			else
				echo "ip doesn't belong to this group"
                	fi
                else
                        echo "ip doesn't exists"
                fi
        else
                echo "group doesn't exists"
        fi
}


_show_help() {
	
	echo "Usages: $0 [-a|--agroup]        : Add Group"
	echo "Usages: $0 [-d|--dgroup]        : Delete Group"
	echo "Usages: $0 [-u|--ugroup]        : Update Group"
	echo "Usages: $0 [-i|--addip]         : Add IP"
	echo "Usages: $0 [-r|--removeip]      : Remove IP"
}


_exit() {

	_show_help
	exit 1
}

if [ -z $1 ]; then
        _exit
fi

case "$1" in
	-h|--help) _show_help; exit 0;;
	-a|--agroup) 
		if [ $# -ne 5 ]; then
			echo "Argument Required"
                        echo "Usages : $0 $1 <groupname> <up> <down> <interfacename>"
                        exit 1
		fi
		_create_group; shift;;
	-d|--dgroup)
		if [ $# -ne 2 ]; then
			echo "Argument Required"
			echo "Usages : $0 $1 <groupname>"
			exit 1
		fi
		_delete_group; shift;;
	-u|--ugroup)
		if [ $# -ne 4 ] || [ $3 == "ip" ]; then
			echo "Argument Required"
			echo "Usages : $0 $1 <groupname> <up>|<down>|<interfacename> <value>"
			exit 1
		fi
		_update_group; shift;;
	-i|--addip)
		if [ $# -ne 3 ]; then
			echo "Argument Required"
                        echo "Usages : $0 $1 <groupname> <ip>"
                        exit 1
		fi
		_add_ip; shift;;
	-r|--removeip)
		if [ $# -ne 3 ]; then
                        echo "Argument Required"
                        echo "Usages : $0 $1 <groupname> <ip>"
                        exit 1
                fi
                _remove_ip; shift;;
	-*) echo "[ERROR] invalid option: $1"; _exit;;
esac
