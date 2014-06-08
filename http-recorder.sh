#!/bin/bash

# load the settings
source $1

(
while true; do
        
        # create new file to hold the data
        datetime=$(date +"%Y-%m-%d_%Hh%Mm%Ss")
        data_file="${datetime}_${app_name}_${machine_id}.tsv"
        
        local i=1
        while i <= $max_lines; do

                # Construct the message, written on a single line.
                # Message consists of meta data and the http response data
                data=$(curl $url 2>> curl-stats.log)
                timestamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
                
                message="$timestamp\t$data\t$script_version\t$machine_id\t\
                        $session_id\t$url\n"

                echo -ne $message >> $data_file
                sleep $delay
                i=$((i+1))
        done
done
) & # the parentheses and & are needed so that script runs as daemon under PPID 1
