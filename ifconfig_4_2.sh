#!/bin/bash

echo -e "\nEnter 1 to display all network interface information first."
echo -e "Enter any other key to continue.\n"
read option

if [[ "$option" -eq 1 ]]; then
    ifconfig
fi
  
output() {
    while true; do
    
        available=($(echo "$paragraph" | grep -oE "$(IFS='|'; echo "${!mappings[*]}")" | sort -u))
        len=${#available[@]}
        
        if [[ $len -eq 1 ]]; then
            word="${available[0]}"
            value=$(ifconfig "$interface" | grep "$section" | grep -oP "(?<="$word" )\S+")
            echo -e "\n$word: $value\n"
            break
        else
            echo -e "\nSelect the information you want to check in "$information":\n"
    
            index=1
            for key in "${available[@]}"; do
                echo "$index: ${mappings[$key]}"
                ((index++))
            done
               
            echo ""
            read -p "Enter your choice (1-$len): " select
                
            if (( select < 1 || select > len )); then
                echo -e "\nInvalid choice. Please select a number from 1 to $len."
                continue
            else
                word="${available[$((select-1))]}"
                value=$(ifconfig "$interface" | grep "$section" | grep -oP "(?<="$word" )\S+")
                echo -e "\n$word: $value\n"
            fi
        fi    
                
        while true; do
            read -p "Do you want to check something else in this section? (y/n): " cont
                
            if [[ "$cont" == "y" ]]; then
                break
            elif [[ "$cont" == "n" ]]; then
                echo ""
                break 2
            else
                echo -e "\nInvalid choice. Please enter either y for yes or n for no.\n"
            fi
        done               
    done
}

while true; do
    echo -e "\nSelect the network interface you want information from:\n"

    ifconfig | awk -v RS='' -v FS='\n' '{
        split($1, words, " ")   # Split first line into words
        gsub(":", "", words[1]) # Remove colons from the first word
        print "" NR " = " words[1] 
    }' 

    n=$(ifconfig | awk -v RS='' 'END {print NR}')

    echo ""
    read -p "Enter your choice (1-$n): " choice

    if (( choice < 1 || choice > n )); then
        echo -e "\nInvalid choice. Please enter a number from 1 to $n."
        continue
    fi

    interface=$(ifconfig | awk -v RS='' -v FS='\n' -v choice="$choice" 'NR==choice {
        split($1, first_word, " ")
        gsub(":", "", first_word[1])
        print first_word[1]
    }')
    
    paragraph=$(ifconfig "$interface")

    # Checking if interface is turned on and displaying status
    if ifconfig | awk '/^'"$interface"'/ && /UP/' > /dev/null; then
        echo -e "\nThe '$interface' interface is TURNED ON.\n"
    else
        echo -e "\nThe '$interface' interface is TURNED OFF.\n"
    fi
    
    declare -A Mappings=(
        ["mtu"]="Maximum Transmission Unit (MTU)"
        ["txqueuelen"]="Transmission queue length (txqueuelen)"
        ["ether"]="MAC / IP Address(es)"
        ["inet"]="MAC / IP Address(es)"
        ["inet6"]="MAC / IP Address(es)"
        ["RX"]="RX (Received Data)"
        ["TX"]="TX (Transmitted Data)"
    )
            
    Available=($(echo "$paragraph" | grep -oE "$(IFS='|'; echo "${!Mappings[*]}")" | sort -u))
    Len=$(echo "${#Available[@]}")
        
    if [[ $Len -eq 0 ]]; then
        echo -e "Sorry, no information is available for the $interface interface.\n"
        continue
    fi
        
    while true; do
        echo -e "Select the information you want to check in "$interface":\n"
            
        declare -A seen  # Associative array to track unique elements    
        unique_arr=()
            
        for key in "${Available[@]}"; do
            if [[ -z "${seen[${Mappings[$key]}]}" ]]; then
                unique_arr+=("${Mappings[$key]}")
                seen["${Mappings[$key]}"]=1
            fi
        done
            
        unset seen
           
        index=1
        for i in "${unique_arr[@]}"; do
            echo "$index: $i"
            ((index++))
        done
            
        uniq_len=${#unique_arr[@]}
          
        echo ""
        read -p "Enter your choice (1-$uniq_len): " info
               
        if (( info < 1 || info > uniq_len )); then
            echo -e "\nInvalid choice. Please select a number from 1 to $uniq_len.\n"
            continue
        else
            Map_value="${unique_arr[$((info-1))]}"
               
            selected=$( 
            for Map_key in "${!Mappings[@]}"; do
                if [[ "${Mappings[$Map_key]}" == "$Map_value" ]]; then
                    echo "$Map_key"
                    break
                fi
            done    
            )
                
            if [[ "$selected" == "mtu" || "$selected" == "txqueuelen" ]]; then
                value=$(ifconfig "$interface" | grep -oP "(?<="$selected" )\S+")
                echo -e "\n$selected: $value\n" 
           
            elif [[ "$selected" == "ether" || "$selected" == "inet" || "$selected" == "inet6" ]]; then
                information="IP Addresses"
                section=""
                
                declare -A mappings=(
                    ["inet"]="IPv4 Address"
                    ["inet6"]="IPv6 Address"
                    ["ether"]="MAC Address"
                    ["netmask"]="Netmask"
                    ["broadcast"]="Broadcast"
                    ["prefixlen"]="Prefix Length"
                    ["scopeid"]="Scope ID"
                )
 
                output
            
            elif [[ "$selected" == "RX" ]]; then
                information="RX"
                section="RX"

                declare -A mappings=(
                    ["packets"]="Packets Received"
                    ["bytes"]="Bytes Received"
                    ["errors"]="Receive Errors"
                    ["dropped"]="Dropped Packets"
                    ["overruns"]="Overruns"
                    ["frame"]="Framing Errors"
                )
                
                output
                                    
            elif [[ "$selected" == "TX" ]]; then
                information="TX"
                section="TX"
            
                declare -A mappings=(
                    ["packets"]="Packets Transmitted"
                    ["bytes"]="Bytes Transmitted"
                    ["errors"]="Transmit Errors"
                    ["dropped"]="Dropped Packets"
                    ["overruns"]="Overruns"
                    ["carrier"]="Carrier Errors"
                    ["collisions"]="Collisions"
                )
                
                output
            
            fi
        fi           
        
        while true; do
            read -p "Do you want to check some other "$interface" information? (y/n): " cont1
            echo ""
            
            if [[ $cont1 != y && $cont1 != n ]]; then
                echo -e "Invalid choice. Please enter either y for yes or n for no.\n"
                continue
            elif [[ "$cont1" == "n" ]]; then
            
                while true; do
                    read -p "Do you want to check another interface? (y/n): " cont2
                    
                    if [[ $cont2 != y && $cont2 != n ]]; then
                        echo -e "\nInvalid choice. Please enter either y for yes or n for no.\n"
                        continue
                    elif [[ "$cont2" == "y" ]]; then
                        break 3 #breaking out of all 3 loops to go to the interface section
                    else
                        echo -e "\nExiting program.\n"
                        exit 0
                    fi
                done
                
            else
                break
            fi
            
        done   
    done
done
