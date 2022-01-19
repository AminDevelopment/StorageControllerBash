#!/bin/bash 

#global variables

file_size=()


#Produces a list in the time alotted 
#saves list in list_file.txt
#Expected output to link_list.txt is: Usr/nabeelamin/Desktop/... + [Int_size] or Usr/nabeelamin/Download/..... + [Int_size]
list_and_sort() {
    find ~/Desktop ~/Downloads -type f ! -name '*.DS_Store' ! -name 'link_list.txt' ! -name 'new_link_list.txt' ! -name 'duplicate_list.txt' -Btime -$1 -exec printf {}" " \; -exec stat -f%z {} \; > link_list.txt

    #Checks to see if file is empty
    if [ ! -s link_list.txt ];
    then 
        return 100
    fi

    #Check to see if file contains only one line (can't have duplicates if there is only one file)
    line_count=$(wc -l < link_list.txt)
    if [ $line_count -eq 1 ];
    then 
        return 100
    fi



    #sort text file by second column - size
    sort -nk2 link_list.txt > new_link_list.txt

    #Get rid of old list file
    rm link_list.txt


    return 0
}

#saves items to be removed on to duplicate_list.txt
remove_item_list() {
    file_info=$1
    echo $file_info >> duplicate_list.txt

}


#called at the end of the main function to delete all files in duplicate_list.txt
remove_list(){
    {
        read
        while IFS= read -r line
        do
            rm $line
        done 
    } < "duplicate_list.txt"
}

#determines if the same size files are the same files
#take in $1 and $2 file indexes
#call remove_item if the files are duplicates
determine_removal(){
    #set variables from callee
    first_d=$1
    second_d=$2

    #increment vars to match file indexing ( file index starts at 1 and array index starts at 0 )
    ((first_d++))
    ((second_d++))

    #get absolute paths to files
    first_address=$(sed -n "${first_d}p" new_link_list.txt | awk '{ print $1 }')
    second_address=$(sed -n "${second_d}p" new_link_list.txt | awk '{ print $1 }')


    #echo "In determine -> First  index: $first_d, First address: $first_address"
    #echo "In determine -> Second index: $second_d, Second address: $second_address"

    #compare files
    if cmp -l $first_address $second_address
    then
        remove_item_list "$second_address"
    else  
        open $first_address
        open $second_address
        echo " "
        echo "They did not match"
        echo "~Printing out First file~"
        sed "${first_d}p" $first_address
        echo "~Printing out Second file~"
        sed "${second_d}p" $second_address
        echo " "

    fi
}


#Compares the files if they are the same size
compare_size() {

    #variable defintions
    second=1
    first=0
    length=${#file_size[@]}

    #compares sizes of a the ordered files until second is equal to file count
    while [ "$second" -lt "$length" ]
    do 
        #find element sizes
        item=${file_size[$first]}
        item_two=${file_size[$second]}
        
        #compare element sizes
        if [[ "$item" = "$item_two" ]]
        then
            #on pass √ -> increment second by 1 and keep first the same
            determine_removal "$first" "$second"
            ((second++))
        else 
            #on fail X -> increment first to second value and increment second by 1
            first=$second
            ((second++))
        fi      
            
    done    
}



#Calculates the sizes of the files
#puts size in array with indexes that match line number of a files address
size_counter() {
    while IFS= read -r line
    do
        size=$(echo $line | awk '{ print $2 }')
        file_size+=($size)
    done <  "new_link_list.txt"
    echo "Array concents: ${file_size[@]}"

}

#updates report log with the date and the number of duplicates found
update_report_log() {
    line_count=$(wc -l < duplicate_list.txt)
    ((line_count=line_count-1))
    date=$(date '+%Y-%m-%d')
    echo "$date: This program ran and found $line_count duplicates today" >> report_log.txt
}


#Main function
main () {
    #Allows user to specify time frame
    #echo "from what time should we start the search (in days)? "
    #read time_frame
    #echo "                       --------Finding files created in the last ${time_frame} days --------"

    

    #default time frame is 5
    time_frame=5

    #find list and sorts based of each files size, displays size of each file after the file path in new_link_list.txt
    list_and_sort "$time_frame"

    #Checks for a failure case which occurs if the find in link_and_sort produces an empty list or only one element 
    local failed=$?

    if [ $failed -eq 100 ];
    then 
        echo "This program can not be utilized today :<"
        date=$(date '+%Y-%m-%d')
        echo "$date: This program ran and found no duplicates today" >> report_log.txt
        return
    fi

    #Clears duplicate_list.txt for the new list of items to remove
    echo "This is a list of files to remove" > duplicate_list.txt


    #Calculates sizes of the files
    size_counter

    #using sizes of each item, it compares files of the same size
    #then calls determine_removal -> determines if two files of the same size are duplicates
    #determine_removal calls remove_item_list which creates a list of items to be removed in duplicate_list.txt
    compare_size

    #remove_list is called to delete all the files contained in duplicate_list.txt
    #Only enters remove_list if duplicate_list.txt contains any files to remove
    line_count=$(wc -l < duplicate_list.txt)
    ((line_count=line_count-1))
    if [ $line_count -gt 0 ];
    then
        remove_list
    fi

    #Updates report log with the number of deletions for the day as well as the date
    update_report_log 

    echo "At the end of main - finshed up with the program"

 
}


main