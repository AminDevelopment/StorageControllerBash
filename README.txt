Storage Controller Manual


What it can do?
->Allows user to specify how back a program can go back to search for duplicates
->Searches for duplicates in Desktop and Download partitions of the computer
->Uses default time_frame of 5 days:
				1) list out and sort all files created in the last five days
				2) counts the size of each sorted file name into an array
				3) then uses double pointers to check if their are any files of the same size
				4) files of the same size are compared bit by bit to test if they are duplicates
				5) Any file that is found to be a duplicate (the second found file) is put into a delete array
				6) After all found files have been tested the delete array looped through and all files it contains are deleted.
				7) Updates a report log with the current date and the number of duplicates found

->Runs automatically using crontab: 55 22 * * * /Users/nabeelamin/Desktop/PERSONAL_PROJECTS/Bash_scripts/Storage_Controller/main-driver.sh


