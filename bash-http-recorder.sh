#!/bin/bash

# load the settings
# Arguments: relative path of the configuration file

if [ $# -eq 0 ]; then
    echo "No arguments (config file path) provided"
    exit 1
fi

source $1 # the config file

(
while true; do
        
        # create new file to hold the data
        datetime=$(date +"%Y-%m-%d_%Hh%Mm%Ss")
        data_file="${datetime}_${app_name}_${machine_id}.tsv"
        
        i=1
        while [ $i -le $max_lines ]; do

                # Construct the message, written on a single line.
                # Message consists of meta data and the http response data
                data=$(curl $url 2>> curl-stats.log)
                timestamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
                
                # $s is the field separator defined in the config file
                message="$timestamp$s$data$s$script_version$s$machine_id$s\
                        $session_start$s$url\n"

                echo -ne $message >> $data_file
                sleep $delay
                i=$((i+1))
        done

        # Remove duplicate lines?
        if [ "$del_dup_lines" = "TRUE" ]; then
                # The first field is a timestamp which is always unique.
                # Do not use it when searching for duplicates.
                skip_num_chars=$(tail -1 "$data_file" \
                                 | awk -F "$s" '{print $1}' | wc --chars)
                total_lines=$(wc -l $data_file | cut -d " " -f 1)
                num_uniq_lines=$(uniq -s $skip_num_chars $data_file | wc -l)
                num_dups=$(( $total_lines - $num_uniq_lines))
                tmp="/tmp/bash-http-recorder.txt"
                cat <(cat $data_file | uniq -s $skip_num_chars -u) <(cat $data_file | uniq -s $skip_num_chars -d) | sort -n > $tmp
                cat $tmp > $data_file 
                rm $tmp

                timestamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
                echo -ne "$timestamp\tDeleted $num_dups duplicated lines\n" >> $log
        fi

        # compress once we are done writing to a file?
        if [ "$gzip" = "TRUE" ]; then
                gzip $data_file &> $log
        fi

done
) & # the parentheses and & are needed so that script runs as daemon under PPID 1
