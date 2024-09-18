#!/bin/bash

:  '
	To run this script: sudo chmod -x ~/pass/to/the/script
	And then cd ~/psaa/to/the/script
	And ./unpack.sh -r or -v ~/the/file/or/folder/pass

	If you need to create an "unpack" command, you should write it to the file ~/.bashrc using nano or wim,
	at the end of the file write: alias unpack="~/the/pass/to/the/script"
	And then in the terminal run the command ". ~/.bashrc" to update the current commands in the terminal.
	Now you can run the command "unpack -v or -r file or directory"
	
	I tried to ask if this is alright on the whatsApp, but got answer "hand it as you see it wright"
	'
	
verbose=false
recursive=false
decompressed_count=0
failure=0


unpack_file() {
    local file="$1"
    local target_dir="$2"
    local file_type
    local base_name
    local base_name_no_ext
    local reference
    
    
    file_type=$(file "$file")
    base_name=$(basename "$file")
    base_name_no_ext="${base_name%.*}"
    
    
    if [[ "$file_type" =~ compressed|archive ]]; then
		
		
        if [[ "$file_type" =~ "gzip compressed data" ]]; then
        
            gunzip -c "$file" > "$target_dir/${base_name_no_ext}_gzip_$decompressed_count" 
            decompressed_count=$((decompressed_count + 1))
        
        elif [[ "$file_type" =~ "bzip2 compressed data" ]]; then
        
            bunzip2 -c "$file" > "$target_dir/${base_name_no_ext}_bzip2_$decompressed_count" 
            decompressed_count=$((decompressed_count + 1))
        
        elif [[ "$file_type" =~ "Zip archive" ]]; then
        
            unzip -od "$target_dir" "$file" > /dev/null 2>&1
            
            if [[ -f "$target_dir/zipped.txt" ]]; then
            
                mv "$target_dir/zipped.txt" "$target_dir/${base_name_no_ext}_zip_$decompressed_count" 
                decompressed_count=$((decompressed_count + 1))
            fi
           
        elif [[ "$file_type" =~ "compress'd data" ]]; then
        
            uncompress -c "$file" > "$target_dir/${base_name_no_ext}_uncompressed_$decompressed_count"  
            decompressed_count=$((decompressed_count + 1))
        
        else 
       
            return 0
            
        fi
        
        if [[ $verbose == true ]]; then
        
            echo "Unpacking $base_name..."
		    
        fi

    else
    
    	failure=$((failure+1))
    	
    	if [[ $verbose == true ]]; then
    	
			reference=${base_name#* * } 
			echo "Ignoring $reference..." 
			
    	fi
    	
    fi
    
}


process_file() {
# Helper function

    local file=$1

    local target_dir="${HOME}"
    
    if [[ -d "$file" ]]; then
    
        # If it"s a directory, recurse if the -r option is set
	    
        if [[ "$recursive" == true ]]; then
        	
        	IFS=$'\n' 
        	
            for subfile in $(find "$file" -type f); do
		         
				if [[ -e "$subfile" ]]; then
				
		    	    process_file "$subfile"
		    	    
				else
				
		    	    echo "$subfile does not exist."
		    	    
				fi
    		
            done
            
		else
			
			IFS=$'\n' 
			
			for subfile in $(find "$file" -type f); do
	    
			if [[ -e "$subfile" ]]; then
			
		    	    unpack_file "$subfile" "$target_dir" 
			    
			fi
			
			done
	    
    	fi
    	
    else
    
         unpack_file "$file" "$target_dir"
         
    fi
}


while getopts "rv" opt; do

    case "$opt" in
    
        r) recursive=true verbose=false;;
        v) verbose=true recursive=false;;
        *) echo "Usage: unpack /[/-r/] /[/-v/] file /[file.../]"
        	exit 1 ;;
        	
    esac
    
done


shift $((OPTIND-1))
# Shift away the options processed


if [[ $# -eq 0 ]]; then
# Check if at least one file is provided

    echo "Usage: unpack.sh [-r] or [-v] file [file...]"
    
    exit 1
    
fi


for file in "$@"; do
# Process each file provided as argument

    if [[ -e "$file" ]]; then
    
        process_file "$file"
        
    else
    
        echo "$file does not exist."
        
    fi
    
done

# Output summary
echo "Decompressed $decompressed_count archive(s)"


# Return the number of files that were not decompressed as the exit code
exit "$failure"
