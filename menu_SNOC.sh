#!/bin/bash
# Starting Off With a She-Bang

# GitLab Project:		https://lgit2p.fenetwork.com/C54917a/menu_snoc
# Written by:			Corey Johnson

# A few things
# 1.)	Only the root user can run this script. See $Root_Test variable... Note: script exits with an error if it is not ran as root
# 2.)	This script creates a profile for each user that runs this script. This profile contains temp files created while running various functions in this script and a config file that gives users the capability to store their username that they use to ssh to Cisco devices [ See Multi_Cisco_Menu() ] and users can customize the ANSI color codes that are displayed while running this script [ See Color_Menu() ]
# 3.)	Files created from this script have a static nano-second timestamp appended to filenames. This timestamp is set when the script is first launched. Therefore, multiple instances of this script can be ran without any conflicts since filenames will always be different. It is recommended to use a Terminal Multiplexer like screen or tmux.

### Basics of how this program works
#
#	This program is menu driven... The Menu that is displayed is the last element in the array "Menus"
#		See the logic at end of this script. Note: when $choice = 0 the last element of array is removed
#
#	Every time that a menu is diplayed, the RM_Files() function is called to reinitialize files
#	This ensure when the user chooses to run another function, variable checks can be performed correctly and blank files will be used to collect and display output
#		Deletes some temp files (which are commonly used to collect and display command output)
#			$Temp_File	$Temp_Output_File	$Output_File
#		Unsets a variable checking variable	$Var_Check
#
### Ensuring variables are set prior to running a function
#	Before users run a function you need to make sure the necessary variables are set for the function to run correctly
#	BEFORE calling a query / action function to run against a server, you need to make sure all needed variables are defined 
#	Several functions exist to do this. These functions are:
#
#	CHECK USING		DEFINED IN	VARIBALE	CHECK TYPE	Additional Info
#	C_Server()		D_Servername()	Server		Y/N Ping	Unsets $Server if ping failed. Defined in a few other places too.
#	C_Database()		D_Database()	Database	Y/N		Can be dynamically set via pattern matching with C_Single_Alarm_Set_Vars()
#	C_Directory()		D_Directory()	Directory	Y/N		Can be dynamically set via pattern matching with C_Single_Alarm_Set_Vars()
#	C_RMAN_File()		See RMAN_Menu()	RMAN_File	Y/N		Defined using option "Define: RMAN Log" in RMAN_Menu()
#	C_FS_Size_Increment()	D_FS_Increase()	FS_Size_Inc	Y/N numeric	Checks are made in the D_FS_Increase() function to ensure a valid increment is defined.
#	C_Cisco()		D_User_Cisco()	User_Cisco	Multi		Checks $User_Cisco and runs C_Custom_Command() and C_Multi_Server() functions
#	C_Multi_Server()	D_M_Server()	M_Server_Size	Y/N numeric	Based on the number of lines in $M_Server_File
#	C_LV() 			D_Directory)	(Multiple)	Multi Dynamic	Checks $VG_Free_PPs_MB and $Volume_Group variables to ensure LVM VG info was found
#
#	After defining necessary variables using functions from the coloumn "DEFINED IN" call the corresponding "CHECK USING" function to check each variable.
#	If the appropriate variable is not defined when performing individual variable checks using the C_*() functions the $Var_Check variable gets set
#	The last step to complete the check is to call the function C_Vars() to check the $Var_Check variable.
#	If the $Var_Check variable is set, the $Var_Check variable gets unset and the current menu is redisplayed.
#
#	See options listed in *_Menu() functions to give you an idea how variable defining and checking is done!
#
### Running Commands Remotely
#	This script utilizes the script /scripts/bin/ssh-wrapper.sh to run commands as the root user on remote UNIX nodes via SSH
#	/scripts/bin/ssh-wrapper.sh restricts some commands that have the capability to comprimise the shell.
#	
#	If Command Logging is needed
#		When a user choses an option to run against a server the Log_and_Run_Commands() function can be used for accountability purposes.
#		It is very important to use this function when any non-query command is used. Therefore, the person that ran the command can be held accountable.
#		This is how the Log_and_Run_Commands() function works and shows a few ways to capture output:
#			Commands to be ran must be added in sequetial order to the $Command_File prior to calling Log_and_Run_Commands()
#			A loop through the commands is started... For each command in $Command_File, the following happens
#				First,	the Timestamp, User, Server, and Current Command is appended to the $Log_File
#				Second,	the Current Command is ran against the server $Server
#			It is possible to capture the output of the command loop using this function. Here are some examples
#				1.)	Echo straight to the console.					Log_and_Run_Commands
#				2.)	Assign to a variable by using command substitution.		var=$(Log_and_Run_Commands) 
#				3.)	Append output to a temporary file.				Log_and_Run_Commands >> $Temp_Output_File
#				4.)	Echo to console and append to file.				Log_and_Run_Commands | tee -a $Temp_Output_File
#
#	Examples of when Log_and_Run_Commands() should be used include:		(These functions all modify server configuration in some way)
#		OM_Agent_Restart_UNIX()	Restart_TSM_Client_Acceptor()	Resize_FS()	Resize_LV()
#
#	If Command Logging is NOT needed    (Only when runnig commands that wont affect server configuration in ANY way)
#		To just run a command without logging use something like
#			$SSH $Server ps -ef
#		The above line would use SSH with optimal options to connect to the server $Server and run the command "ps -ef"
#		Capturing remote command output is very similar to the above Log_and_Run_Commands() examples
#			1.)	Echo straight to the console					$SSH $Server [COMMAND]
#			2.)	Assign to a variable by using command substitution.		var=$($SSH $Server [COMMAND]) 
#			3.)	Append output to a temporary file.				$SSH $Server [COMMAND] >> $Temp_Output_File
#			4.)	Echo to console and append to file.				$SSH $Server [COMMAND] | tee -a $Temp_Output_File
#
#	Examples of running commands remotely without logging include:
#		G_Export_Error()	G_TSM_Processes()	G_TSM_Config()		G_DF_FS()
#		G_OM_Agent_Status()	Test_OM_Agent()		OM_Agent_Restart()
#		
#
### Capturing, Coloring, and Viewing Output
#	See "### Logging Commands" for info on how to log and capture command output
#	SOME VERY IMPORTANT NOTES
#		The View_Output() function will only display lines that contain the ANSI Color Code $STD
#		When ever a menu is displayed, the RM_Files() function is called to remove temp files. (including $Temp_Output_File and $Output_File)
#
#	(Recommended Method)
#	In most cases, you want your output to end up colorized in the $Output_File.
#	This way output can be viewed with the View_Output() function
#
#		In most cases, the best way to do this is to use redirection to send STDOUT to $Temp_Output_File and then call the function Color_and_RM_Temp_Output()
#		Optionally, you can also redirect STDERR to $Temp_Error_File and call Color_and_RM_Temp_Error()
#			See	G_OM_Agent_Status()	G_MPIO()	Resize_FS()
#
#		After storing the output you want colored in $Temp_Output_File and errors you want colored in $Temp_Error_File
#		Call either or both of these functions...
#			Color_and_RM_Temp_Output()
#				Wraps each line in $Temp_Output_File with ANSI color codes $Cust_Output and $STD
#				Appends ANSI wrapped text to $Output_File
#			Color_and_RM_Temp_Error()
#				Wraps each line in $Temp_Error_File with ANSI color codes $Cust_Error and $STD
#				Appends ANSI wrapped text to $Output_File
#
#	Note:	When echoing lines it is posible and useful to use Parameter Expansion to wrap lines with ANSI Color Codes.	See "man bash"
#		ANSI Color Code variables that are used in this script:
#			$Cust_Output	$Cust_Error	$Cust_Menu	$STD
#		Example of echoing a color wraped line:
#			echo -e "${Cust_Error}Server [$Server] did NOT respond to ping test ${STD}"
#
#	Alternative Methods Used To Display Output Include:
#	1.)	echo the line straight to the console and use pause()	(Useful when printing errors to the screen)  (Or when debugging)    :)
#			See	D_FS_Increase()		G_VG()		Resize_LV()	Color_Menu()
#	2.)	echo the line and redirect output directly to $Output_File so output can be displayed all at once using the function View_Output()
#			See	G_DB_Logfile_Sync()	G_TSM_Log()	G_TSM_Config()	Restart_TSM_Client_Acceptor()	G_Mount()
#	3.)	echo the line straight to the console and pipe to "tee" to overwrite or append that line to a file
#			See	G_Export_Error()	G_Cisco_Output()	Multi_Cisco_Menu()

################################################################
#################### Define Variables ##########################
################################################################

#set -m	# This breaks View_Output...

# Set Standard color code variables...
STD='\033[0;37;40m'
std=$(echo $STD | sed 's/\\033/\\e/')
StartTime=$(date "+%m-%d-%y.%M.%S.%N")	# Appended to temporary files that are created when running the script... Allows multiple instances to be ran from one host
SSH='ssh -o StrictHostKeyChecking=no -o LogLevel=quiet -o NumberOfPasswordPrompts=0 -o ConnectTimeout=2'	# Sets the default SSH params to suppress unimportant SSH output
Main_Node=$(uname -n)   # Not used... May be useful in a centralized log file in the future...
Root_Test=$(whoami)	# Must have root privledges to run this script
Main_User=$(who am i | awk '{ print $1 }')	# Grabs the username of the user who launched the script... Used for Logging / Accounting
Script_Temp_Dir="/home/C54917a/SNOC_Script"	# Where User Profiles and Script Temp Files are created, stored, and destroyed
Subscript_Dir="/home/C54917a/SNOC_Script/Subscripts"	# Where Files and Remote scripts are stored

if [ "$Root_Test" != "root" ]; then
	clear; echo -e "\033[1;97;41mroot privileges required! Run   sudo snoc${STD}"; exit 255 # Run along kid, it's past your bedtime.
fi

# Check / Create User Folder to hold user's config file and the script's temporary files 
if [ ! -d "${Script_Temp_Dir}/${Main_User}" ]; then
	mkdir "${Script_Temp_Dir}/${Main_User}";
fi

# Set file locations...  Note: when exiting the script normally, all temp files that contain "SNOC_Script" will be removed
Config_File="${Script_Temp_Dir}/${Main_User}/User_Config_File"
Log_File="/var/audit/SNOC_menu_log.csv"
Log_File_Cisco="/var/audit/SNOC_menu_log_Cisco.csv"
Less_Volatile_Temp_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Less_Volatile_Temp_File-${StartTime}"  # Does not get deleted when a menu is displayed...
Temp_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Temp_File-${StartTime}"
Temp_Error_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Temp_Error_File-${StartTime}"
Temp_Output_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Temp_Output_File-${StartTime}"
Output_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Output_File-${StartTime}"
Command_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Command_List-${StartTime}"
Sed_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Sed_File-${StartTime}"
Banner_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Banner"
M_Server_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Multi_Server_list-${StartTime}"
M_Server_Up_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Multi_Server_Up_list-${StartTime}"
M_Server_Down_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Multi_Server_Down_list-${StartTime}"
M_Commands_File="${Script_Temp_Dir}/${Main_User}/SNOC_Script_Multi_Commands_list-${StartTime}"
M_Server_Size=-1
Down_Server_Size=-1

################################################################
################# Define Config File Functions #################
################################################################

Create_Config_File(){
	# Set default standard colors, which the user can override
	# Defaults the config file to sensible color codes and sets the Cisco Username to be the current user's non-A account
	rm -f $Config_File
	echo "#   SNOC Script Config File" > $Config_File
	echo "#   NOTE: Spacing is Critical. There must be a space before and after the \"=\" sign" >> $Config_File
	echo "#         Manually Editing is probably a bad idea..." >> $Config_File
	echo "" >> $Config_File
	echo "User_Cisco = $Main_User" | sed 's/a//g' >> $Config_File
	echo "Cust_Error = \\033[1;97;41m" >> $Config_File
	echo "Cust_Output = \\033[1;92;40m" >> $Config_File
	echo "Cust_Menu = \\033[1;94;40m" >> $Config_File
	echo "Randomness = 0" >> $Config_File
	echo "Randomize = Cust_Output" >> $Config_File
	echo "Always_Show_DB_PW = 1" >> $Config_File
	echo "Always_Show_DB_FS = 1" >> $Config_File
	echo "NODE_NAME_Field = 0" >> $Config_File	# 0 prompts user to define when wanting to paste an alarm in
	echo "Remember_Colors = 0" >> $Config_File
	echo "Show_Warnings = 1" >> $Config_File
	if [[ "$Main_User" == "C54917a" ]];then echo "Dev_Mode = 1" >> $Config_File
	else echo "Dev_Mode = 0" >> $Config_File;fi
	echo "MOTD = \"SNOC Linux Script   \"" >> $Config_File
	echo "sMark_Bot = 0" >> $Config_File
	echo "Leon_Bot = 0" >> $Config_File
	echo "Scroll_Direction = 0" >> $Config_File
	echo "Menu_Refresh_Rate = 700" >> $Config_File
	echo "MOTD_All = 0" >> $Config_File
	echo "Banner_Disabled = 0" >> $Config_File
	echo "Scroll_Intensity = 1" >> $Config_File
	echo "Banner_Padding = 3" >> $Config_File
}

Read_Config_File(){
	# Sets variables based on config file...  Allows for customizable colors and remembers the last username used in the Cisco Menu
	# Note:  the varables ending in _pf convert the current ANSI code to a code that can be used by the "tput" command for printing arrays
	User_Cisco=$(cat $Config_File | grep "^User_Cisco" | awk '{ print $3 }')
	Read_Colors
	Randomness=$(cat $Config_File | grep "^Randomness" | awk '{ print $3 }')
	Randomize=$(cat $Config_File | grep "^Randomize" | awk '{$1=$2=""; print $0}')
	Color_Vars=($Randomize)
	Always_Show_DB_PW=$(cat $Config_File | grep "^Always_Show_DB_PW" | awk '{ print $3 }')
	Always_Show_DB_FS=$(cat $Config_File | grep "^Always_Show_DB_FS" | awk '{ print $3 }')
	NODE_NAME_Field=$(cat $Config_File | grep "^NODE_NAME_Field" | awk '{ print $3 }')
	Remember_Colors=$(cat $Config_File | grep "^Remember_Colors" | awk '{ print $3 }')
	Show_Warnings=$(cat $Config_File | grep "^Show_Warnings" | awk '{ print $3 }')
	Dev_Mode=$(cat $Config_File | grep "^Dev_Mode" | awk '{ print $3 }')
	if [ -z "$MOTD" ];then
		MOTD=$(cat $Config_File | grep "^MOTD =" | grep -oP '(?<=MOTD = ").*(?=")')
	fi
	sMark_Bot=$(cat $Config_File | grep "^sMark_Bot" | awk '{ print $3 }')
	Leon_Bot=$(cat $Config_File | grep "^Leon_Bot" | awk '{ print $3 }')
	Scroll_Direction=$(cat $Config_File | grep "^Scroll_Direction" | awk '{ print $3 }')
	Menu_Refresh_Rate=$(cat $Config_File | grep "^Menu_Refresh_Rate" | awk '{ print $3 }')
	MOTD_All=$(cat $Config_File | grep "^MOTD_All" | awk '{ print $3 }')
	Banner_Disabled=$(cat $Config_File | grep "^Banner_Disabled" | awk '{ print $3 }')
	Scroll_Intensity=$(cat $Config_File | grep "^Scroll_Intensity" | awk '{ print $3 }')
	Banner_Padding=$(cat $Config_File | grep "^Banner_Padding" | awk '{ print $3 }')
}

Read_Colors(){
	Cust_Error=$(cat $Config_File | grep "^Cust_Error" | awk '{ print $3 }')
	Cust_Error_pf=$(echo $Cust_Error | sed 's/\\033/\\e/')
	Cust_Output=$(cat $Config_File | grep "^Cust_Output" | awk '{ print $3 }')
	Cust_Output_pf=$(echo $Cust_Output | sed 's/\\033/\\e/')
	Cust_Menu=$(cat $Config_File | grep "^Cust_Menu" | awk '{ print $3 }')
	Cust_Menu_pf=$(echo $Cust_Menu | sed 's/\\033/\\e/')
}

Print_Colors(){
	#  Prints ANSI Color Code Sequences with configured options...
	if [ "$Opt_FG" == "FG_Bright" ]; then Seq_FG="90 97"; else Seq_FG="30 37"; fi
	if [ "$Opt_BG" == "BG_Bright" ]; then Seq_BG="100 107"; else Seq_BG="40 47"; fi
	for f in 29 $(seq $Seq_FG); do
		for b in 39 $(seq $Seq_BG); do
			FG="$f"
			BG="$b"
			if [ "$f" -eq "29" ]; then unset Colon FG; else Colon=";"; fi
			if [ "$b" -eq "39" ]; then unset Colon BG; fi
			code="\033[${Bold}${Dim}${Under}${Blink}${FG}${Colon}${BG}m"
			echo -e -n "${code}$(echo \\$code)\033[0m "
		done
		echo
	done
}

Reset_Colors(){
	sed -i "s/Cust_Error = .*/Cust_Error = \\$(echo "\033[1;97;41m")/" $Config_File
	sed -i "s/Cust_Output = .*/Cust_Output = \\$(echo "\033[1;92;40m")/" $Config_File
	sed -i "s/Cust_Menu = .*/Cust_Menu = \\$(echo "\033[1;94;40m")/" $Config_File
	sed -i "s/Randomness = .*/Randomness = 0/" $Config_File
	sed -i "s/Randomize = .*/Randomize = Cust_Output/" $Config_File
	Read_Colors
}

Randomize_Colors(){
	Color_Vars_Size=$((${#Color_Vars[@]}-1))
	Colon=";"
	for i in $(seq 0 $Color_Vars_Size); do
		Var="${Color_Vars[$i]}"
		Bool_01=$(shuf -i 0-1 -n 1);if [ "$Bool_01" -eq "0" ]; then Bold="1;";else unset Bold;fi
		Bool_01=$(shuf -i 0-1 -n 1);if [ "$Bool_01" -eq "0" ]; then Under="4;";else unset Under;fi
		Bool_01=$(shuf -i 0-1 -n 1);if [ "$Bool_01" -eq "0" ]; then FG=$(shuf -i 90-97 -n 1);else FG=$(shuf -i 30-37 -n 1);fi
		Bool_01=$(shuf -i 0-1 -n 1);if [ "$Bool_01" -eq "0" ]; then BG=$(shuf -i 100-107 -n 1);else BG=$(shuf -i 40-47 -n 1);fi
		while [ "$(( ($FG - $BG) % 10 ))" == "0" ]; do
			# Change Background color so Foreground and Background are different
			Bool_01=$(shuf -i 0-1 -n 1);if [ "$Bool_01" -eq "0" ]; then BG=$(shuf -i 100-107 -n 1);else BG=$(shuf -i 40-47 -n 1);fi
		done 
		code="\033[${Bold}${Under}${Blink}${FG}${Colon}${BG}m"
		sed -i "s/${Var} = .*/${Var} = \\$(echo "$code")/" $Config_File
	done
	Read_Colors
	unset Colon Bold Under FG BG code Dim Blink
}

Check_Cust_Color(){
	# Checks to verify that an ANSI Color Code sequence was provided in the function Cust_Color_Code
	if [ "$(cut -d\[ -f1 <<< $Cust_Color_Code)" != "033" ]; then
		echo -e "${RED}ANSI Color Code Check Failed${STD}"
		Var_Check="Failed"
	fi
	if [ "$(cut -d\[ -f1 <<< $(echo "$Cust_Color_Code" | rev) | cut -d\; -f1 | sed 's/[0-9]*//g')" != "m" ]; then
		echo -e "${RED}ANSI Color Code Check Failed${STD}"
		Var_Check="Failed"
	fi
}

################################################################
################# Define Common Functions ######################
################################################################

pause(){  # Mainly useful for printing errors.. Can be used to see things echoed to the console...
	read -p "Press [Enter] key to continue..." fackEnterKey
}

paused(){
	if [[ "$Dev_Mode" -eq "1" ]];then pause;fi
}

D_Servername(){
	clear
	rm -f $M_Server_File 2> /dev/null
	unset OS_Test
	read -p "Define Servername:   " Server
}

C_OS_Test(){
	# Figure out the Operating System... ( Windows, AIX, Linux )
	if [ ! -z "$Server" ]; then
		if [ -z "$OS_Test" ]; then
			if [[ "$Server" == "w"* ]]; then
				OS_Test="Windows"
			else
				echo "uname" > $Command_File
				OS_Test=$($SSH $Server uname)
				if [ $? -eq 255 ]; then
					echo -e "${Cust_Error}SSH has encountered and error${STD}"
					unset OS_Test Server
					sleep 1
				fi
			fi
		fi
	fi
}

D_Database(){
	clear
	read -p "Define Database:   " Database
}

D_Directory(){
	clear
	unset Directory
	if [[ "$FS_Action" == "Obtain" ]] && [[ "$Main_Function" == "Obtain" ]] && [[ "$Show_Warnings" -eq "1" ]]; then
		echo -e "${Cust_Error}      Define absolute path of a filesystem    i.e.   /oracle/database/dbfiles1                                        ${STD}"
		echo -e "${Cust_Error}  Or, Specify a Logical Volume to list all filesystems mounted on that LV                                             ${STD}"
		echo -e "${Cust_Error}  Or, Specify a Filesystem Type to list all filesystems of that filesystem type   i.e.   jfs2 , nfs , ext4            ${STD}"
		echo -e "${Cust_Error}                                                                                                                      ${STD}"
		echo -e "${Cust_Error}  Alternatively, Use the \"mount\" option to list all directories                                                       ${STD}"
		echo -e "${Cust_Error}                                                                                                                      ${STD}"
		echo -e "${Cust_Error}  Note: The \"Directory\" variable is only set when specifying an absolute path of a Filesystem's mount point           ${STD}"
		echo -e "${Cust_Error}                                                                                                                      ${STD}"
	fi
	read -p "Define Directory:   " Directory
	if [[ "$Directory" == */ ]] && [[ "$Directory" != "/" ]]; then
		Directory=$(echo $Directory | sed 's/.$//')  # remove trailing "/"
	fi
}

D_DB_CI_Hint(){
	clear
	read -p "Define CIHint     Database (Server)       " CIHint
	Server=$(echo $CIHint | cut -d\( -f2 | cut -d\) -f1)
	Database=$(echo $CIHint | awk '{ print $1 }' | tr '[:upper:]' '[:lower:]')
}

D_NODE_NAME_Field(){
	clear
	NODE_NAME_Field="0"
	while [[ "$NODE_NAME_Field" -eq "0" ]];do
		clear
		echo -e "${Cust_Error}--------------------------------------------------------------------------------------------------${STD}"
		echo -e "${Cust_Error}      \"${Cust_Output}NODE_NAME${Cust_Error}\" or \"${Cust_Output}Node Hint${Cust_Error}\" field MUST be before the \"${Cust_Output}Title${Cust_Error}\" field in your OMi display       ${STD}"
		echo -e "${Cust_Error}      Also, Ensure \"${Cust_Output}Object${Cust_Error}\" field exists in your OMi display for best results                     ${STD}"
		echo -e "${Cust_Error}                                                                                                  ${STD}"
		echo -e "${Cust_Error}      Note:  This can be defined again in the \"${Cust_Menu}User Configurable Settings${Cust_Error}\" Menu                   ${STD}"
		echo -e "${Cust_Error}--------------------------------------------------------------------------------------------------${STD}"
		read -p "Define field number for \"NODE_NAME\" or \"Node Hint\"   (Counting from the left)      " NODE_NAME_Field
		if ! [[ $NODE_NAME_Field == +([0-9]) ]]; then
			echo -e "${Cust_Error}Please enter a Whole Number${STD}" && sleep 3
			NODE_NAME_Field="0"
		fi
			sed -i "s/NODE_NAME_Field = .*/NODE_NAME_Field = $(echo $NODE_NAME_Field)/" $Config_File
	done
}

C_Database(){
	if [ -z "$Database" ]; then
		echo "Please set Database"
		Var_Check=Failed
	else
		Database=$(echo "$Database" | tr '[:upper:]' '[:lower:]')
	fi
}

C_Server(){
	if [ -z "$Server" ]; then
		echo "Please set Server Name"
		Var_Check=Failed
	else
		rm -f $M_Server_Up_File $M_Server_Down_File 2> /dev/null
		Server=$(echo "$Server" | awk '{ print $1 }' | tr '[:upper:]' '[:lower:]')
		ping -c1 -W1 $Server > /dev/null && Echo_Reply=Yes || Echo_Reply=No
		if [ "$Echo_Reply" == "No" ]; then
			echo -e "${Cust_Error}Server [$Server] did NOT respond to ping test ${STD}" && sleep 3
			unset Server OS_Test
			continue
		else
			echo $Server | tee $M_Server_File $M_Server_Up_File >> /dev/null
			M_Server=();M_Server_Removed=();Down_Server=()
			M_Server_Size=-1;Down_Server_Size=-1;readarray -t M_Server < $M_Server_File;M_Server_Size=$((${#M_Server[@]}-1))
		fi
	fi
}

C_Directory(){
	if [ -z "$Directory" ]; then
		echo "Please set Directory"
		Var_Check=Failed
	fi
}

C_Vars(){
	if [ ! -z "$Var_Check" ]; then
		unset Var_Check
		echo -e "${Cust_Error}Please Define Above Variables${STD}"
		sleep 2;continue
	fi
}

RM_Files(){ # Clean up the main files that are used to print output to the screen... This gets called everytime a non-main menu is displayed.
	unset Var_Check
	rm -f $Temp_File 2> /dev/null
	rm -f $Temp_Output_File 2> /dev/null
	rm -f $Output_File 2> /dev/null
}

Initialize_Vars(){
	unset Directory Filesystem_Type FS_Size_Inc RMAN_File Custom_Command LV_Free_PPs LV_Free_PPs_MB PP_Size FS_Size_Inc Logical_Volume Volume_Group
	if [ "$Database" == "Multi_Server" ];then unset Database; fi
	Current_LV_LP_Size=0
	Max_LV_LPs=0
	New_LV_LP_Size=0
}

################################################################
################ Pattern Matching Functions ####################
################################################################

D_Single_Alarm(){
	clear
	if [ "$NODE_NAME_Field" -eq "0" ];then
		echo -e "${Cust_Error}You have not set the field number for \"NODE_NAME\" or \"Node Hint\" in your OMi Browser${STD}\n\n"
		D_NODE_NAME_Field
	fi
	clear
	unset Server Database Directory OS_Test   # This is important... So Variable checking can reoccur.
	echo -e "Define  A Single  OMi Alarm  ---  Looking for \"NODE_NAME\" or \"Node Hint\" in field number $NODE_NAME_Field"
	echo -e "${Cust_Error}--------------------------------------------------------------------------------------------${STD}"
	echo -e "${Cust_Error}Note: Set \"NODE_NAME\" or \"Node Hint\" field number in \"User Configurable Settings\" Menu      "${STD}
	echo -e "${Cust_Error}      \"NODE_NAME\" or \"Node Hint\" field MUST be before the \"Title\" field in your OMi display ${STD}"
	echo -e "${Cust_Error}      Also, Add \"Object\" field to your OMi display for best results                         ${STD}"
	echo -e "${Cust_Error}--------------------------------------------------------------------------------------------${STD}"
	echo -e "${Cust_Output}Reading input indefinately... ${STD}${Cust_Error}Press Ctrl-D${STD}${Cust_Output} to terminate input after pasting an alarm${STD}\n\n\n${Cust_Menu}--------------------------------------------------------------------------------------------${STD}"
	input=$(cat)
	clear
	Server=$(echo "$input" | grep "	"| cut -f${NODE_NAME_Field} | tr '[:upper:]' '[:lower:]' | cut -d\| -f1 | cut -d\, -f1 | head -n 1) # grep-ing for TAB char
	#Server=$(echo "$input" | grep "	"| sed -n 1p | awk '{ print $1 }' | tr '[:upper:]' '[:lower:]') # grep-ing for TAB char
	C_Server;C_Vars;C_OS_Test;C_Single_Alarm_Set_Vars
}

C_Single_Alarm_Set_Vars(){
	# Database --- Patterns to try and set Database
	echo "$input" | grep -oP '(?<=Database ).*(?=: Tablespace )' | head -n 1 > $Temp_File
	echo "$input" | grep -oP '(?<=Database ).*(?=: Standby In Use. Tablespace)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=Database ).*(?=: Connection check)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=Database ).*(?=: Previous connection check)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=Database ).*(?=: Tnsping of)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=Database ).*(?= is not running)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=alert_).*(?=\.log)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=tandby database ).*(?= is behind in posting)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=RMAN Errors ).*(?= Archive Log)' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP "(?<=$(echo $Server | cut -d. -f1) ).*(?= Hot Backup Errors)"| head -n 1 >> $Temp_File
	echo "$input" | grep -oP "(?<=$(echo $Server | cut -d. -f1) ).*(?= DATAPUMP Export Errors)"| head -n 1 >> $Temp_File
	#  Need Syntax for Full Export
	Matches=$(cat $Temp_File | tr '[:upper:]' '[:lower:]' | sort | uniq | grep -c -v '^$')
	if [ "$Matches" -eq "1" ];then
		Database=$(cat $Temp_File | tr '[:upper:]' '[:lower:]' | sort | uniq | grep -v '^$')
	fi

	# If a Database was found, try to obtain the dbfiles / sapdata directory with the most available space
	if [[ ! -z "$Database" ]] && [[ "${Menus[$LMI]}" == "Print_Filesystem_Menu" ]] && [[ -z "$Directory" ]];then G_Tablespace_Info;fi
	# Directory --- Patterns to try and set Directory
	echo "$input" | grep -oP '(?<= utilization on ).*(?= file system )' | head -n 1 > $Temp_File
	echo "$input" | grep -oP '(?<=space utilization for Logical Disk ).*(?=of type)' | sed 's/^[ \t]*//;s/[ \t]*$//' | head -n 1 >> $Temp_File
	echo "$input" | grep -oP '(?<=Lived).*(?=st full)' | sed 's/ump filesystem almo/\/var/g' | head -n 1 >> $Temp_File
	Matches=$(grep -c -v '^$' $Temp_File)
	if [ "$Matches" -eq "1" ];then
		Directory=$(cat $Temp_File | grep -v ^$)
	fi
}

################################################################
################ Define Database Functions #####################
################################################################

G_Hot_Standby(){
	# Checks to see if the current server is in a Primary / Standby relationship... Useful for DBA / Filesystem work
	# This functions runs when the  Database_Menu  or  Filesystem_Menu  is displayed
	if [ "$OS_Test" != "Windows" ]; then
		echo "cat /home/root/hotstandby.txt" > $Command_File
		Hot_Standby=$(echo -e "$($SSH $Server cat /home/root/hotstandby.txt | grep -i -e warning -e identical -e fail)\nSNOC_${Server}")
		Primary_Standby_Line=$(echo "$Hot_Standby" | grep -i "Filesystems must be identical size on" | sed -n 's/^.*size\ on\ //p' )
		if [[ "$Primary_Standby_Line" == *"and"* ]]; then
			Primary_Server=$(echo "$Primary_Standby_Line" | awk '{ print $1 }')
			Standby_Server=$(echo "$Primary_Standby_Line" | awk '{ print $3 }')
		fi
	fi
}

G_DB_Logfile_Sync(){
	if [[ "$Primary_Standby_Line" == *"and"* ]]; then
		unset Alert_Log_File Primary_Log Standby_Log
		Original_Server=$(echo "$Server")
		Server=$(echo $Primary_Server)
		echo Checking Log on $Server
		choice="lower"
		G_DB_Alert_Log
		if [ ! -z "$Alert_Log_File" ]; then
			echo "cat $Alert_Log_File" > $Command_File
			Primary_Log=$(cat $Temp_Output_File)
		fi
		Server=$(echo $Standby_Server)
		echo Checking Log on $Server
		G_DB_Alert_Log
		if [ ! -z "$Alert_Log_File" ]; then
			echo "cat $Alert_Log_File" > $Command_File
			Standby_Log=$(cat $Temp_Output_File)
		fi
		rm -f $Output_File
		if [ ! -z "$Primary_Log" ] && [ ! -z "$Standby_Log" ]; then
			echo "$Primary_Log" | grep -i -e "Current log#" -e "Media Recovery Waiting" | tail -n 1 | awk '{ print $5 }' > $Temp_Output_File
			echo "$Primary_Log" | grep -i -e "Current log#" -e "Media Recovery Waiting" | tail -n 1 | awk '{ print $8 }' >> $Temp_Output_File
			Primary_Log_Number=$(grep -E '^[0-9]+$' $Temp_Output_File)
			echo "$Standby_Log" | grep -i -e "Current log#" -e "Media Recovery Waiting" | tail -n 1 | awk '{ print $5 }' > $Temp_Output_File
			echo "$Standby_Log" | grep -i -e "Current log#" -e "Media Recovery Waiting" | tail -n 1 | awk '{ print $8 }' >> $Temp_Output_File
			Standby_Log_Number=$(grep -E '^[0-9]+$' $Temp_Output_File)
			if [ ! -z "$Primary_Log_Number" ] || [ ! -z "$Standby_Log_Number" ]; then
				Difference=$(expr $Primary_Log_Number - $Standby_Log_Number)
				if [ "$Difference" -lt "0" ]; then Difference=$($Difference * -1); fi
				echo -e "${Cust_Output}$Primary_Server Primary Log # = $Primary_Log_Number${STD}" >> $Output_File
				echo -e "${Cust_Output}$Standby_Server Standby Log # = $Standby_Log_Number${STD}\n${STD}" >> $Output_File
				if [ "$Difference" -le "1" ]; then echo -e "${Cust_Output}Log files are fully synchronized${STD}" >> $Output_File; else echo -e "${Cust_Error}Log files differ by $Difference entries${STD}" >> $Output_File; fi
			else
				echo -e "${Cust_Error}Unable to find log numbers for both Primary / Standby servers${STD}\n${STD}" >> $Output_File
				echo -e "${Cust_Error}Primary_Log_Number = ${Cust_Output}$Primary_Log_Number${STD}\n${Cust_Error}Standby_Log_Number = ${Cust_Output}$Standby_Log_Number${STD}" >> $Output_File
			fi
		else
			if [ -z "$Primary_Log" ]; then echo -e "${Cust_Error}Primary Server: ${Cust_Output}$Primary_Server${Cust_Error} -- No alert_$Database\.log found${STD}" >> $Output_File; fi
			if [ -z "$Standby_Log" ]; then echo -e "${Cust_Error}Standby Server: ${Cust_Output}$Standby_Server${Cust_Error} -- No alert_$Database\.log found${STD}" >> $Output_File; fi
		fi
	else
		echo -e "${Cust_Error}$Server is not configured in a Primary / Standby fashion${STD}" >> $Output_File
	fi
	Server=$(echo "$Original_Server")
	unset Alert_Log_File Primary_Log Standby_Log Original_Server Primary_Log_Number Standby_Log_Number
}

G_Oratab(){
	Oratab=$($SSH $Server cat /etc/oratab)
#	echo -e "\n\nORATAB\n$Oratab\n\n"
	if [ ! -z "$Database" ];then
		ORACLE_SID=$(echo "$Oratab" | egrep -v '#' | cut -f1 -d ':' | grep -i $Database)
	fi
	if [ ! -z "$ORACLE_SID" ];then
		Database=$ORACLE_SID
		ORACLE_HOME=$(echo "$Oratab" | grep ${ORACLE_SID}: | cut -f2 -d ':')	# Need this to be for a local database
		ORACLE_BASE=$ORACLE_HOME						# Need this to be for a local database
		ORACLE_ADMIN=$ORACLE_BASE/admin/$ORACLE_SID				# Need this to be for a local database

	fi
	if [ ! -z "$ORACLE_HOME" ];then
		Tnsnames=$($SSH $Server cat /etc/tnsnames.ora | sed 's/^ *//')
#		Tnsnames=$($SSH $Server cat $ORACLE_HOME/network/admin/tnsnames.ora | sed 's/^ *//')
#		echo "$Tnsnames"
#		paused
		DB_TNS=$(echo "$Tnsnames" | sed -n "/^${ORACLE_SID}.WORLD =/I,/^[a-zA-Z0-9_\-]/p" | sed 's/(/\n/g' | sed 's/)/\n/g' | grep -v ^$)
		echo -e "$DB_TNS\n\n" | tee -a $Temp_Output_File
#		paused
		DB_Port=$(echo "$DB_TNS" | grep -i ^port | awk '{ print $3 }' | head -n 1)
		echo -e "ORACLE_SID=$ORACLE_SID\nORACLE_HOME=$ORACLE_HOME\nORACLE_BASE=$ORACLE_BASE\nORACLE_ADMIN=$ORACLE_ADMIN\nDB_PW=$DB_PW\nServer=$Server\nDB_Port=$DB_Port" | tee -a $Temp_Output_File
#		paused
		cat ${Subscript_Dir}/dba_template > $Temp_File	# Uses a Heredoc to allow remote commands    Looking for 'EOF' to terminate Heredoc
		Args=7
		sed -i "s/Args=.*/Args=$Args/" $Temp_File	# Dynamically set number of expected args when calling remote script... Will exit if not matched
		if [ ! -z "$Add_Arg1" ];then
			sed -i "s/####1=.*/Add_Arg1=\$8/" $Temp_File
		fi
		if [ ! -z "$Add_Arg2" ];then
			sed -i "s/####1=.*/Add_Arg2=\$9/" $Temp_File
		fi
		cat ${Subscript_Dir}/dba_tablespace_query >> $Temp_File
		echo "exit" >> $Temp_File
		echo "EOF" >> $Temp_File
#		cat $Temp_File >> $Temp_Output_File
		scp $Temp_File root@$Server:/home/root/SNOC_Test_Script_C54917 >> /dev/null 2> /dev/null
		$SSH $Server chmod +x /home/root/SNOC_Test_Script_C54917
		$SSH $Server /home/root/SNOC_Test_Script_C54917 $ORACLE_SID $ORACLE_HOME $ORACLE_BASE $ORACLE_ADMIN $DB_PW $Server $DB_Port | tee -a $Temp_Output_File
		$SSH $Server rm -f /home/root/SNOC_Test_Script_C54917
		Color_and_RM_Temp_Output 2> /dev/null
		View_Output
	fi
	unset Add_Arg1 Add_Arg2
#	unset Args	#	Need to eventually implement this into menu
}

G_Tablespace_Info(){
	# Finds DBA password info in the /etc/pwfile file  and  also prints free space for associated dbfile / sapdata filesystems
	# If there are no matches for the specified database, the Password / Filesystem information for all databases will be printed
	df_Out=$(echo "$($SSH $Server df -m -P)" | grep -i -e dbfile -e sapdata)
	df_Out=$(echo "$(echo -e "Filesystem MB_blocks Used Available_MB Capacity Mounted_on";echo "$df_Out")" | awk '{printf "%-40s %-12s %-12s %-12s %-12s %s\n",$1,$2,$3,$4,$5,$6}')
	if [ ! -z "$Database" ];then
		df_Database=$(echo -e "$df_Out" | grep -i -e $Database/.*dbfile -e $Database/.*sapdata -e Filesystem | sort -nk4)
	else
		unset df_Database
	fi	
	pwfile_Out=$($SSH $Server cat /etc/pwfile | grep -i system)
	DB_PW_Test=$(echo "$pwfile_Out" | grep -i $Database 2> /dev/null)
	if [ "$Database" != "Multi_Server" ]; then
		echo -e "${STD}Server:    ${Cust_Output}$Server${STD}" > $Temp_Output_File
		echo -e "${STD}Database:  ${Cust_Output}$Database${STD}" >> $Temp_Output_File
	fi
	if [ -z "$DB_PW_Test" ]; then
		if [ "$Database" != "Multi_Server" ]; then echo -e "${Cust_Error}Exact Database name \"$Database\" not found in \"/etc/pwfile\"  Listing all database info in the file${STD}" >> $Temp_Output_File
		fi
		echo -e "$(echo "$pwfile_Out" | sed 's/_.*\// /g' | awk '{printf "%-20s %s\n",$2,$3}')" >> $Temp_Output_File 
		DB_PW="No matching PW found"
	else
		DB_PW=$(echo "$pwfile_Out" | grep -i ${Database}_PW | cut -d\/ -f2)
		echo -e "${STD}Password:  ${Cust_Output}$DB_PW${STD}" >> $Temp_Output_File
	fi
	echo >> $Temp_Output_File
	if [[ "$df_Database" == *"oracle"* ]]; then
		DB_FS=$(echo -e "$df_Database" | awk {'printf "%-20s %s\n",$4,$6}')
		echo -e "$DB_FS" >> $Temp_Output_File
	else
		if [ "$Database" != "Multi_Server" ]; then
			echo -e "${Cust_Error}No Oracle Data File directory found containing \"${Database}\" Here are all Data Files for All Databases${STD}" >> $Temp_Output_File
		fi
		echo "$df_Out" >> $Temp_Output_File
		DB_FS=$(echo "No matching dbfiles or sapdata filesystems found for ${Database}")
	fi
	echo >> $Temp_Output_File
	echo "alter database backup controlfile to trace;" >> $Temp_Output_File
	echo >> $Temp_Output_File
	if [[ "$Main_Function" == "Obtain" ]] || [[ ! -z "$Database" ]] && [[ "${Menus[$LMI]}" == "Print_Filesystem_Menu" ]] && [[ -z "$Directory" ]];then # Auto Set Largest Directory when defining a DBA alarm in Filesystem Menu... Avoiding Replacing "/" when wanting "/"
		rm -f $Temp_Output_File 2> /dev/null
		if [[ "$df_Database" == *"oracle"* ]]; then
			# Set largest directory... Based on Available Space
			Directory=$(echo -e "${df_Database}" | grep -i -e $Database/*dbfile -e $Database/*sapdata  | sort -nk4 | tail -n 1 | awk '{ print $6 }')
		else
			Directory="/" # Make sure Directory is not empty.
			G_Mount
		fi
	else
		Color_and_RM_Temp_Output 2> /dev/null
	fi
	unset df_Out pwfile_Out DB_PW_Test df_Database
}

G_DB_Alert_Log(){
	# obtains the databases alert.log file... Note: $choice variable determines "cat" or "tail -f" of alert_$Database.log
	Alert_Log_File=$(echo "$($SSH $Server find /oracle -name alert_$Database.log)" | sort -r | head -n 1)
	echo "$Alert_Log_File"
	if [ ! -z "$Alert_Log_File" ]; then
		if [[ "$choice" =~ [[:upper:]] ]]; then
			$SSH $Server tail -f -n 1000 $Alert_Log_File | tee -a $Temp_Output_File
		else
			$SSH $Server cat $Alert_Log_File >> $Temp_Output_File
		fi
	else
		echo -e "${Cust_Error}$Server --- No alert_$Database.log file found...${STD}" >> $Temp_Output_File
	fi
}

C_RMAN_File(){
	if [ -z "$RMAN_File" ]; then
		echo "Please set RMAN File"
		Var_Check=Failed
	fi
}

G_RMAN_Listing(){
	# Prints out all files in the /tmp/rmanlogs directory
	# if a database was specified, grep will filter the results
	$SSH $Server ls -latr /tmp/rmanlogs >> $Temp_File
	echo -e "${Cust_Error}Copy the full filename... So you can \"Define: RMAN Log\" and then \"Get: RMAN Log Output\"${STD}" >> $Temp_Output_File
	if [ ! -z "$Database" ]; then
		echo -e "${Cust_Output}ls -lat /tmp/rmanlogs | grep -i $Database${STD}"
		cat $Temp_File | grep -i $Database >> $Temp_Output_File
	else
		echo -e "${Cust_Output}ls -lat /tmp/rmanlogs${STD}"
		cat $Temp_File >> $Temp_Output_File
	fi
	echo -e "${Cust_Error}Copy the full filename... So you can \"Define: RMAN Log\" and then \"Get: RMAN Log Output\"${STD}" >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

G_RMAN_Output(){
	# obtain the chosen RMAN log file
	echo -e "${Cust_Output}cat /tmp/rmanlogs/$RMAN_File | less +G${STD}"
	$SSH $Server cat /tmp/rmanlogs/$RMAN_File >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

G_Export_Error(){
	# This function greps for errors in the most recent export error file (depending on type specified)
	# If the errors in the file contains "dsmc incremental" an additional prompt will appear asking to perform the incremenal backup
	if [ ! -z "$Export_Log" ]; then
		clear
		echo find /oracle -name \""*$Export_Log"\"
		Export_Error_file=$($SSH $Server find /oracle -name "*$Export_Log" 2>/dev/null | grep -i $Database | sort -r | head -n 1);clear
		if [[ "$Export_Error_file" == *".log"* ]]; then
			Export_Error_Out=$($SSH $Server cat $Export_Error_file | grep -i error)
			echo -e "grep -i error $Export_Error_file \n\n $(echo "$Export_Error_Out")" >> $Temp_Output_File
		else
			echo -e "${Cust_Error}No $Export_Log Found...${STD}" >> $Temp_Output_File
		fi
		Color_and_RM_Temp_Output 2> /dev/null
		if [[ "$Export_Error_Out" == *"dsmc incremental"* ]]; then
			View_Output
			Export_Error_Out=$(echo "$Export_Error_Out" | grep -i "dsmc incremental" | cut -f 2- -d\  | sed -e 's/^[ \t]*//' )
			echo -e "${Cust_Error}-------------------------------------------------------------------${STD}"
			echo -e "${Cust_Output}Do you want to run the backup on $Server\n$Export_Error_Out\n( Y / n )${STD}"
			echo -e "${Cust_Error}-------------------------------------------------------------------${STD}"
			read -n 1 -s -p "" choice
			case $choice in
				Y|y)
					echo "$Export_Error_Out" > $Command_File
					Log_and_Run_Commands | tee -a $Temp_Output_File
					Color_and_RM_Temp_Output 2> /dev/null
					;;
				*) clear
			esac
		fi
	fi
	View_Output
}


################################################################
################### Define TSM Functions #######################
################################################################

G_TSM_Log(){
	C_OS_Test
	if [ "$OS_Test" == "AIX" ]; then
		#AIX
		TSM_Log="/usr/tivoli/tsm/client/ba/bin/${TSM_Log}"
	else
		TSM_Log="/opt/tivoli/tsm/client/ba/bin/${TSM_Log}"
	fi
	TSM_Log_Test=$($SSH $Server ls $TSM_Log)
	if [ ! -z "$TSM_Log_Test" ]; then
		echo "cat $TSM_Log" > $Command_File
		$SSH $Server cat $TSM_Log >> $Temp_Output_File
		Color_and_RM_Temp_Output 2> /dev/null
	else
		echo -e "${Cust_Error}$Server --- No $TSM_Log found...${STD}" >> $Output_File
	fi
}

G_TSM_Processes(){
	echo "$($SSH $Server ps -ef)" |grep -e dsmc -e tsm |grep -v grep >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

G_TSM_Config(){
	C_OS_Test
	if [ "$OS_Test" == "AIX" ]; then
		# AIX
		TSM_Location=$($SSH $Server find /etc -name "*rc.tsm")
		if [ "$TSM_Location" == "/etc/rc.tsm" ]; then
			Out=$(echo "$($SSH $Server cat /etc/inittab)" | grep -i -e rc.start_scheduler.ksh -e /etc/rc.tsm)
			echo -e "Checking TSM Configuration... You should see some output...\ngrep -i -e rc.start_scheduler.ksh -e /etc/rc.tsm /etc/inittab\n\n$Out" >> $Temp_Output_File
		else
			echo -e "${Cust_Error}TSM not found in the standard directory \"/etc/rc.tsm\"    Please Ticket...${STD}" >> $Output_File
		fi
	else
		# Non-AIX    Probably Linux
		Out=$(echo "$($SSH $Server chkconfig)" | grep tsm)
		echo -e "Checking TSM Configuration... You should see some output...\nchkconfig |grep tsm\n\n$Out" >> $Temp_Output_File
	fi
	Color_and_RM_Temp_Output 2> /dev/null
}

Restart_TSM_Client_Acceptor(){
#	kill $(ps -ef |grep dsmc |grep -v grep | awk '{ print $2 }' |tr '\n' ' '); service tsm stop; service tsm start
	C_OS_Test
	Processes=$($SSH $Server ps -ef |grep dsmc |grep -v grep | awk '{ print $2 }' |tr '\n' ' ')
	if [ "$OS_Test" == "AIX" ]; then
		# AIX
		TSM_Location=$($SSH $Server find /etc -name "*rc.tsm")
		echo -e "${Cust_Output}Old TSM PIDs are $Processes${STD}" >> $Output_File
		if [ "$TSM_Location" == "/etc/rc.tsm" ]; then
			echo "kill $Processes" >> $Command_File
			echo "$TSM_Location" >> $Command_File
			Log_and_Run_Commands > /dev/null
		else
			echo -e "${Cust_Error}TSM not found in the standard directory \"/etc/rc.tsm\"    Please Ticket...${STD}" >> $Output_File
		fi
	else
		# Non-AIX    Probably Linux
		TSM_Location=$($SSH $Server find /etc/rc.d/init.d -name "tsm")
		if [ "$TSM_Location" == "/etc/rc.d/init.d/tsm" ]; then
			echo -e "${Cust_Output}Old TSM PIDs are $Processes${STD}" >> $Output_File
			echo "kill $Processes" >> $Command_File
			echo "service tsm stop" >> $Command_File
			echo "service tsm start" >> $Command_File
		else
			echo -e "${Cust_Error} TSM not found in the standard directory \"/etc/rc.d/init.d/tsm\"    Please Ticket...${STD}" >> $Output_File
		fi
		Log_and_Run_Commands > /dev/null
	fi
	Processes=$($SSH $Server ps -ef |grep dsmc |grep -v grep | awk '{ print $2 }' |tr '\n' ' ')
	echo -e "${Cust_Output}New TSM PIDs are $Processes${STD}" >> $Output_File
	#paused
}

################################################################
################# Define Server Functions ######################
################################################################

Check_OM_Perfstat(){
	C_OS_Test
	if [ "$OS_Test" == "AIX" ]; then
		# AIX
		Perfstat=$($SSH $Server find /usr/lpp/perf/bin -name "perfstat" 2> /dev/null | head -n 1)
	else
		# Linux
		Perfstat=$($SSH $Server find /opt/perf/bin -name "perfstat" 2> /dev/null | head -n 1)
	fi
	if [ -z "$Perfstat" ]; then
		echo -e "${Cust_Output}$Server --- perfstat could not be found${STD}" >> $Output_File
	fi
}

G_OM_Agent_Status_UNIX(){
	C_OS_Test
	if [ "$OS_Test" != "Windows" ]; then
		Check_OM_Perfstat
		if [ ! -z "$Perfstat" ]; then
			$SSH $Server $Perfstat >> $Temp_Output_File
			Color_and_RM_Temp_Output 2> /dev/null
		fi
	else
		echo -e "$Server\n${Cust_Error}Windows is not supported..." >> $Temp_Output_File
		Color_and_RM_Temp_Output 2> /dev/null
	fi
}

G_OM_Agent_Status(){
	Agent_Status=$($SSH hpom /opt/OV/bin/ovrc -host $Server -status 2> $Temp_Error_File | grep -v ^$)
	if [ ! -z "$Agent_Status" ]; then
		echo "$Agent_Status" >> $Temp_Output_File
		Color_and_RM_Temp_Output 2> /dev/null
	else
		Color_and_RM_Temp_Error 2> /dev/null
	fi
}

Test_OM_Agent(){
	$SSH hpom /home/C54917a/OM_msg_test.sh $Server
}

OM_Agent_Restart_UNIX(){
	C_OS_Test
	if [ "$OS_Test" != "Windows" ]; then
		Check_OM_Perfstat
		Processes=$($SSH $Server ps -ef | grep -i -e /usr/lpp/perf/bin -e /opt/perf/bin | awk '{ print $2 }' |tr '\n' ' ')
		if [ ! -z "$Perfstat" ]; then
			if [ "$OS_Test" == "AIX" ]; then
				# AIX
				echo "/usr/lpp/OV/bin/ovc -kill" > $Command_File
				echo "/usr/lpp/perf/bin/ovpa stop" >> $Command_File
				echo "kill $Processes" >> $Command_File
				echo "/usr/lpp/perf/bin/ovpa start" >> $Command_File
				echo "/usr/lpp/OV/bin/opcagt -cleanstart" >> $Command_File
			else
				# Linux
				echo "/opt/OV/bin/ovc -kill" > $Command_File
				echo "/opt/perf/bin/ovpa stop" >> $Command_File
				echo "kill $Processes" >> $Command_File
				echo "/opt/perf/bin/ovpa start" >> $Command_File
				echo "/opt/OV/bin/opcagt -cleanstart" >> $Command_File
			fi
		fi
		echo -e "${Cust_Error} Press   Control C   ONE TIME to continue once \"The Perf Agent alarm generator\" has been started...\n${STD}"
		Log_and_Run_Commands
		sleep 5
		G_OM_Agent_Status_UNIX
	else
		echo -e "${Cust_Error}Windows is not supported..." >> $Temp_Output_File
		echo -e "${Cust_Error}Try pasting this entire command in an Administrative Powershell window\n${Cust_Menu}Invoke-Command -ComputerName $Server -ScriptBlock { ovpacmd stop ; opcagt -kill ; Get-Process | Where-Object -FilterScript {\$_.Path -Like \"C:\\Program Files\\HP\\HP BTO Software*\"} | Stop-Process ; ovpacmd start ; opcagt -cleanstart ; opcagt -status }\n${Cust_Error}Or try SNOC Windows Jumphost Scripts${STD}  ----  ${Cust_Output}https://snoc:8443/display/TRAINREF/SNOC+Windows+Jumphost+Scripts" >> $Temp_Output_File
		Color_and_RM_Temp_Output 2> /dev/null
	fi
}

OM_Agent_Restart(){
	$SSH hpom /opt/OV/bin/ovrc -host $Server -restart 2> /dev/null
	G_OM_Agent_Status
}

G_MPIO(){
	if [[ "$Server" != "w"* ]]; then
		if [[ "$Server" == "l"* ]]; then
			$SSH $Server multipath -ll >> $Temp_Output_File 2> $Temp_Error_File
		else
			$SSH $Server /scripts/bin/mpio_summary.ksh >> $Temp_Output_File 2> $Temp_Error_File
		fi
	else
		echo -e "$Server\n${Cust_Error}Windows is not supported..." >> $Temp_Output_File
	fi
	Color_and_RM_Temp_Output 2> /dev/null
	Color_and_RM_Temp_Error 2> /dev/null
}

G_eService(){
	$SSH hpom /opt/OV/bin/ovbbccb -ping $Server >> $Temp_Output_File 2> $Temp_Error_File
	Color_and_RM_Temp_Output 2> /dev/null
	Color_and_RM_Temp_Error 2> /dev/null
}

NNMI_Ping(){
	$SSH lhpnnmigm1p.fenetwork.com ping -c2 -W1 $Server >> $Temp_Output_File 2> $Temp_Error_File
	Color_and_RM_Temp_Output 2> /dev/null
	Color_and_RM_Temp_Error 2> /dev/null
}

################################################################
############### Define Filesystem Functions ####################
################################################################

D_FS_Increase(){
	clear
	if [[ "$Filesystem_Type" != "vxfs" ]] && [[ "$Filesystem_Type" != "jfs"* ]]; then
	#if [[ "$Filesystem_Type" == *"ext"* ]] || [[ "$Filesystem_Type" == *"nfs"* ]]; then
		echo -e "${Cust_Error}Resizing Filesystem Type $Filesystem_Type is NOT Supported${STD}"
		pause
	else
		C_LV;C_Vars
		echo -e "Filesystem Increases    (Relative to current Filesystem size)"
		rm -f $Temp_File
		for d in {0.01,.02,.03,.04,.05,.07,.10,.12,.15,.17,.20};do
			Percent=$(echo $d | cut -d. -f2)
			Size=$( echo "$FS_Size * $d" | bc | cut -d. -f1)
			echo -e -n "+$Percent% = |$Size| MB   --- Rounding up to nearest block |${Cust_Output}$(( $(( ( $Size + $PP_Size - 1 ) / $PP_Size )) * $PP_Size ))${STD}| MB" >> $Temp_File
			if [[ "$Size" -gt "$VG_Free_PPs_MB" ]];then
				echo -e " ---   ${Cust_Error}Not enough freespace${STD}" >> $Temp_File
			else
				echo >> $Temp_File
			fi
		done
		cat $Temp_File | column -t -s"|" -o ' '
		echo -e "\n\nMax Resize  ---  Available MB:   ${Cust_Menu}$VG_Free_PPs_MB${STD}"
		read -p "Define MB to increase Filesystem by:   " FS_Size_Inc
		if ! [[ $FS_Size_Inc == +([0-9]) ]]; then
			echo -e "${Cust_Error}Please enter a Whole Number${STD}" && sleep 3
			unset FS_Size_Inc
		fi
		if [ "$FS_Size_Inc" -gt "$VG_Free_PPs_MB" ]; then
			echo -e "${Cust_Error}Outside of Available Range...  ( 0 - $VG_Free_PPs_MB )${STD}" && sleep 3
			unset FS_Size_Inc
		else
			FS_Size_Inc=$(( $(( ( $FS_Size_Inc + $PP_Size - 1 ) / $PP_Size )) * $PP_Size ))
			New_LV_LP_Size_MB=$(expr $Max_LV_LPs_MB + $FS_Size_Inc)
			New_LV_LP_Size=$(( ( $New_LV_LP_Size_MB + $PP_Size - 1 ) / $PP_Size ))
		fi
	fi
}

C_FS_Size_Increment(){
	if [ -z "$FS_Size_Inc" ]; then
		echo "Please set New Logical Volume Size"
		Var_Check=Failed
	fi
}

C_LV(){
	if [ -z "$VG_Free_PPs_MB" ]; then
		Var_Check=Failed
	fi
	if [ -z "$Volume_Group" ]; then
		echo "Could not obtain Volume Group"
		Var_Check=Failed
	fi
	if [ ! -z "$Var_Check" ]; then
		unset Var_Check
		echo -e "\n\nGetting LVM ( Logical Volume Management ) info now"
		C_Server;C_Directory;C_Vars;Main_Function="Obtain";G_LV;continue
	fi
	clear
}

G_DF_FS(){
	df_Out=$(echo "$(echo -e "Filesystem MB_blocks Used Available Capacity Mounted_on";echo "$($SSH $Server df -m -P $Directory | grep -v ^Filesystem)")" | awk '{printf "%-40s %12s %12s %12s %12s %s\n",$1,$2,$3,$4,$5,$6}')
	if [ ! -z "$Directory" ]; then
		Filesystem=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $1 }')
		FS_Avail_Space=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $4 }' | cut -d. -f1)
		FS_Percent=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $5 }' | cut -d% -f1)
		FS_Size=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $2 }')
	fi
	if [[ "$Filesystem_Type" == "vxfs" ]] || [[ "$Filesystem_Type" == *"nfs"* ]]; then
		Logical_Volume=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $1 }' | rev | cut -d/ -f1 | rev)
		Volume_Group=$(echo "$df_Out" | grep -v ^Filesystem 2> /dev/null | awk '{ print $1 }' | rev | cut -d/ -f2 | rev)
	fi
	echo "$df_Out" >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

G_DU_FS(){
	$SSH $Server du -mx $Directory | sort -rn >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

G_LS_FS(){
	$SSH $Server ls -la $Directory >> $Temp_Output_File
	Color_and_RM_Temp_Output 2> /dev/null
}

Resize_FS(){
	C_OS_Test
	if [[ "$Filesystem_Type" == "vxfs" ]]; then
		if [ "$OS_Test" == "AIX" ]; then
			G_DF_FS
			vxresize=$($SSH $Server find /opt -name "vxresize")
			echo "$vxresize -g $Volume_Group $Logical_Volume +$(echo $FS_Size_Inc)m" > $Command_File
			Log_and_Run_Commands >> $Temp_Output_File 2> $Temp_Error_File
			Color_and_RM_Temp_Output 2> /dev/null
			Color_and_RM_Temp_Error 2> /dev/null
		fi
	elif [[ "$Filesystem_Type" == *"nfs"* ]]; then
		echo -e "${Cust_Error}Filesystem is a NFS filesystem... Do not extend!!${STD}" | tee -a $Output_File
	else
		if [ "$OS_Test" == "AIX" ]; then
			# AIX
			Resize_LV
			rm -f $Temp_Output_File 2> /dev/null; rm -f $Output_File 2> /dev/null
			G_DF_FS
			echo -e "Increasing the Filesystem ${Cust_Menu}$Directory${STD} by ${Cust_Menu}$FS_Size_Inc${STD} MB"
			echo "chfs -a size=+$(echo $FS_Size_Inc)M $Directory" > $Command_File
		else
			# Linux
			G_DF_FS
			echo -e "${STD}" >> $Output_File
			echo -e "Increasing the Filesystem ${Cust_Menu}$Filesystem${STD} by ${Cust_Menu}$FS_Size_Inc${STD} MB"
			echo "lvextend -L +$(echo $FS_Size_Inc)M $Filesystem -r" > $Command_File
		fi
		Log_and_Run_Commands >> $Temp_Output_File 2> $Temp_Error_File
		Color_and_RM_Temp_Output 2> /dev/null
		Color_and_RM_Temp_Error 2> /dev/null
		echo -e "${STD}" >> $Output_File
	fi
}

Update_FS_Info(){
	C_Server;C_Directory;C_Vars;C_OS_Test;FS_Action="Obtain";Main_Function="Obtain";G_Mount;G_Tablespace_Info;G_DF_FS
}

G_Mount(){
	$SSH $Server mount > $Temp_Output_File
#	cat $Temp_Output_File | grep -i ${Directory}
	if [[ "$Main_Function" == "Obtain" ]] && [[ "$FS_Action" == "Obtain" ]];then
		if [[ "$Directory" != "/"* ]]; then  # Filesystem is NOT specified... Relative Matching
			clear
			echo -e "${Cust_Error}-------------------------------------------------------------------${STD}" > $Output_File
			echo -e "${Cust_Menu}Please define a full filesystem path  (starting with a \"/\")${STD}" >> $Output_File
			echo -e "${Cust_Error}-------------------------------------------------------------------${STD}" >> $Output_File
				echo -e "${Cust_Output}Printing filesystems in \"mount | grep -i $Directory\" command output${STD}\n${STD}" >> $Output_File
			if [ "$OS_Test" == "AIX" ]; then
				echo "$(cat $Temp_Output_File | grep -i $Directory | awk '{ print $2 }')" > $Temp_Output_File
			else
				echo "$(cat $Temp_Output_File | grep -i $Directory | awk '{ print $3 }')" > $Temp_Output_File
			fi
			Color_and_RM_Temp_Output
			echo -e "${STD}\n${Cust_Error}-------------------------------------------------------------------${STD}" >> $Output_File
			echo -e "${Cust_Menu}Copy the appropriate filesystem... Then define the filesystem in the menu${STD}" >> $Output_File
			echo -e "${Cust_Error}-------------------------------------------------------------------${STD}" >> $Output_File
			unset Filesystem Filesystem_Type Directory
			View_Output
		else  # Filesystem Specified
			if [ "$OS_Test" == "AIX" ]; then
				Directory=$(cat $Temp_Output_File | grep -i " ${Directory} " | awk '{ print $2 }' | head -n 1)
				Filesystem=$(cat $Temp_Output_File | grep -i " ${Directory} " | awk '{ print $1 }' | head -n 1)
				Filesystem_Type=$(cat $Temp_Output_File | grep " ${Directory} " | awk '{ print $3 }' | head -n 1)
			else
				Directory=$(cat $Temp_Output_File | grep -i " ${Directory} " | awk '{ print $3 }' | head -n 1)
				Filesystem=$(cat $Temp_Output_File | grep -i " ${Directory} " | awk '{ print $6 }' | head -n 1)
				Filesystem_Type=$(cat $Temp_Output_File | grep " ${Directory} " | awk '{ print $5 }' | head -n 1)
			fi
			if [ "$Filesystem_Type" == "vxfs" ]; then
				LVM_LV="Volume Set"
				LVM_VG="Disk Group"
			else
				LVM_LV="Logical Volume"
				LVM_VG="Volume Group"
			fi
			G_LV
		fi
	else
		if [[ ! -z "$Directory" ]];then
			echo "$(cat $Temp_Output_File | grep -i ${Directory} | head -n 1)" > $Temp_Output_File
		fi
		Color_and_RM_Temp_Output
	fi
}

G_LV(){
	if [ "$FS_Action" == "Both" ]; then echo "Resizing Filesystem and Logical Volume..."; fi
	if [ "$FS_Action" == "LV" ]; then echo "Increasing the Max Logical Volume Size..."; fi
	if [ "$Main_Function" == "Obtain" ]; then echo "Getting Latest: Filesystem, Logical Volume, and Volume Group info..."; fi
	Output_File_Last_Line
	C_OS_Test
	if [ "$FS_Action" == "Obtain" ] || [ "$FS_Action" == "Both" ] && [ "$Main_Function" == "Obtain" ]; then
		G_DF_FS
		echo -e "${STD}" >> $Output_File
		Output_File_Last_Line
		sed -i -f $Sed_File $Output_File
	fi
	sed -i -f $Sed_File $Output_File
	if [ "$OS_Test" == "AIX" ]; then
		# AIX
		if [ "$Filesystem_Type" == "vxfs" ]; then
			PP_Size="1"
			VG_Free_PPs_MB=$(echo "$($SSH $Server /scripts/vxvm/VxFreeSpace.sh -g $Volume_Group)" | awk '{ print $4 }' | cut -d. -f1)
		else
			Logical_Volume=$(echo $Filesystem | rev | cut -d/ -f1 | rev)
			if [ ! -z "$Logical_Volume" ]; then
				echo "lslv $Logical_Volume" >> $Temp_Output_File
				$SSH $Server lslv $Logical_Volume >> $Temp_Output_File
				Volume_Group=$(cat $Temp_Output_File | grep 'VOLUME GROUP' | awk '{ print $6 }' | tail -n 1) 2> /dev/null
				PP_Size=$(cat $Temp_Output_File | grep "PP SIZE" | awk '{ print $6 }' | tail -n 1) 2> /dev/null
				Current_LV_LP_Size=$(cat $Temp_Output_File | grep ^LPs: | awk '{ print $4 }' | tail -n 1) 2> /dev/null
				Max_LV_LPs=$(cat $Temp_Output_File | grep "MAX LPs" | awk '{ print $3 }' | tail -n 1) 2> /dev/null
				Max_LV_LPs_MB=$(expr $Max_LV_LPs \* $PP_Size)
				LV_Free_PPs=$(( Max_LV_LPs - Current_LV_LP_Size ))
				LV_Free_PPs_MB=$(expr $LV_Free_PPs \* $PP_Size)
			fi
			Color_and_RM_Temp_Output 2> /dev/null
			if [[ "$Main_Function" == "G_VG" ]] || [[ "$Main_Function" == "Obtain" ]]; then
				sed -i -f $Sed_File $Output_File
			else
				echo -e "${STD}" >> $Output_File
				Output_File_Last_Line
			fi
			G_VG
			if [ ! -z "$Logical_Volume" ]; then
				VG_Free_PPs=$(cat $Temp_Output_File | grep "FREE PPs" | awk '{ print $6 }' | tail -n 1) 2> /dev/null
				VG_Free_PPs_MB=$(expr $VG_Free_PPs \* $PP_Size)
				Max_Resize=$((Current_LV_LP_Size + VG_Free_PPs))
				Max_Resize_MB=$(expr $(expr $Current_LV_LP_Size \* $PP_Size) + $VG_Free_PPs_MB)
			fi
			Color_and_RM_Temp_Output 2> /dev/null
			if [[ "$Main_Function" == "G_LV" ]] || [[ "$Main_Function" == "Obtain" ]]; then
				sed -i -f $Sed_File $Output_File
			else
				Output_File_Last_Line
			fi
		fi
	else
		# Linux
		if [ "$Main_Function" == "Obtain" ]; then
			Logical_Volume=$(echo $Filesystem | rev | cut -d/ -f1 | rev | cut -d- -f2)
			echo "$($SSH $Server vgs --units m -o lv_full_name,vg_extent_size,vg_free,vg_free_count)" | grep -i "$Logical_Volume" > $Temp_File
			Volume_Group=$(cat $Temp_File | awk '{ print $1 }' | cut -d/ -f1)
			PP_Size=$(cat $Temp_File | awk '{ print $2 }' | cut -d. -f1)
			VG_Free_PPs_MB=$(cat $Temp_File | awk '{ print $3 }' | cut -d. -f1)
			VG_Free_PPs=$(cat $Temp_File | awk '{ print $4 }')
			LV_Free_PPs_MB=$(echo $VG_Free_PPs_MB)
			LV_Free_PPs=$(echo $VG_Free_PPs)
			rm -f $Temp_Output_File
		else
			echo "lvdisplay $Filesystem" >> $Temp_Output_File
			$SSH $Server lvdisplay $Filesystem >> $Temp_Output_File
			Volume_Group=$(cat $Temp_Output_File | grep 'VG Name' | awk '{ print $3 }')
			Color_and_RM_Temp_Output 2> /dev/null
			if [ "$Main_Function" == "G_VG" ]; then
				sed -i -f $Sed_File $Output_File
			else
				Output_File_Last_Line
			fi
			echo "vgdisplay $Volume_Group" >> $Temp_Output_File
			$SSH $Server vgdisplay $Volume_Group >> $Temp_Output_File
			Color_and_RM_Temp_Output 2> /dev/null
			if [ "$Main_Function" == "G_LV" ]; then
				sed -i -f $Sed_File $Output_File
			else
				Output_File_Last_Line
			fi
		fi
	fi
	if [ -z "$Logical_Volume" ]; then echo -e "${Cust_Error}No Logical Volume Found for ${Cust_Output}$Directory${STD}" >> $Output_File; fi
}

FS_Var_Dump(){
	echo -e "Main_Function = $Main_Function\nOF_Last_Line = $OF_Last_Line\nDirectory = $Directory\nLogical_Volume = $Logical_Volume\nVolume_Group = $Volume_Group\nCurrent_LV_LP_Size = $Current_LV_LP_Size\nMax_LV_LPs = $Max_LV_LPs\nMax_LV_LPs_MB = $Max_LV_LPs_MB\nLV_Free_PPs = $LV_Free_PPs\nLV_Free_PPs_MB = $LV_Free_PPs_MB\nVG_Free_PPs_MB = $VG_Free_PPs_MB\nMax_Resize = $Max_Resize\nPP_Size = $PP_Size\nFS_Size_Inc = $FS_Size_Inc\nNew_LV_LP_Size_MB = $New_LV_LP_Size_MB\nNew_LV_LP_Size = $New_LV_LP_Size\n"
	pause
}

G_VG(){
	C_OS_Test
	if [ "$OS_Test" == "AIX" ]; then
		# AIX
		echo "lsvg $Volume_Group" | tee $Command_File
		$SSH $Server lsvg $Volume_Group >> $Temp_Output_File
	else
		# G_LV Function uses the command "vgs" to obtain needed info for Resizing LV
		echo -e "${Cust_Error}Linux is NOT Supported Currently${STD}"
		pause
	fi
}

Resize_LV(){
	if [ "$OS_Test" == "AIX" ]; then
		if [[ "$Filesystem_Type" != "vxfs" ]] && [[ "$Filesystem_Type" != *"nfs"* ]]; then
			if [ "$FS_Size_Inc" -le "$VG_Free_PPs_MB" ]; then
				echo AIX
				echo -e "Increasing the Logical Volume ${Cust_Menu}$Logical_Volume${STD} by ${Cust_Menu}$FS_Size_Inc${STD} MB..."
				echo "chlv -x $New_LV_LP_Size $Logical_Volume" > $Command_File
				Log_and_Run_Commands >> $Temp_Output_File 2> $Temp_Error_File
				Color_and_RM_Temp_Output 2> /dev/null
				Color_and_RM_Temp_Error 2> /dev/null
				New_LV_LP_Size=$(( ( $FS_Size_Inc / $PP_Size ) + $New_LV_LP_Size ))
			else
				clear
				echo "Please set Logical Volume Increment  ( 1 - $VG_Free_PPs_MB )"
				pause
			fi
		else
			echo -e "${Cust_Error}Resizing Logical Volume is not supported for ${Cust_Menu}$Filesystem_Type${STD}"
			pause
		fi
	else
		echo -e "${Cust_Error}Only Supported on AIX...${STD}"
		pause
	fi
	#if [ "$FS_Action" == "LV" ]; then unset FS_Size_Inc FS_Action; fi
}

################################################################
##################### CISCO Functions ##########################
################################################################

D_User_Cisco(){
	clear
	read -p "Define Cisco Username:   " User_Cisco
	if [ ! -z "$User_Cisco" ]; then
		sed -i "s/User_Cisco =.*/User_Cisco = ${User_Cisco}/g" $Config_File
	fi
}

D_Password(){
	clear
	read -s -p "Define Cisco Password:   " Pass_Cisco
	echo   # Makes sure first line G_Cisco_Output() is lined up
}

C_Cisco(){
	Read_M_Commands
	C_Multi_Server
	C_Custom_Command
	if [ -z "$User_Cisco" ]; then
		echo "Please set Cisco Username"
		Var_Check=Failed
	fi
	C_Vars
	D_Password
}

G_Cisco_Output(){
	# This function uses "expect" to read STDOUT from the ssh command and to pass plaintext ( command , password )
	# Loops through the list of defined nodes... For each node, SSH port 22 is checked to see if the port is listening.
	# If the SSH port is listening, A loop through the list of defined commands is initiated.
	# Prints errors for connection timeout / wrong password... If the wrong password was defined. the loops will break to avoid active directory account lockout
	Read_M_Commands
	rm $Output_File 2> /dev/null;Output_File_Last_Line
	for i in $(seq 0 $M_Server_Size); do
		Server="${M_Server[$i]}"
		nc -z -w2 $Server 22 > /dev/null
		SSH_Test=$?
		if [ $SSH_Test -eq 0 ]; then
			for j in $(seq 0 $M_Commands_Size); do
				Custom_Command="${M_Commands[$j]}"
				# echo "$(( i + 1 )) / $(( M_Server_Size + 1 )) --- $Server        $(( j + 1 )) / $(( M_Commands_Size + 1 )) --- $Custom_Command"
				echo -e "${STD}\n${Cust_Menu}SNOC_Script $Server $Custom_Command $OS_Test${STD}\n${STD}" >> $Output_File
				cat $Output_File | tail -n +$OF_Last_Line | grep "37;40m";Output_File_Last_Line
				echo "$(date "+%b %d %Y %X"),$Main_User,$Server,${M_Commands[$j]}" >> $Log_File_Cisco
				/usr/bin/expect -f <(cat <<- EOF
				spawn ssh -o StrictHostKeyChecking=no -o LogLevel=quiet -l ${User_Cisco} ${Server} ${Custom_Command}
				set timeout 15
				expect {
					"assword: " {
						send "${Pass_Cisco}\r"
						expect {
							"assword: " {
								exit 1
							}
							timeout {
								exit 2
							}
							"#" {
								interact
								exit 0
							}
						}
					}
					timeout {
						exit 2
					}
				}
				EOF
				) > $Temp_File
				expect_ret_code=$?
				if [ $expect_ret_code -ne 0 ]; then
					if [ $expect_ret_code -eq 1 ]; then
						echo -e "${Cust_Error}Wrong Password or Authentiaction Issue... Ensure \"Non - A\" account is being used${STD}" >> $Output_File
						break 2  # break / escape out of 2 loops... ( break all the for loops in this case to avoid Acitve Directory account lockout )
					elif [ $expect_ret_code -eq 2 ]; then
						echo -e "${Cust_Error}Timeout Threshold Exceeded...${STD}" | tee -a $Temp_File
					fi
				fi
				sed -i "s/${Pass_Cisco}//g" $Temp_File
				sed -i 's/Connection to .*//g' $Temp_File
				cat $Temp_File | tr "\015" ' ' | grep -v "^spawn" | grep -v "assword: " > $Temp_Output_File
				Color_and_RM_Temp_Output 2> /dev/null
			done
			unset Server
		else
			echo -e "${STD}\n${Cust_Menu}SNOC_Script $Server $Custom_Command $OS_Test${STD}\n${STD}" >> $Output_File
			echo -e "${Cust_Error}$Server did not respond on SSH port 22${STD}" >> $Output_File
			continue
		fi
	done
	clear
}

################################################################
############## Define Multi Server Functions ###################
################################################################

D_M_Server(){
	# Opens "vim" in insert mode to define a list of node names...
	# After the user exits vim (if they know how to) A ping loop is initiated
	# If the ping test fails for a node, that node gets pruned from the up nodes and is added to "$M_Server_Removed" because it is assumed to be offline
	# Note: If a server is added to "$M_Server_Removed" no commands or functions will be ran against that node.
	unset OS_Test Var_Check
	vim -c 'startinsert' $M_Server_File
	M_Server_File_Longest_Line=$(wc -L $M_Server_File | awk '{ print $1 }')
	sed -i '/^$/d' $M_Server_File
	sed -i 's/ //g' $M_Server_File
	cat $M_Server_File | cut -f${NODE_NAME_Field} | awk '{ print $1 }' | cut -d\| -f1 | cut -d\, -f1 > $Temp_File
	if [[ "$M_Server_File_Longest_Line" -ge "70" ]]; then	# Assuming Alarms were copied in via OMi if longest line is over 70 Characters
		cat $Temp_File | grep -i -e fenetwork.com -e rts.local -e esa.local -e femtr.com -e fecorptest.com -e first-energy -e firstenergycorp | tr '[:upper:]' '[:lower:]' | cut -d\. -f1 | sort | uniq > $M_Server_File
	else
		cat $Temp_File | tr '[:upper:]' '[:lower:]' | cut -d\. -f1 | sort | uniq > $M_Server_File
	fi
	if [[ "$M_Server_File_Longest_Line" -ge "70" ]] && [[ "$Show_Warnings" -eq "1" ]]; then	# Assuming Alarms were copied in via OMi if longest line is over 70 Characters
		echo -e "${Cust_Error}--------------------------- W A R N I N G------------------------------${STD}"
		echo -e "${Cust_Error}Only using node names with valid FE domains...                         ${STD}"
		echo -e "${Cust_Error}    fenetwork.com   rts.local   esa.local   femtr.com   first-energy   ${STD}"
		echo -e "${Cust_Error}    fecorptest.com  firstenergycorp.com                                ${STD}"
		echo -e "${Cust_Error}                                                                       ${STD}"
		echo -e "${Cust_Error}                                                                       ${STD}"
		echo -e "${Cust_Error}If needing to define additional nodes:   Use option \"1\"                ${STD}"
		echo -e "${Cust_Error} a. Manually define any remaining nodes    OR                          ${STD}"
		echo -e "${Cust_Error} b. Paste in only the \"NODE_NAME\" field from OMi    (Using Excel)      ${STD}"
		echo -e "${Cust_Error}                                                                       ${STD}"
		echo -e "${Cust_Error} Note:  Duplicate Node Names are automatiacly removed                  ${STD}"
		echo -e "${Cust_Error}                                                                       ${STD}"
		echo -e "${Cust_Error}-----------------------------------------------------------------------${STD}"
		pause
	fi
}

Ping_Multi_Servername(){
	M_Server=();M_Server_Removed=();Down_Server=()
	M_Server_Size=-1;Down_Server_Size=-1;readarray -t M_Server < $M_Server_File;M_Server_Size=$((${#M_Server[@]}-1))
	rm -f $M_Server_Up_File $M_Server_Down_File 2> /dev/null
	if [ -z "$Bypass_Ping_Test" ]; then
		echo Pinging Server List...
		for ((i=0;i<=$M_Server_Size;i++)); do
			ping -c1 -W1 "${M_Server[$i]}" &> /dev/null && Echo_Reply=Yes || Echo_Reply=No
			if [ "$Echo_Reply" == "Yes" ]; then
				echo Up    "${M_Server[$i]}"
				echo "${M_Server[$i]}" >> $M_Server_Up_File
			else
				echo Down  "${M_Server[$i]}"
				echo "${M_Server[$i]}" >> $M_Server_Down_File
				Down_Server+=("$i")			# Index
				M_Server_Removed+=("${M_Server[$i]}")	# Hostname
			fi
		done
	else
		echo Bypassing Ping Test
		cp $M_Server_File $M_Server_Up_File
	fi
	Down_Server_Size=$((${#Down_Server[@]}-1))
	if [ "$Down_Server_Size" -gt "-1" ]; then	# Remove Down servers from array M_Server using M_Server index number in Down_Server array
		for ((i=$Down_Server_Size;i>=0;i--)); do clear
			index_plus_0=$((${Down_Server[$i]}))
			index_plus_1=$((${Down_Server[$i]}+1))
			M_Server=( "${M_Server[@]:0:$index_plus_0}" "${M_Server[@]:$index_plus_1}" )
		done
	fi
	M_Server_Size=$((${#M_Server[@]}-1))
	C_Multi_Server
	clear
}

C_Custom_Command(){
	if [ "$M_Commands_Size" -lt "0" ]; then
		echo "Please set Command"
		Var_Check=Failed
	else
		echo "$Custom_Command" > $Command_File
	fi
}

C_Multi_Server(){
	if [ "$M_Server_Size" -lt "0" ]; then
		echo "Please set Server Names"
		Var_Check=Failed
	fi
}

D_Custom_Command(){
	vim -c 'startinsert' $M_Commands_File
	sed -i '/^$/d' $M_Commands_File
	Read_M_Commands
} 

Read_M_Commands(){
	M_Commands=();M_Commands_Size=-1;readarray -t M_Commands < $M_Commands_File;M_Commands_Size=$((${#M_Commands[@]}-1))
}

Run_Multi_Custom_Function(){
	Output_File_Last_Line
	for num1 in $(seq 0 $M_Server_Size); do
		Server="${M_Server[$num1]}"
		#echo "$(( num1 + 1 )) / $(( M_Server_Size + 1 )) --- $Server"
		echo -e "${STD}\n${Cust_Menu}SNOC_Script $Server $OS_Test $Custom_Function${STD}\n${STD}" >> $Output_File
		cat $Output_File | tail -n +$OF_Last_Line | grep "37;40m";Output_File_Last_Line
		$Custom_Function | tee -a $Output_File
		unset Server
	done; clear
}

Run_Multi_Custom_Command(){
	Output_File_Last_Line
	for num1 in $(seq 0 $M_Server_Size); do
		Server="${M_Server[$num1]}"
		#echo "$(( num1 + 1 )) / $(( M_Server_Size + 1 )) --- $Server"
		for j in $(seq 0 $M_Commands_Size); do
			Custom_Command="${M_Commands[$j]}"
		#	echo "    $(( j + 1 )) / $(( M_Commands_Size + 1 )) --- $Custom_Command"
			echo -e "${STD}\n${Cust_Menu}SNOC_Script $Server $Custom_Command $OS_Test${STD}\n${STD}" >> $Output_File
			cat $Output_File | tail -n +$OF_Last_Line | grep "37;40m";Output_File_Last_Line
			echo $Custom_Command > $Command_File
			if [[ "$Server" != "w"* ]]; then
				Log_and_Run_Commands >> $Temp_Output_File
			else
				echo -e "${Cust_Error}Windows is NOT supported${STD}" >> $Temp_Output_File
			fi
			Color_and_RM_Temp_Output 2> /dev/null
		done
		unset Server
	done; clear
	View_Output
}

Log_and_Run_Commands(){
	# This function should at least be used whenever a "non-query" / "action" is performed on a server
	# Commands to be ran must be stored sequentially the $Command_File file
	readarray -t L_Commands < $Command_File
	L_Commands_Size=$((${#L_Commands[@]}-1))
	for ((i=0;i<=$L_Commands_Size;i++)); do
		echo "$(date "+%b %d %Y %X"),$Main_User,$Server,${L_Commands[$i]}" >> $Log_File
		$SSH $Server $(echo "${L_Commands[$i]}")
	done
}

Output_File_Last_Line(){ # Creates a quick file "$Sed_File" that references the current last line number of the "$Output_File"
			 # Use this command after calling this function to clean/print the $Output_File  ----> sed -i -f $Sed_File $Output_File
	touch $Output_File
	OF_Last_Line=$(wc -l $Output_File | awk '{ print $1 }')
	if [ "$OF_Last_Line" -eq "0" ]; then OF_Last_Line="1"; fi
	echo "$OF_Last_Line,\$d" > $Sed_File
	chmod +x $Sed_File
}

Color_and_RM_Temp_Output(){       #  Colors the   $Temp_Output_File   with   ${Cust_Output}   and appends to $Output_File
	Output=$(cat $Temp_Output_File)
	while read -r line; do
		if [ "$Randomness" -ge "3" ];then Randomize_Colors;fi
		echo -e "${Cust_Output}$line${STD}" >> $Output_File
	done <<< "$Output"
	rm -f $Temp_Output_File 2> /dev/null
}

Color_and_RM_Temp_Error(){	# Colors the   $Temp_Error_File   with   ${Cust_Error}   and appends to $Output_File
	Output=$(cat $Temp_Error_File)
	while read -r line; do
		if [ "$Randomness" -ge "3" ];then Randomize_Colors;fi
		echo -e "${Cust_Error}$line${STD}" >> $Output_File
	done <<< "$Output"
	rm -f $Temp_Error_File 2> /dev/null
}

View_Output(){
	if [[ ! -z "$(jobs)" ]];then wait;fi
	set +m
	if [ ! -z "Output_File" ];then
		echo -e "$(cat $Output_File)" | grep "37;40m" | less -R
	else
		echo -e "${Cust_Error}No Output File Found... Cannot View_Output()${STD}"
		pause
	fi
	set -m
}

################################################################
################# Miscellaneous Functions ######################
################################################################

This_is_sMark(){
	Phrase=(Yep K Bye "No Leon!" "Get back to work Leon!" "What Paged Me?" "Good Work" "This is Mark! Who joined?" Language "Uh-Huh" "Yep. K." "Is the PJM Report Done?" "Too much time on the small screens" "Not enough time on the big screens" "This is Mark!" "How many customers are out?" "Any interesting changes today?" "Don't forget to do your training..." Approved "Good Morning!" "Have A Quiet Evening!" "Whats the status of the RTUs today?" "That will be Approved" "What does CPO look like?" "Call Verizon" "Safety is Important!" "Got a meeting coming up"  "Why is there so much red on the board?" "Update Teams Chat" "Your quarterly check in is tomorrow" "Get out of the Schedule!" "Choooo-Choooo" "Any questions or concerns?" "Whats for lunch today?" Great "Good Teamwork!")
	Phrase_num=${#Phrase[@]}
	sMark_Bot_Messages+=("$(echo ${Phrase[$((RANDOM % Phrase_num))]})")
	unset Phrase_num
}

This_is_Leon(){
	Phrase=("Mr. BlueShirt" "Supervisor Mark Allen" "C'mon Dave" And... 9er "I can SNOC better than you" "Add a 9er" "Drop a 9er" DAMNIT "You da'man" "CRITICAR" "Throw a 9er in there" "Auto-Assist" "You can call me Leon" "Explain to me on how" "Criticur!")
	Phrase_num=${#Phrase[@]}
	Leon_Bot_Messages+=("$(echo ${Phrase[$((RANDOM % Phrase_num))]})")
	unset Phrase_num
}

Goodbye_SNOC(){
	# Hate to see you go... Stay motivated with a random phrase. :)
#	set +m
	rm -f ${Script_Temp_Dir}/${Main_User}/SNOC_Script_*
	rm -f .${Script_Temp_Dir}/${Main_User}/SNOC_Script_*
	Phrase=("Goodbye" "Leaving so soon?" "Hate to see you go" "Dont forget to go outside..." "Bye Bye" "What happens in SNOC stays in SNOC" "Bye Now!" "Thanks for SNOC-ing today!" "sudo SNOC" "Hasta la vista, baby" "May the Force be with you" "Houston, we have a problem" "Never trust a computer you can't throw out a window."  "We are all in the gutter, but some of us are looking at the stars." "Just keep swimming!" "Until next time my friend..." "Don't cry because it's over. Smile because it happened" "It ain't over 'til it's over" "Have a supercalifragilisticexpialidocious day!" "Have a Great Day!  :)" "Be miserable. Or motivate yourself. Whatever has to be done, it's always your choice" "  -------                  \n< Bye Now >                \n  -------                  \n        \   ^__^           \n         \  (oo)\_______   \n            (__)\       )\/\\n                ||---w-||  \n                ||     ||  ")
	Phrase_num=${#Phrase[@]}
	echo -e "${Cust_Error}${Phrase[$((RANDOM % Phrase_num))]}${STD}"
}

I_Wanna_Play_A_Game(){
	clear;Max_Val="30000";Selected="-1";num="0";Target=$((RANDOM % Max_Val)); Min_Val="0";while [ "$Selected" != "$Target" ];do unset Selected; while [ -z "$Selected" ]; do echo -e "Guess a Number between ${Cust_Menu}$Min_Val${STD} - ${Cust_Menu}$Max_Val${STD}   ";read -p "" Selected;if ! [[ $Selected == +([0-9]) ]]; then unset Selected; echo Please Define a Positive Integer; fi;done;if [[ "$Selected" -ge "$Max_Val" ]] || [[ "$Selected" -le "$Min_Val" ]]; then echo -e "${Cust_Error}Outside of Range${STD}  ${Cust_Menu}( $Min_Val - $Max_Val )${STD}";else num=$(( $num + 1 ));if [ "$Selected" -lt "$Target" ]; then echo -e "${Cust_Menu}${num}${STD}:  ${Cust_Output}Guess Higher...${STD}"; Min_Val=$Selected; fi;if [ "$Selected" -gt "$Target" ]; then echo -e "${Cust_Menu}${num}${STD}:  ${Cust_Output}Guess Lower...${STD}"; Max_Val=$Selected; fi;if [ "$Selected" -eq "$Target" ]; then echo -e "${Cust_Output}You got the answer in ${Cust_Menu}$num${Cust_Output} guesses\n\n${Cust_Error}Now Get Back To Work!${STD}"; pause > /dev/null; fi;fi;if [ "$Selected" -eq "42" ]; then clear; echo -e "${Cust_Error}The Answear to Life, the Universe, and Everything!\n${Cust_Output}CONGRATULATIONS!!!!!!!!!!!!${STD}";Selected=$Target;pause > /dev/null;fi;done;unset Max_Val Selected num Target Min_Val
}

################################################################
################# Define Menus and Loops #######################
################################################################

Set_Banner(){
	printf -v pad %${Banner_Padding}s
	cols=$(tput cols)
	if [[ "${Menus[$S2LMI]}" == "Read_Menu_Main" ]] || [[ "$MOTD_All" -eq "1" ]];then
		update_banner="yes"
		Banner="$MOTD"
	else
		update_banner="yes"
		Banner=$( echo "$Menu_Banner" | perl -pe 's/\e\[[0-9;]*m(?:\e\[K)?//g' )
	fi
	if [ ! -z "$update_banner" ];then
		rm -f $Banner_File
		Banner=$Banner$pad
		num=$(( $cols / ( $(echo "$Banner" | wc -c) -1 ) ))
		for i in $(seq $num);do echo -e -n "$Banner" >> $Banner_File;done
		echo >> $Banner_File
		unset update_banner
	fi
}

Menu_Timer(){ # Specify variables in seconds
	unset choice
	if [[ -z "$Old_Menus_Size" ]] || [[ "$Old_Menus_Size" -ne "${#Menus[@]}" ]];then	# New Menu is diplayed... Menus size changes
		Old_Menus_Size="${#Menus[@]}"
		if [[ "$Randomness" -eq "1" ]] && [[ "${Menus[$S2LMI]}" == *"Menu_Main" ]];then Randomize_Colors
		elif [[ "$Randomness" -gt "1" ]] && [[ "${Menus[$S2LMI]}" == "Read_Menu_"* ]];then Randomize_Colors
		fi
		if [[ "${Menus[$LMI]}" == "Menu_Timer" ]] && [[ "${Menus[$S2LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$T2LMI]}" == "Print_"* ]];then
			Set_Banner
		fi
	fi
#	paused
	read_ms=$(echo "$Menu_Refresh_Rate / 1000" | bc -l)
	sleep_max="10000"
	count="0"
	G_LMI
	read -t 0.001 -N 1000000	# Discard STDIN
	while [[ -z "$choice" ]] && [[ "$count" -lt "$sleep_max" ]];do
		unset choice
		if [[ "${Menus[$LMI]}" == "Menu_Timer" ]] && [[ "${Menus[$S2LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$T2LMI]}" == "Print_"* ]];then
			if [ "$Randomness" -ge "4" ];then Randomize_Colors;fi
			if [[ "${Menus[$S2LMI]}" == "Read_Menu_Main" ]];then
				if [[ "$sMark_Bot" -gt "0" ]];then menu_reset="no"
					if [[ "$sMark_Bot" -ge "$((RANDOM % 100))" ]];then This_is_sMark;fi
				fi
				if [[ "$Leon_Bot" -gt "0" ]];then menu_reset="no"
					if [[ "$Leon_Bot" -ge "$((RANDOM % 100))" ]];then This_is_Leon;fi
				fi
			fi
			
			if [[ "$Banner_Disabled" -eq "0" ]];then
				screen=$(cat $Banner_File)
				if [[ "$Scroll_Direction" -eq "0" ]];then sed -i -r "s/(.{$Scroll_Intensity})(.*)/\2\1/" $Banner_File
				else sed -i -r "s/(.*)(.{$Scroll_Intensity})/\2\1/" $Banner_File
				fi
			fi
			screen=$(echo -e "$screen\n$(seq -s'*' 1 $(tput cols)  | tr -d '[:digit:]')")	# Prints a row of *******
			clear;echo -e "$screen"
			${Menus[$T2LMI]}	# Prints Menu
		else
			echo -e "${Cust_Error}Non-proper menus are assigned in the \"Menus\" Arrar${STD}"
			Print_Menu_Vars
			paused
		fi
#		Print_Menu_Vars
		read -s -p "" -n 1 -t $read_ms choice
		count=$(($count+$Menu_Refresh_Rate))
	done
	unset Menus[${LMI}]
}

Print_User_Config_Menu(){
	if [[ "$Menu_Banner" != "Modify Config File   " ]];then Menu_Banner="Modify Config File   ";fi
	echo -e "1  Define:     Cisco Username -- (Non A) account         Currently = ${Cust_Output}$User_Cisco${STD}"
	echo -e -n "2  Toggle:     Display Database Passwords in Menu        Currently = ";if [ "$Always_Show_DB_PW" -eq "0" ];then echo -e "${Cust_Error}No${STD}";fi;if [ "$Always_Show_DB_PW" -eq "1" ];then echo -e "${Cust_Output}Yes${STD}";fi
	echo -e -n "3  Toggle:     Display Database Filesystems in Menu      Currently = ";if [ "$Always_Show_DB_FS" -eq "0" ];then echo -e "${Cust_Error}No${STD}";fi;if [ "$Always_Show_DB_FS" -eq "1" ];then echo -e "${Cust_Output}Yes${STD}";fi
	echo -e -n "4  Define:     NODE_NAME field # in your OMi display.    Currently = ";if [ "$NODE_NAME_Field" -eq "0" ];then echo -e "${Cust_Error}$NODE_NAME_Field${STD}";else echo -e "${Cust_Output}$NODE_NAME_Field${STD}";fi
	echo -e -n "5  Toggle:     Show Warnings?                            Currently = ";if [ "$Show_Warnings" -eq "0" ];then echo -e "${Cust_Error}No${STD}";fi;if [ "$Show_Warnings" -eq "1" ];then echo -e "${Cust_Output}Yes (Recommended)${STD}";fi
	echo -e -n "D  Toggle:     Dev Mode... For testing new features.     Currently = ";if [ "$Dev_Mode" -eq "0" ];then echo -e "${Cust_Output}No  (Recommended)${STD}";fi;if [ "$Dev_Mode" -eq "1" ];then echo -e "${Cust_Error}Yes${STD} This May Be Extremely Buggy... Bring a Flyswatter or Bugspray... Probably best to leave off...";fi
	echo -e "\n\nR  Set:        Menu Refresh Rate (Milliseconds)          Currently = ${Cust_Output}$Menu_Refresh_Rate${STD}"
	echo -e -n "B  Toggle:     Banner Status                             Currently = ";if [ "$Banner_Disabled" -eq "0" ];then echo -e "${Cust_Output}Banner is Enabled (Recommended)${STD}";fi;if [ "$Banner_Disabled" -eq "1" ];then echo -e "${Cust_Error}Banner is Disabled${STD}";fi
	echo -e -n "N  Toggle:     Scrolling Banner Direction                Currently = ";if [ "$Scroll_Direction" -eq "0" ];then echo -e "${Cust_Output}Left${STD}";fi;if [ "$Scroll_Direction" -eq "1" ];then echo -e "${Cust_Output}Right${STD}";fi
	echo -e "M  Set:        Scrolling Banner Text                     Currently = ${Cust_Output}$MOTD${STD}"
	echo -e "P  Toggle:     Scrolling Banner Padding (Spaces)         Currently = ${Cust_Output}$Banner_Padding${STD}"
	echo -e -n ",  Toggle:     Custom    Banner Across All Menus?        Currently = ";if [ "$MOTD_All" -eq "0" ];then echo -e "${Cust_Output}Main Menu Only (Recommended)${STD}";fi;if [ "$MOTD_All" -eq "1" ];then echo -e "${Cust_Error}All Menus${STD}";fi
	echo -e ".  Toggle:     Scrolling Banner Intensity                Currently = ${Cust_Output}$Scroll_Intensity${STD}"
	if [ -z "$sMark_Bot" ];then sMark_Bot="0";fi;echo -e "S  Set:        sMark Bot Seek & Destroy (Main Menu Only) Currently = ${Cust_Output}$sMark_Bot%${STD}"
	if [ -z "$Leon_Bot" ];then Leon_Bot="0";fi;echo -e "L  Set:        Leon  Bot                (Main Menu Only) Currently = ${Cust_Output}$Leon_Bot%${STD}"
	if [ -z "$Color_List" ];then Color_List="01234567";fi
	if [[ "$Scroll_Direction" -eq "0" ]];then Color_List=$(echo "$Color_List" | sed -r 's/(.{1})(.*)/\2\1/');else Color_List=$(echo "$Color_List" | sed -r 's/(.*)(.{1})/\2\1/');fi
	echo -e "\n\n\033[1;9$CL7;100m9  \033[1;9$CL5;100mM\033[1;9$CL1;100me\033[1;9$CL6;100mn\033[1;9$CL3;100mu\033[1;9$CL0;100m:       \033[1;9$CL0;100mC\033[1;9$CL1;100mu\033[1;9$CL2;100ms\033[1;9$CL3;100mt\033[1;9$CL4;100mo\033[1;9$CL5;100mm\033[1;9$CL6;100mi\033[1;9$CL7;100mz\033[1;9$CL0;100me \033[1;9$CL2;100mC\033[1;9$CL3;100mo\033[1;9$CL4;100ml\033[1;9$CL5;100mo\033[1;9$CL6;100mr\033[1;9$CL5;100ms${STD}"
#	echo -e "\n\n\033[1;9$CL7;100m9  \033[1;9$CL5;100mM\033[1;9$CL1;100me\033[1;9$CL6;100mn\033[1;9$CL3;100mu\033[1;9$CL0;100m:       \033[1;9$CL0;10${CL0}mC\033[1;9$CL1;10${CL0}mu\033[1;9$CL2;10${CL0}ms\033[1;9$CL3;10${CL0}mt\033[1;9$CL4;10${CL0}mo\033[1;9$CL5;10${CL0}mm\033[1;9$CL6;10${CL0}mi\033[1;9$CL7;10${CL0}mz\033[1;9$CL0;10${CL0}me \033[1;9$CL2;10${CL0}mC\033[1;9$CL3;10${CL0}mo\033[1;9$CL4;10${CL0}ml\033[1;9$CL5;10${CL0}mo\033[1;9$CL6;10${CL0}mr\033[1;9$CL5;10${CL0}ms${STD}     \033[1;9$CL0;100mC\033[1;9$CL1;100mu\033[1;9$CL2;100ms\033[1;9$CL3;100mt\033[1;9$CL4;100mo\033[1;9$CL5;100mm\033[1;9$CL6;100mi\033[1;9$CL7;100mz\033[1;9$CL0;100me \033[1;9$CL2;100mC\033[1;9$CL3;100mo\033[1;9$CL4;100ml\033[1;9$CL5;100mo\033[1;9$CL6;100mr\033[1;9$CL5;100ms${STD}     \033[1;9$CL0;10${CL7}mC\033[1;9$CL1;10${CL6}mu\033[1;9$CL2;10${CL5}ms\033[1;9$CL3;10${CL4}mt\033[1;9$CL4;10${CL3}mo\033[1;9$CL5;10${CL2}mm\033[1;9$CL6;10${CL1}mi\033[1;9$CL7;10${CL0}mz\033[1;9$CL0;10${CL7}me \033[1;9$CL2;10${CL5}mC\033[1;9$CL3;10${CL4}mo\033[1;9$CL4;10${CL3}ml\033[1;9$CL5;10${CL2}mo\033[1;9$CL6;10${CL1}mr\033[1;9$CL5;10${CL0}ms${STD}"
	echo -e "0: Previous Menu"
	CL0=$(echo $Color_List | sed 's/.//2g');CL1=$(echo $Color_List | sed 's/.//3g' | rev | sed 's/.//2g');CL2=$(echo $Color_List | sed 's/.//4g' | rev | sed 's/.//2g');CL3=$(echo $Color_List | sed 's/.//5g' | rev | sed 's/.//2g');CL4=$(echo $Color_List | sed 's/.//6g' | rev | sed 's/.//2g');CL5=$(echo $Color_List | sed 's/.//7g' | rev | sed 's/.//2g');CL6=$(echo $Color_List | sed 's/.//8g' | rev | sed 's/.//2g');CL7=$(echo $Color_List | sed 's/.//9g' | rev | sed 's/.//2g')
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_User_Config_Menu " ]];then
		Menus+=("Read_Menu_User_Config_Menu" "Menu_Timer")
	fi
}

Read_Menu_User_Config_Menu(){
	case $choice in
		1) D_User_Cisco ;;
		2) if [ "$Always_Show_DB_PW" -lt "1" ]; then Always_Show_DB_PW=$(( $Always_Show_DB_PW + 1 ));else Always_Show_DB_PW=0;fi;sed -i "s/Always_Show_DB_PW = .*/Always_Show_DB_PW = $(echo $Always_Show_DB_PW)/" $Config_File ;;
		3) if [ "$Always_Show_DB_FS" -lt "1" ]; then Always_Show_DB_FS=$(( $Always_Show_DB_FS + 1 ));else Always_Show_DB_FS=0;fi;sed -i "s/Always_Show_DB_FS = .*/Always_Show_DB_FS = $(echo $Always_Show_DB_FS)/" $Config_File ;;
		4) D_NODE_NAME_Field ;;
		5) if [ "$Show_Warnings" -lt "1" ]; then Show_Warnings=$(( $Show_Warnings + 1 ));else Show_Warnings=0;fi;sed -i "s/Show_Warnings = .*/Show_Warnings = $(echo $Show_Warnings)/" $Config_File ;;
		d|D) if [ "$Dev_Mode" -lt "1" ]; then Dev_Mode=$(( $Dev_Mode + 1 ));else Dev_Mode=0;fi;sed -i "s/Dev_Mode = .*/Dev_Mode = $(echo $Dev_Mode)/" $Config_File ;;
		r|R) read -p "Set Menu Refresh Rate in Milliseconds:   " Menu_Refresh_Rate;if ! [[ $Menu_Refresh_Rate == +([0-9]) ]] || [[ "$Menu_Refresh_Rate" -lt "50" ]]; then echo -e "${Cust_Error}Please enter a Whole Number Greater Than 50 Milliseconds${STD}" && sleep 3;Menu_Refresh_Rate="700";fi;sed -i "s/Menu_Refresh_Rate = .*/Menu_Refresh_Rate = $(echo $Menu_Refresh_Rate)/" $Config_File ;;
		b|B) if [ "$Banner_Disabled" -lt "1" ]; then Banner_Disabled=$(( $Banner_Disabled + 1 ));else Banner_Disabled=0;fi;sed -i "s/Banner_Disabled = .*/Banner_Disabled = $(echo $Banner_Disabled)/" $Config_File ;;
		m|M) read -p "Type a New Banner:   " MOTD;sed -i "s/MOTD = \".*/MOTD = \"$(echo "$MOTD")\"/" $Config_File;MOTD=$(cat $Config_File | grep "^MOTD" | grep -oP '(?<=MOTD = ").*(?=")');update_banner="yes";Set_Banner ;;
		p|P) if [ "$Banner_Padding" -lt "10" ]; then Banner_Padding=$(( $Banner_Padding + 1 ));else Banner_Padding=0;fi;sed -i "s/Banner_Padding = .*/Banner_Padding = $(echo $Banner_Padding)/" $Config_File;update_banner="yes";Set_Banner ;;
		n|N) if [ "$Scroll_Direction" -lt "1" ]; then Scroll_Direction=$(( $Scroll_Direction + 1 ));else Scroll_Direction=0;fi;sed -i "s/Scroll_Direction = .*/Scroll_Direction = $(echo $Scroll_Direction)/" $Config_File ;;
		,|\<) if [ "$MOTD_All" -lt "1" ]; then MOTD_All=$(( $MOTD_All + 1 ));else MOTD_All=0;fi;update_banner="yes";Set_Banner;sed -i "s/MOTD_All = .*/MOTD_All = $(echo $MOTD_All)/" $Config_File ;;
		\.|\>) if [ "$Scroll_Intensity" -lt "10" ]; then Scroll_Intensity=$(( $Scroll_Intensity + 1 ));else Scroll_Intensity=0;fi;sed -i "s/Scroll_Intensity = .*/Scroll_Intensity = $(echo $Scroll_Intensity)/" $Config_File ;;
		s|S) read -p "Set sMark Bot Percentage:   " sMark_Bot;if ! [[ $sMark_Bot == +([0-9]) ]] || [[ "$sMark_Bot" -lt "0" ]] || [[ "$sMark_Bot" -gt "100" ]]; then echo -e "${Cust_Error}Please enter a Whole Number between 0 - 100${STD}" && sleep 3;sMark_Bot="0";fi;sed -i "s/sMark_Bot = .*/sMark_Bot = $(echo $sMark_Bot)/" $Config_File ;;
		l|L) read -p "Set Leon Bot Percentage:   " Leon_Bot;if ! [[ $Leon_Bot == +([0-9]) ]] || [[ "$Leon_Bot" -lt "0" ]] || [[ "$Leon_Bot" -gt "100" ]]; then echo -e "${Cust_Error}Please enter a Whole Number between 0 - 100${STD}" && sleep 3;Leon_Bot="0";fi;sed -i "s/Leon_Bot = .*/Leon_Bot = $(echo $Leon_Bot)/" $Config_File ;;
		9) Menus+=("Print_Color_Menu") ;;
		*) echo >> /dev/null
	esac
}

Print_Color_Menu(){
	if [[ "$Menu_Banner" != "Custom Color Menu   " ]];then Menu_Banner="Custom Color Menu   ";fi
	Conf_Test_Error=$(cat $Config_File | grep ^Randomize | grep "\ Cust_Error")
	Conf_Test_Output=$(cat $Config_File | grep ^Randomize | grep "\ Cust_Output")
	Conf_Test_Menu=$(cat $Config_File | grep ^Randomize | grep "\ Cust_Menu")
	if [ "$Randomness" -gt "1" ]; then echo -e "${Cust_Error}\"Randomness Level\" too high to set color options${STD}\n\n\n";if [ "$Randomness" -ge "3" ];then echo -e -n "${Cust_Error}                                                                                             \nThis Level Of Randomness May Impact Script's Performance If Large Output Files Need Processed\n                                                                                             ${STD}";else echo -e "\n";fi;echo -e "\n\n\n\n${STD}"; else echo -n "Set: "; if [ ! -z "$Bold" ]; then echo -e -n "\033[1mBOLD${STD}  "; fi; if [ ! -z "$Dim" ]; then echo -e -n "\033[2mDIM${STD}  "; fi; if [ ! -z "$Under" ]; then echo -e -n "\033[4mUNDER${STD}  "; fi; if [ ! -z "$Blink" ]; then echo -e -n "\033[5mBLINK${STD}  "; fi; if [ ! -z "$Opt_FG" ]; then echo -e -n "$Opt_FG  "; else echo -e -n "FG_Dark  "; fi; if [ ! -z "$Opt_BG" ]; then echo -e -n "$Opt_BG  "; else echo -e -n "BG_Dark  "; fi; echo -e "\n";fi
	if [ "$Randomness" -le "1" ]; then
		echo -e "1: Toggle:        \033[1mBOLD    TEXT${STD}"
		echo -e "2: Toggle:        \033[2mDIM     TEXT${STD}"
		echo -e "3: Toggle:        \033[4mUNDER   TEXT${STD}"
		echo -e "4: Toggle:        \033[5mBLINK   TEXT${STD}   (Some Terminals)"
		echo -e "5: Toggle:        Foreground Text Brightness"
		echo -e "6: Toggle:        Background Text Brightness"
		echo -e -n "9: Define:        Custom ANSI Color Code     "; if [ ! -z "$Cust_Color_Code" ]; then echo -e "\\${Cust_Color_Code}\\\\${Cust_Color_Code}${STD}"; else echo; fi
		echo "Q: View:          Color Examples  (With Specified Options)"
		echo -e "W: Reset:         All Color Code Options"
	fi
	echo -e -n "\nP: Toggle:        Randomness Level       Currently: ${Cust_Error}";if [[ "$Randomness" -eq "0" ]];then echo -n "No Randomness...";elif [[ "$Randomness" -eq "1" ]];then echo -n "Randomizing At Main Menu Only";elif [[ "$Randomness" -eq "2" ]];then echo -n "Randomizing At Any New Menu";elif [[ "$Randomness" -eq "3" ]];then echo -n "Randomizing at Any New Menu  AND  For Each New Line Of Output";elif [[ "$Randomness" -eq "4" ]];then echo -n "Randomizing at menus every $Menu_Refresh_Rate Milliseconds & For Each Line Of Output";fi;echo -e "${STD}"
	echo -e -n "    A: Toggle:        Error   Color Auto Randomize  ${Cust_Error}";if [[ -z "$Conf_Test_Error" ]];then echo -e -n "Static       ";else echo -e -n "Randomizing  ";fi;echo -e "Currently = $(echo \\${Cust_Error})${STD}"
	echo -e -n "    S: Toggle:        Output  Color Auto Randomize  ${Cust_Output}";if [[ -z "$Conf_Test_Output" ]];then echo -e -n "Static       ";else echo -e -n "Randomizing  ";fi;echo -e "Currently = $(echo \\${Cust_Output})${STD}"
	echo -e -n "    D: Toggle:        Menu    Color Auto Randomize  ${Cust_Menu}";if [[ -z "$Conf_Test_Menu" ]];then echo -e -n "Static       ";else echo -e -n "Randomizing  ";fi;echo -e "Currently = $(echo \\${Cust_Menu})${STD}"
	if [ "$Randomness" -gt "1" ];then echo -e "\n\n";else
		echo -e "    Z: Overwrite:     Error   Color in Config File"
		echo -e "    X: Overwrite:     Output  Color in Config File"
		echo -e "    C: Overwrite:     Menu    Color in Config File"
	fi
	echo -e "\nPresets --------------------------------------"
	echo -e "    B: Randomize:     Maximum Randomness"
	echo -e "    N: Randomize:     Reset Randomness and Randomize All Colors One Time"
	echo -e "    M: Reset:         Reset Randomness and Set All Colors to Default"
	echo -e -n "\nR: Remember Colors Options When Relaunching Script?   ${Cust_Error}";if [ "$Remember_Colors" -eq "0" ];then echo -n "No";else echo -n "Yes";fi;echo -e "${STD}"
	echo -e "0: Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Color_Menu " ]];then
		Menus+=("Read_Menu_Color_Menu" "Menu_Timer")
	fi
}

Read_Menu_Color_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Color | less ;;
		1) if [ -z "$Bold" ]; then Bold="1;"; else unset Bold; fi ;;
		2) if [ -z "$Dim" ]; then Dim="2;"; else unset Dim; fi ;;
		3) if [ -z "$Under" ]; then Under="4;"; else unset Under; fi ;;
		4) if [ -z "$Blink" ]; then Blink="5;"; else unset Blink; fi ;;
		5) if [ "$Opt_FG" == "FG_Bright" ]; then Opt_FG="FG_Dull"; else Opt_FG="FG_Bright"; fi ;;
		6) if [ "$Opt_BG" == "BG_Bright" ]; then Opt_BG="BG_Dull"; else Opt_BG="BG_Bright"; fi ;;
		9) clear;if [ "$Randomness" -le "1" ]; then Print_Colors;echo -e "\n\n\n";read -p "Enter ANSI Color Code: " Cust_Color_Code;Check_Cust_Color;C_Vars;fi ;;
		p|P) if [ "$Randomness" -lt "4" ]; then Randomness=$(( $Randomness + 1 ));else Randomness=0;fi;sed -i "s/Randomness = .*/Randomness = $(echo $Randomness)/" $Config_File;Read_Config_File ;;
		a|A) if [ ! -z "$Conf_Test_Error" ];then sed -i 's/\ Cust_Error/\ /g' $Config_File;else sed -i 's/Randomize = /Randomize = Cust_Error /g' $Config_File;fi;Read_Config_File ;;
		s|S) if [ ! -z "$Conf_Test_Output" ];then sed -i 's/\ Cust_Output/\ /g' $Config_File;else sed -i 's/Randomize = /Randomize = Cust_Output /g' $Config_File;fi;Read_Config_File ;;
		d|D) if [ ! -z "$Conf_Test_Menu" ];then sed -i 's/\ Cust_Menu/\ /g' $Config_File;else sed -i 's/Randomize = /Randomize = Cust_Menu /g' $Config_File;fi;Read_Config_File ;;
		q|Q) if [ "$Randomness" -le "1" ]; then Print_Colors;pause;fi ;;
		w|W) unset Bold Dim Under Blink Opt_FG Opt_BG ;;
		z|Z) if [[ -z "$Conf_Test_Error" ]] && [[ "$Randomness" -le "1" ]] || [[ "$Randomness" -eq "0" ]];then Check_Cust_Color;C_Vars;sed -i "s/Cust_Error = .*/Cust_Error = \\\\$(echo "$Cust_Color_Code")/" $Config_File;fi;Read_Config_File ;;
		x|X) if [[ -z "$Conf_Test_Output" ]] && [[ "$Randomness" -le "1" ]] || [[ "$Randomness" -eq "0" ]];then Check_Cust_Color;C_Vars;sed -i "s/Cust_Output = .*/Cust_Output = \\\\$(echo "$Cust_Color_Code")/" $Config_File;fi;Read_Config_File ;;
		c|C) if [[ -z "$Conf_Test_Menu" ]] && [[ "$Randomness" -le "1" ]] || [[ "$Randomness" -eq "0" ]];then Check_Cust_Color;C_Vars;sed -i "s/Cust_Menu = .*/Cust_Menu = \\\\$(echo "$Cust_Color_Code")/" $Config_File;fi;Read_Config_File ;;
		b|B) sed -i "s/Randomness = .*/Randomness = 4/" $Config_File;sed -i "s/Randomize = .*/Randomize = Cust_Output Cust_Error Cust_Menu/" $Config_File;Randomize_Colors;Read_Config_File ;;
		n|N) Reset_Colors;Randomize_Colors;Read_Config_File ;;
		m|M) Reset_Colors;Read_Config_File ;;
		r|R) if [ "$Remember_Colors" -lt "1" ]; then Remember_Colors=$(( $Remember_Colors + 1 ));else Remember_Colors=0;fi;sed -i "s/Remember_Colors = .*/Remember_Colors = $(echo $Remember_Colors)/" $Config_File ;;
		*) echo >> /dev/null
	esac
}

Print_RMAN_Menu() {
	if [[ "$Menu_Banner" != "RMAN MENU   " ]];then Menu_Banner="RMAN MENU   ";fi
	echo -e "Server:             [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e "Database:           [${Cust_Menu}$Database${STD}]"
	echo -e "RMAN log:           [${Cust_Menu}$RMAN_File${STD}]"
	echo -e "\n"
	echo "1. Define:     Servername"
	echo "2. Define:     Database"
	echo "3. Define:     RMAN Log"
	echo "Q. Get:        RMAN Log Listing"
	echo "W. Get:        RMAN Log Output"
	echo "0. Database Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_RMAN_Menu " ]];then
		Menus+=("Read_Menu_RMAN_Menu" "Menu_Timer")
	fi
}
Read_Menu_RMAN_Menu(){
	case $choice in
		\!) D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Database;C_Vars;C_OS_Test;Main_Function="Obtain";G_Tablespace_Info ;;
		1) D_Servername;C_Server;C_Vars;C_OS_Test ;;
		2) C_Server;C_Vars;D_Database;G_Tablespace_Info ;;
		3) clear;read -p "Define RMAN Log:   " RMAN_File ;;
		q|Q) C_Server;C_Vars;G_RMAN_Listing;View_Output ;;
		w|W) C_Server;C_RMAN_File;C_Vars;G_RMAN_Output;View_Output ;;
		*) echo >> /dev/null
	esac
}

Print_Export_Menu() {
	if [[ "$Menu_Banner" != "EXPORT ERROR MENU   " ]];then Menu_Banner="EXPORT ERROR MENU   ";fi
	echo -e "Server:             [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e "Database:           [${Cust_Menu}$Database${STD}]"
	echo -e "\n"
	echo "1. Define:     Servername"
	echo "2. Define:     Database"
	echo "Q. Hot Backup"
	echo "W. Full Export"
	echo "E. Datapump"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Export_Menu " ]];then
		Menus+=("Read_Menu_Export_Menu" "Menu_Timer")
	fi
}

Read_Menu_Export_Menu(){
	case $choice in
		\!) D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Database;C_Vars;C_OS_Test;Main_Function="Obtain";G_Tablespace_Info ;;
		1) D_Servername;C_Server;C_Vars;C_OS_Test ;;
		2) C_Server;C_Vars;D_Database ;;
		q|Q) C_Server;C_Database;C_Vars;Export_Log="hot.log";G_Export_Error;View_Output ;;
		w|W) C_Server;C_Database;C_Vars;Export_Log="exp.log";G_Export_Error ;;
		e|E) C_Server;C_Database;C_Vars;Export_Log="expdp.log";G_Export_Error ;;
		*) echo >> /dev/null
	esac
}

Print_Database_Menu() {
	if [[ "$Menu_Banner" != "DATABASE MENU   " ]];then Menu_Banner="DATABASE MENU   ";fi
	if [[ "$Hot_Standby" != *"SNOC_${Server}"* ]]; then if [ ! -z "$Server" ]; then G_Hot_Standby 2> /dev/null;fi;fi
	echo -e "${Cust_Error}$Hot_Standby"|grep -v "SNOC_";echo -e -n "${STD}"
	echo -e "Server:             [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e -n "Database:           [${Cust_Menu}$Database${STD}]";if [[ ! -z "$Server" ]] && [[ ! -z "$Database" ]] && [[ "$Always_Show_DB_PW" -gt "0" ]];then echo -e "    [${Cust_Menu}$DB_PW${STD}]";else echo;fi
	if [[ ! -z "$Server" ]] && [[ ! -z "$Database" ]] && [[ "$Always_Show_DB_FS" -gt "0" ]];then echo -e "${Cust_Output}$DB_FS${STD}";fi
	echo -e "\n"
	echo "!. Paste:      OMi Database Alarm            \"NODE_NAME\" or \"Node Hint\" Must be in field #$NODE_NAME_Field, \"Object\" and \"Title\" fields should exist for best results"
	echo "1. Define:     Servername"
	echo "2. Define:     Database"
	echo "3. Define:     OMi CIHint Custom Attribute   Format = Database (Server)"
	echo
	echo "Q. Get:        TABLESPACE INFO"
	echo "W. Get:        Get alert_${Database}.log     lowercase = cat    uppercase = tail -f"
	echo "E. Get:        Hot / Full / Datapump EXPORT ERRORS"
	echo "R. Get:        RMAN Errors"
	echo "T. Get:        Primary / Standby Synchronization Status"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Database_Menu " ]];then
		Menus+=("Read_Menu_Database_Menu" "Menu_Timer")
	fi
}

Read_Menu_Database_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Database | less ;;
		\!) D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Database;C_Vars;C_OS_Test;Main_Function="Obtain";G_Tablespace_Info ;;
		1) D_Servername;C_Server;C_Vars;C_OS_Test;Main_Function="Obtain";G_Tablespace_Info ;;
		2) C_Server;C_Vars;D_Database;Main_Function="Obtain";G_Tablespace_Info;if [ "$Dev_Mode" -eq "1" ];then G_Oratab;fi ;;
		3) D_DB_CI_Hint;C_Server;C_Database;C_Vars;C_OS_Test;Main_Function="Obtain";G_Tablespace_Info ;;
		8) if [ "$Always_Show_DB_FS" -lt "1" ]; then Always_Show_DB_FS=$(( $Always_Show_DB_FS + 1 ));else Always_Show_DB_FS=0;fi;sed -i "s/Always_Show_DB_FS = .*/Always_Show_DB_FS = $(echo $Always_Show_DB_FS)/" $Config_File ;;
		9) if [ "$Always_Show_DB_PW" -lt "1" ]; then Always_Show_DB_PW=$(( $Always_Show_DB_PW + 1 ));else Always_Show_DB_PW=0;fi;sed -i "s/Always_Show_DB_PW = .*/Always_Show_DB_PW = $(echo $Always_Show_DB_PW)/" $Config_File ;;
		q|Q) C_Server;C_Vars;unset Main_Function;G_Tablespace_Info;View_Output ;;
		w|W) C_Server;C_Database;C_Vars;G_DB_Alert_Log;Color_and_RM_Temp_Output 2> /dev/null;View_Output ;;
		e|E) Menus+=("Print_Export_Menu") ;;
		r|R) Menus+=("Print_RMAN_Menu") ;;
		t|T) C_Server;C_Database;C_Vars;G_DB_Logfile_Sync;View_Output ;;
		*) echo >> /dev/null
	esac
}

Print_Server_Menu() {
	if [[ "$Menu_Banner" != "SERVER MENU   " ]];then Menu_Banner="SERVER MENU   ";fi
	echo -e "Server:             [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e "\n"
	echo "!. Paste:      OMi Database Alarm            \"NODE_NAME\" or \"Node Hint\" Must be in field #$NODE_NAME_Field, \"Object\" and \"Title\" fields should exist for best results"
	echo -e "1. Define:     Servername"
	echo -e "Q. Get:        MPIO Path Status      -- Prints /scripts/bin/mpio_summary.ksh or multipath -ll output"
	echo -e "W. Get:        eService Status       -- Warnings occurred during the read of the OVO responsible manager configuration alarms"
	echo -e "E. Get:        ${Cust_Error}UNIX${STD} OM Agent Status  -- Full perfstat output..."
	echo -e "R. Get:        ${Cust_Error}ALL${STD}  OM Agent Status  -- Requires ovbbccb to be running   ---  Registered Components Only"
	echo -e "Z. Action:     ${Cust_Error}UNIX${STD} Restart OM Agent -- Follows SNOC's procedure"
	echo -e "X. Action:     ${Cust_Error}ALL${STD}  Restart OM Agent -- Requires ovbbccb to be running   ---  Registered Components Only"
	echo -e "M. Action:     OM Message Test       -- Generate Green OMi Event if successful ---  ${Cust_Error}Works With All Operating Systems & Domains${STD}"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Server_Menu " ]];then
		Menus+=("Read_Menu_Server_Menu" "Menu_Timer")
	fi
}

Read_Menu_Server_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Server | less ;;
		\!) D_Single_Alarm;C_Server;C_Vars;C_OS_Test ;;
		1) D_Servername;C_Server;C_Vars;C_OS_Test ;;
		q|Q) C_Server;C_Vars;G_MPIO;View_Output ;;
		w|W) C_Server;C_Vars;G_eService;View_Output ;;
		e|E) C_Server;C_Vars;G_OM_Agent_Status_UNIX;View_Output ;;
		r|R) C_Server;C_Vars;G_OM_Agent_Status;View_Output ;;
		z|Z) C_Server;C_Vars;OM_Agent_Restart_UNIX;View_Output ;;
		x|X) C_Server;C_Vars;OM_Agent_Restart;View_Output ;;
		m|M) C_Server;C_Vars;Test_OM_Agent ;;
		*) echo >> /dev/null
	esac
}

Print_Filesystem_Menu(){
	if [[ "$Menu_Banner" != "FILESYSTEM MENU   " ]];then Menu_Banner="FILESYSTEM MENU   ";fi
	unset Main_Function FS_Action
	if [[ "$Hot_Standby" != *"SNOC_${Server}"* ]]; then if [ ! -z "$Server" ]; then G_Hot_Standby > /dev/null 2>&1;if [ "$Dev_Mode" -eq "1" ];then G_Oratab;fi;fi;fi
	echo -e "${Cust_Error}$Hot_Standby" | grep -v "SNOC_";echo -e -n "${STD}"
	echo -e ""
	if [ ! -z "$Directory" ]; then
		echo -e "Volume Info:        $LVM_LV: [${Cust_Menu}$Logical_Volume${STD}]    $LVM_VG: [${Cust_Menu}$Volume_Group${STD}]   Free in $LVM_VG: [${Cust_Menu}$VG_Free_PPs_MB${STD}] MB"
		echo -e "Filesystem Info:    Free Space: [${Cust_Menu}$FS_Avail_Space${STD}]    Total Space: [${Cust_Menu}$FS_Size${STD}]"
	fi
	echo -e ""
	echo "!. Paste:      OMi Database Alarm            \"NODE_NAME\" or \"Node Hint\" Must be in field #$NODE_NAME_Field, \"Object\" and \"Title\" fields should exist for best results"
	echo -e "1. Define:     Servername                     [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e -n "2. Define:     Database                       [${Cust_Menu}$Database${STD}]";if [[ ! -z "$Server" ]] && [[ ! -z "$Database" ]] && [[ "$Always_Show_DB_PW" -gt "0" ]];then echo -e "    [${Cust_Menu}$DB_PW${STD}]";else echo;fi
	if [[ ! -z "$Server" ]] && [[ ! -z "$Database" ]] && [[ "$Always_Show_DB_FS" -gt "0" ]];then echo -e "${Cust_Output}$DB_FS${STD}";fi
	echo -e -n "3. Define:     Filesystem / Logical Volume    [${Cust_Menu}$Directory${STD}] ${Cust_Menu}$Filesystem_Type${STD}"; if [ ! -z "$Directory" ]; then echo -e -n " --- [${Cust_Menu}$FS_Percent${STD}] % Full   Free in FS = [${Cust_Menu}$FS_Avail_Space${STD}] MB"; fi
	echo -e -n "\n4. Define:     FS / LV Increase (MB)          [${Cust_Menu}$FS_Size_Inc${STD}] MB"; if [[ ! -z "$Filesystem_Type" ]] && [[ "$Filesystem_Type" != "vxfs" ]] && [[ "$Filesystem_Type" != "jfs"* ]]; then echo -e "  ${Cust_Error}Filesystem Resizing for ${Cust_Menu}$Filesystem_Type${Cust_Error} is NOT supported${STD}"; else if [[ ! -z "$Directory" ]] && [[ "$Filesystem_Type" != "vxfs" ]]; then echo -e -n "   Available for Assignment = [${Cust_Menu}$VG_Free_PPs_MB${STD}] MB"; fi; fi
	if [[ "$Filesystem_Type" == "vxfs" ]] || [[ "$Filesystem_Type" == *"nfs"* ]]; then echo; else if [[ ! -z "$Directory" ]] && [[ ! -z "$Server" ]]; then if [ "$VG_Free_PPs_MB" -lt "32768" ];then echo -e "\n${Cust_Error}Consider creating a ticket to UNIX... The $LVM_VG ${Cust_Output}$Volume_Group${Cust_Error} has less than 32 GB Free: ${Cust_Output}$VG_Free_PPs_MB${Cust_Error} MB Free...${STD}"; fi; fi; fi
	echo -e "\n"
	echo "Q. Get:        Database Directories"
	echo "W. Get:        \"df -m\""
	echo "E. Get:        \"du -mx\"     ----  Check for files that are using the most space an a directory"
	echo "R. Get:        \"ls -la\"     ----  Get \"Long Listing\" of files"
	echo "T. Get:        LV  Logical Volume  info"
	echo "Y. Get:        VG  Volume Group    info"
	echo "U. Get:        LV  and  VG         info"
	echo "I. Get:        \"mount\""
	echo -n "Z. Action:     Resize Filesystem  AND  Logical Volume";if [[ ! -z "$Filesystem_Type" ]] && [[ "$Filesystem_Type" != "vxfs" ]] && [[ "$Filesystem_Type" != "jfs"* ]]; then echo -e "    ${Cust_Error}NOT Supported for ${Cust_Menu}$Filesystem_Type${Cust_Error} Filesystems${STD}";else echo; fi
	echo "X. Action:     Resize Only the Logical Volume   ( AIX ONLY )"
	echo "?. Update:     Gets latest values for Specified Filesystem"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Filesystem_Menu " ]];then
		Menus+=("Read_Menu_Filesystem_Menu" "Menu_Timer")
	fi
}

Read_Menu_Filesystem_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Filesystem | less ;;
		\!) Initialize_Vars;D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Directory;C_Vars;C_OS_Test;FS_Action="Obtain";Main_Function="Obtain";G_Mount ;;
		1) Initialize_Vars;D_Servername;C_Server;C_Vars;C_OS_Test;G_Tablespace_Info ;;
		2) C_Server;C_Vars;D_Database;Main_Function="Obtain";G_Tablespace_Info ;;
		3) C_Server;C_Vars;FS_Action="Obtain";Main_Function="Obtain";D_Directory;C_Directory;C_Vars;G_Mount;G_Tablespace_Info ;;
		4) C_Server;C_Directory;C_Vars;D_FS_Increase ;;
		8) if [ "$Always_Show_DB_FS" -lt "1" ]; then Always_Show_DB_FS=$(( $Always_Show_DB_FS + 1 ));else Always_Show_DB_FS=0;fi;sed -i "s/Always_Show_DB_FS = .*/Always_Show_DB_FS = $(echo $Always_Show_DB_FS)/" $Config_File ;;
		9) if [ "$Always_Show_DB_PW" -lt "1" ]; then Always_Show_DB_PW=$(( $Always_Show_DB_PW + 1 ));else Always_Show_DB_PW=0;fi;sed -i "s/Always_Show_DB_PW = .*/Always_Show_DB_PW = $(echo $Always_Show_DB_PW)/" $Config_File ;;
		q|Q) C_Server;C_Vars;G_Tablespace_Info;View_Output ;;
		w|W) C_Server;C_Vars;G_DF_FS;View_Output ;;
		e|E) C_Server;C_Directory;C_Vars;G_DU_FS;View_Output ;;
		r|R) C_Server;C_Directory;C_Vars;G_LS_FS;View_Output ;;
		t|T) if [ "$Filesystem_Type" != "vxfs" ];then C_Server;C_Directory;C_Vars;Main_Function="G_LV";G_LV;View_Output;fi ;;
		y|Y) if [ "$Filesystem_Type" != "vxfs" ];then C_Server;C_Directory;C_Vars;Main_Function="G_VG";G_LV;View_Output;fi ;;
		u|U) if [ "$Filesystem_Type" != "vxfs" ];then C_Server;C_Directory;C_Vars;Main_Function="";G_LV;View_Output;fi ;;
		i|I) C_Server;C_Vars;G_Mount;View_Output ;;
		d|D) clear;FS_Var_Dump ;;
		z|Z) C_Server;C_Directory;C_FS_Size_Increment;C_Vars;FS_Action="Both";Resize_FS;Main_Function="Obtain";G_LV;View_Output ;;
		x|X) C_LV;C_FS_Size_Increment;C_FS_Size_Increment;C_Vars;FS_Action="LV";Resize_LV;Main_Function="Obtain";G_LV ;;
		\?) Update_FS_Info ;;
		#\?) C_Server;C_Directory;C_Vars;C_OS_Test;FS_Action="Obtain";Main_Function="Obtain";G_Mount;G_Tablespace_Info;G_DF_FS ;;
		*) echo >> /dev/null
	esac
}

Print_TSM_Menu() {
	if [[ "$Menu_Banner" != "TSM MENU   " ]];then Menu_Banner="TSM MENU   ";fi
	echo -e "Server:             [${Cust_Menu}$Server${STD}]    $OS_Test"
	echo -e "\n"
	echo "1. Define:     Servername"
	echo "Q. Get:        dsmsched.log"
	echo "W. Get:        dsmerror.log"
	echo "E. Get:        jbberror.log"
	echo "R. Get:        TSM Running Processes"
	echo "T. Get:        TSM Configuration"
	echo "Z. Action:     Restart TSM Client Acceptor"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_TSM_Menu " ]];then
		Menus+=("Read_Menu_TSM_Menu" "Menu_Timer")
	fi
}

Read_Menu_TSM_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_TSM | less ;;
		\!) D_Single_Alarm;C_Server;C_Vars;C_OS_Test ;;
		1) D_Servername;C_Server;C_Vars;C_OS_Test ;;
		q|Q) C_Server;C_Vars;TSM_Log="dsmsched.log";G_TSM_Log;View_Output ;;
		w|W) C_Server;C_Vars;TSM_Log="dsmerror.log";G_TSM_Log;View_Output  ;;
		e|E) C_Server;C_Vars;TSM_Log="jbberror.log";G_TSM_Log;View_Output  ;;
		r|R) C_Server;C_Vars;G_TSM_Processes;Color_and_RM_Temp_Output;View_Output  ;;
		t|T) C_Server;C_Vars;G_TSM_Config;View_Output  ;;
		z|Z) C_Server;C_Vars;Restart_TSM_Client_Acceptor;View_Output  ;;
		*) echo >> /dev/null
	esac
}

Print_Multi_Cisco_Menu(){
	if [[ "$Menu_Banner" != "CISCO MENU   " ]];then Menu_Banner="CISCO MENU   ";fi
	M_Server_Size=$((${#M_Server[@]}-1));Read_M_Commands 2> /dev/null
#	echo -e "~. README:     Multi Cisco Menu Notes / Tips          Note: When copying alarms via OMi only nodes with valid FE domain names will be used"
	echo -e "1. Define:     Servernames                 ${Cust_Output}using vim${STD}  Note: One server per line${STD}       Use \"!\" to wipe file first"
	if [ "$M_Server_Size" -gt "-1" ]; then echo -e "${Cust_Output}Up Nodes${STD}";printf "${Cust_Output_pf}%s\t%s\t%s${std}\n" "${M_Server[@]}" | awk '{printf "%-40s %-40s %-40s\n",$1,$2,$3}'; fi
	if [ "$Down_Server_Size" -gt "-1" ]; then echo -e "${Cust_Error}Down Nodes  ---  Removed from list${STD}";printf "${Cust_Error_pf}%s\t%s\t%s${std}\n" "${M_Server_Removed[@]}" | awk '{printf "%-40s %-40s %-40s\n",$1,$2,$3}'; fi
	echo -e "2. Define:     User - \"Non-A\" Account      ${Cust_Menu}$User_Cisco${STD}"
	echo -e "3. Define:     Custom Commands             ${Cust_Output}using vim${STD}  Note: One command per line${STD}"
	if [ -f $M_Commands_File ]; then Output=$(cat $M_Commands_File); while read -r line; do echo -e "${Cust_Output}$line${STD}"; done <<< "$Output"; fi
	echo "9. Run:        Custom Cisco Commands       Note: Only \"show\" commands / \"Privileged Exec\" commands that release terminal..."
	echo -e ""
	echo "Q. Get:        show ip bgp summary         BGP Alarms"
	echo "W. Get:        show vrrp brief             VRRP Alarms"
	echo "E. Get:        show ip interface brief     Check Connection Down Alarms"
	echo "R. Get:        show env all                Power Supply / Fan Alarms   (This might work...)"
	echo "T. Get:        show module                 Check all modules in chasis"
	echo "Y. Get:        show ip route               See full routing table"
	echo "U. Get:        show cdp neighbors          See attached Cisco devices"
	echo "I. Get:        show version                Check Cisco IOS / Device Platform / uptime information"
	echo "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Multi_Cisco_Menu " ]];then
		Menus+=("Read_Menu_Multi_Cisco_Menu" "Menu_Timer")
	fi
}

Read_Menu_Multi_Cisco_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Cisco | less ;;
		1) D_M_Server;Ping_Multi_Servername ;;
		\!) rm $M_Server_File 2> /dev/null;D_M_Server;Ping_Multi_Servername ;;
		2) D_User_Cisco ;;
		3) D_Custom_Command ;;
		9) C_Cisco;G_Cisco_Output;View_Output ;;
		q|Q) echo "show ip bgp summary" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		w|W) echo "show vrrp brief" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		e|E) echo "show ip interface brief" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		r|R) echo "show env all" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		t|T) echo "show module" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		y|Y) echo "show ip route" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		u|U) echo "show cdp neighbors" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		i|I) echo "show version" | tee $M_Commands_File;C_Cisco;G_Cisco_Output;unset Pass_Cisco;View_Output ;;
		0) unset Server ;;
		*) echo >> /dev/null
	esac
}

Print_Multi_Server_Menu() {
	if [[ "$Menu_Banner" != "MULTI SERVER MENU   " ]];then Menu_Banner="MULTI SERVER MENU   ";fi
	M_Server_Size=$((${#M_Server[@]}-1));Read_M_Commands 2> /dev/null
	echo -e "${Cust_Error}All commands will be ran as \"root\"         ${STD}       Use \"=\" to toggle server ping test and run actions against all nodes"
	echo -e -n "${Cust_Error}With Great Power Comes Great Responsibility${STD}       Bypass Ping Test = "; if [ ! -z "$Bypass_Ping_Test" ]; then echo -e "${Cust_Error}Yes${STD}"; else echo -e "No"; fi
#	if [ "$M_Server_Size" -gt "-1" ]; then
#		if [ -z "$Bypass_Ping_Test" ]; then echo -e "${Cust_Output}Up Nodes${STD}"; printf "${Cust_Output_pf}%s\t%s\t%s${std}\n" "${M_Server[@]}" | awk '{printf "%-40s %-40s %-40s\n",$1,$2,$3}'; fi
#		if [ ! -z "$Bypass_Ping_Test" ]; then echo -e "${Cust_Error}Bypassing Ping Test...${STD}"; printf "%s\t%s\t%s\n" "${M_Server[@]}" | awk '{printf "%-40s %-40s %-40s\n",$1,$2,$3}'; fi
#	fi
	if [ -z "$Bypass_Ping_Test" ];then
		if [ "$M_Server_Size" -gt "-1" ]; then
			paste <(printf "${Cust_Output_pf}%-40s\t%-40s${std}\n" "${M_Server[@]}") <(printf "${Cust_Error_pf}%-40s\t%-40s${std}\n" "${M_Server_Removed[@]}") | awk -F '\t' '{ printf("%-40s%-40s%-40s%-40s\n", $1, $2, $3, $4) }'
		fi
	else
		paste <(printf "%-40s\t%-40s\n" "${M_Server[@]}") <(printf "%-40s\t%-40s\n" "${M_Server_Removed[@]}") | awk -F '\t' '{ printf("%-40s%-40s%-40s%-40s\n", $1, $2, $3, $4) }'
	fi
#	if [ "$Down_Server_Size" -gt "-1" ]; then echo -e "${Cust_Error}Down Nodes  ---  Removed from list${STD}";printf "${Cust_Error_pf}%s\t%s\t%s${std}\n" "${M_Server_Removed[@]}" | awk '{printf "%-40s %-40s %-40s\n",$1,$2,$3}'; fi
	echo -e "\n"
	echo -e "~. README:     Multi Server Menu Notes / Tips          Note: When copying alarms via OMi only nodes with valid FE domain names will be used"
	echo -e "1. Define:     Servernames                  ${Cust_Output}using vim${STD}  Note: One server per line${STD}       Use \"!\" to wipe file first"
	echo -e "2. Define:     Directory                    [${Cust_Menu}$Directory${STD}]"
	echo -e "3. Define:     Custom Commands              ${Cust_Output}using vim${STD}  Note: One command per line${STD}"
	if [ -f $M_Commands_File ]; then Output=$(cat $M_Commands_File); while read -r line; do echo -e "${Cust_Output}$line${STD}"; done <<< "$Output"; fi
	echo -e "9. Run:        Custom Commands"
	echo
	echo -e "Q. Database    Get ALL Tablespace Info      --   Gets 'cat /etc/pwfile' and 'df -m | grep -e dbfiles -e sapdata' output"
	echo -e "W. Server      Get MPIO Path                --   Prints /scripts/bin/mpio_summary.ksh or multipath -ll output"
	echo -e "E. Server      Get eService Status          --   Warnings occurred during the read of the OVO responsible manager configuration alarms"
	echo -e "R. Server      ${Cust_Error}UNIX Only${STD} OM Agent Status    --   Prints perfstat output"
	echo -e "T. Server      ${Cust_Error}All OS's${STD}  OM Agent Status    --   Prints registered component status   --  Requires ovbbccb to be running"
	echo -e "Y. Server      OM Message Test              --   Generates a green alarm in OMi if Agent is working"
	echo -e "U. TSM         View dsmsched.log            --   Prints dsmsched.log"
	echo -e "I. TSM         View dsmerror.log            --   Prints dsmerror.log"
	echo -e "O. TSM         View jbberror.log            --   Prints jbberror.log"
	echo -e "P. TSM         Check TSM Configuration      --   Checks TSM boot-time configuration"
	echo -e "A. TSM         Check TSM Processes          --   Gets 'ps -ef | grep -e dsmc -e tsm' output"
	echo -e "S. FS          Get \"df -m\" Output           --   Get 'df -m' output"
	echo -e "D. NNMi        NNMI Ping                    --   Pings via NNMi  (lhpnnmigm1p) --- Use \"=\" first to Bypass Ping Test (Should be Yes)"
	echo -e "Z. OM Action   ${Cust_Error}UNIX Only${STD} OM Agent Reboot    --   Restarts Restart OM Agent and prints perfstat  --  Follows SNOC's procedure"
	echo -e "X. OM Action   ${Cust_Error}All OS's${STD}  OM Agent Reboot    --   Restart OM Agent --   Restarts OM agent's registered components    --  Requires ovbbccb to be running"
	echo -e "C. TSM Action  Restart TSM Client Acceptor  --   Restarts TSM according to SNOC's Procedure"
	echo -e "0. Main Menu"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Multi_Server_Menu " ]];then
		Menus+=("Read_Menu_Multi_Server_Menu" "Menu_Timer")
	fi
}

Read_Menu_Multi_Server_Menu(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Multi_Server | less ;;
		1) D_M_Server;Ping_Multi_Servername ;;
		\!) rm $M_Server_File 2> /dev/null;D_M_Server;Ping_Multi_Servername ;;
		2) D_Directory;Filesystem=$(echo $Directory) ;;
		3) D_Custom_Command ;;
		9) C_Multi_Server;C_Custom_Command;C_Vars;Run_Multi_Custom_Command ;;
		=) if [ -z "$Bypass_Ping_Test" ]; then Bypass_Ping_Test="Yes"; else unset Bypass_Ping_Test; fi;Ping_Multi_Servername ;;
		q|Q) C_Multi_Server;C_Vars;Database="Multi_Server";Custom_Function="G_Tablespace_Info";Run_Multi_Custom_Function;View_Output ;;
		w|W) C_Multi_Server;C_Vars;Custom_Function="G_MPIO";Run_Multi_Custom_Function;View_Output ;;
		e|E) C_Multi_Server;C_Vars;Custom_Function="G_eService";Run_Multi_Custom_Function;View_Output ;;
		r|R) C_Multi_Server;C_Vars;Custom_Function="G_OM_Agent_Status_UNIX";Run_Multi_Custom_Function;View_Output ;;
		t|T) C_Multi_Server;C_Vars;Custom_Function="G_OM_Agent_Status";Run_Multi_Custom_Function;View_Output ;;
		y|y) C_Multi_Server;C_Vars;Custom_Function="Test_OM_Agent";Run_Multi_Custom_Function ;;
		u|U) C_Multi_Server;C_Vars;TSM_Log="dsmsched.log";Custom_Function="G_TSM_Log";Run_Multi_Custom_Function;View_Output ;;
		i|I) C_Multi_Server;C_Vars;TSM_Log="dsmerror.log";Custom_Function="G_TSM_Log";Run_Multi_Custom_Function;View_Output ;;
		o|O) C_Multi_Server;C_Vars;TSM_Log="jbberror.log";Custom_Function="G_TSM_Log";Run_Multi_Custom_Function;View_Output ;;
		p|P) C_Multi_Server;C_Vars;Custom_Function="G_TSM_Config";Run_Multi_Custom_Function;View_Output ;;
		a|A) C_Multi_Server;C_Vars;Custom_Function="G_TSM_Processes";Run_Multi_Custom_Function;Color_and_RM_Temp_Output;View_Output ;;
		s|S) C_Multi_Server;C_Vars;Custom_Function="G_DF_FS";Run_Multi_Custom_Function;View_Output ;;
		d|D) C_Multi_Server;C_Vars;Custom_Function="NNMI_Ping";Run_Multi_Custom_Function;View_Output ;;
		z|Z) C_Multi_Server;C_Vars;Custom_Function="OM_Agent_Restart_UNIX";Run_Multi_Custom_Function;View_Output ;;
		x|X) C_Multi_Server;C_Vars;Custom_Function="OM_Agent_Restart";Run_Multi_Custom_Function;View_Output ;;
		c|C) C_Multi_Server;C_Vars;Custom_Function="Restart_TSM_Client_Acceptor";Run_Multi_Custom_Function;View_Output ;;
		0) unset Server Database Bypass_Ping_Test ;;
		*) echo >> /dev/null
	esac
}

Print_Menu_Main(){
	Initialize_Vars
	echo -e "                 ${Cust_Output}https://snoc:8443/display/TRAINREF/SNOC+Linux+Scripts${STD}\n"
	if [[ "$Show_Warnings" -eq "1" ]]; then
		echo -e "${Cust_Error}Note:   In any Menu  ( 1 - 6 )                                                                                        ${STD}"
		echo -e "${Cust_Error}        Use \"!\" to paste in appropriate alarms directly from OMi for the current menu you are in                      ${STD}"
		echo -e "${Cust_Error}        Alternatively, Hold shift when selecting an option from this menu to immediately be prompted to paste an alarm${STD}\n"
	fi
	echo -e "1. Menu:  SERVER            ${Cust_Output}(${STD} ${Cust_Menu}MPIO${STD}      ${Cust_Output},${STD} ${Cust_Menu}eService${STD}     ${Cust_Output},${STD} ${Cust_Menu}OM Agent${STD}          ${Cust_Output})${STD}"
	echo -e "2. Menu:  DATABASE          ${Cust_Output}(${STD} ${Cust_Menu}TOAD Info${STD} ${Cust_Output},${STD} ${Cust_Menu}FAL Request${STD}  ${Cust_Output},${STD} ${Cust_Menu}Export Errors${STD}     ${Cust_Output},${STD} ${Cust_Menu}RMAN${STD}                  ${Cust_Output})${STD}"
	echo -e "3. Menu:  FILESYSTEM        ${Cust_Output}(${STD} ${Cust_Menu}df -m${STD}     ${Cust_Output},${STD} ${Cust_Menu}LV / VG Info${STD} ${Cust_Output},${STD} ${Cust_Menu}Resize Filesystem${STD} ${Cust_Output},${STD} ${Cust_Menu}Resize Logical Volume${STD} ${Cust_Output})${STD}"
	echo -e "4. Menu:  TSM               ${Cust_Output}(${STD} ${Cust_Menu}TSM Logs${STD}  ${Cust_Output},${STD} ${Cust_Menu}Check Config${STD} ${Cust_Output},${STD} ${Cust_Menu}Restart TSM${STD}       ${Cust_Output})${STD}"
	echo -e "5. Menu:  SERVER (Multiple) ${Cust_Output}(${STD} ${Cust_Menu}Most Everything Above${STD}    ${Cust_Output},${STD} ${Cust_Menu}Custom Commands${STD}   ${Cust_Output},${STD} ${Cust_Error}POWER USERS${STD}           ${Cust_Output})${STD}"
	echo -e "6. Menu:  CISCO  (Multiple) ${Cust_Output}(${STD} ${Cust_Menu}VRRP${STD}      ${Cust_Output},${STD} ${Cust_Menu}BGP${STD}          ${Cust_Output},${STD} ${Cust_Menu}Custom Commands${STD}   ${Cust_Output})${STD}"
	echo
	echo "9. Menu:  User Configurable Settings"
	echo "?. Reset: User Configurable Settings"
	echo "0. Exit"
	paste <(printf "${Cust_Output_pf}%-40s${std}\n" "${sMark_Bot_Messages[@]}") <(printf "${Cust_Menu_pf}%-40s${std}\n" "${Leon_Bot_Messages[@]}") | awk -F '\t' '{ printf("%-40s%-40s\n", $1, $2) }'
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Main " ]];then
		Menus+=("Read_Menu_Main" "Menu_Timer")
	fi
}

Read_Menu_Main(){
	case $choice in
		\~) cat ${Script_Temp_Dir}/Subscripts/README_Main | less ;;
		1) Menus+=("Print_Server_Menu") ;;
		\!) Menus+=("Print_Server_Menu");G_LMI;D_Single_Alarm;C_Server;C_Vars;C_OS_Test ;;
		2) Menus+=("Print_Database_Menu") ;;
		\@) Menus+=("Print_Database_Menu");G_LMI;D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Database;C_Vars;C_OS_Test;G_Tablespace_Info ;;
		3) Menus+=("Print_Filesystem_Menu") ;;
		\#) Menus+=("Print_Filesystem_Menu");G_LMI;Initialize_Vars;D_Single_Alarm;C_Single_Alarm_Set_Vars;C_Server;C_Directory;C_Vars;C_OS_Test;FS_Action="Obtain";Main_Function="Obtain";G_Mount ;;
		4) Menus+=("Print_TSM_Menu") ;;
		\$) Menus+=("Print_TSM_Menu");G_LMI;D_Single_Alarm;C_Server;C_Vars;C_OS_Test ;;
		5) Menus+=("Print_Multi_Server_Menu") ;;
		\%) Menus+=("Print_Multi_Server_Menu");G_LMI;rm $M_Server_File 2> /dev/null;D_M_Server;Ping_Multi_Servername ;;
		6) Menus+=("Print_Multi_Cisco_Menu") ;;
		\^) Menus+=("Print_Multi_Cisco_Menu");G_LMI;rm $M_Server_File 2> /dev/null;D_M_Server;Ping_Multi_Servername ;;
		9) Menus+=("Print_User_Config_Menu") ;;
		\?) Create_Config_File;Read_Config_File ;;
		r|R) Randomness=0;sed -i "s/Randomness = .*/Randomness = $(echo $Randomness)/" $Config_File;Randomize_Colors ;;
		k|K) $(echo "This_is_sMark");menu_reset="no" ;;
		l|L) $(echo "This_is_Leon");menu_reset="no" ;;
		g|G) I_Wanna_Play_A_Game ;;
		0) unset Menus ;;
		*) echo -n ""
	esac
}

G_LMI(){	# Get Last Menu Index number...  Gets Last few index numbers in the array  "Menus"
	Last_3_Menu_Indexs=$(for index in "${!Menus[@]}"; do echo "$index -- ${Menus[$index]}"; done | awk '{ print $1 }' | tail -n 3 | tac)
	LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '1p')		# LMI   = Last Menu Index
	S2LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '2p')	# S2LMI = Second To Last Menu Index
	T2LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '3p')	# T2LMI = Third To Last Menu Index
}

################################################################
############### Initial Logic / Call Main Menu #################
################################################################

Print_Menu_Vars(){
	echo -e -n "$count   $LMI:${Menus[$LMI]}   $S2LMI:${Menus[$S2LMI]}   $T2LMI:${Menus[$T2LMI]}    ${!Menus[@]}   MR = ";if [[ -z "$menu_reset" ]];then echo -e -n "No";else echo -e -n "Yes";fi;echo -e "    ${Menus[@]}\n${Menus[@]}\n"
}

Clean_Files(){
	RM_Files 2> /dev/null
}

Hello_SNOC(){
	if [ ! -f "$Config_File" ]; then Create_Config_File;fi;Read_Config_File
	if [[ "$Remember_Colors" -eq "0" ]];then Reset_Colors;Read_Config_File;fi
	Menus=("Print_Menu_Main");unset choice
	while [[ ! -z "$Menus" ]]; do
		G_LMI	#	Ensure you are working with latest "Menus" elements
		if [[ -z "$menu_reset" ]];then	# Needed for sMark bot Search and Destroy feature...  (Coming Soon)
#			echo -e "${Cust_Error}menu_reset is not set... Removing sMark and Leon bots${STD}"
			unset sMark_Bot_Messages Leon_Bot_Messages
			clear;if [[ "${Menus[$T2LMI]}" == "Print_"* ]];then
				clear
#				${Menus[$T2LMI]}
#			else
#				echo -e "${Cust_Error}Expected ${Menus[$T2LMI]} to be a Print Menu Function${STD}"
#				paused
			fi
		fi
		if [[ "${Menus[$LMI]}" == "Menu_Timer" ]];then
#			echo -e "${Cust_Error}Last Menu is \"Menu_Timer\"... Calling \"Menu_Timer\"${STD}"
#			paused
			Clean_Files
			${Menus[$LMI]}
			continue
		fi
		if [[ ! -z "$choice" ]];then
			if [[ $choice == +([0-9]) ]] && [[ "$choice" -eq "0" ]]; then
#				echo -e "${Cust_Error}Chose \"0\"${STD}"
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
#					echo -e "${Cust_Error}Removing ${Menus[$LMI]} and ${Menus[$S2LMI]}${STD}"
					unset Menus[${LMI}]
					unset Menus[${S2LMI}];G_LMI
					if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
						Menus+=("Menu_Timer");G_LMI	# Display Previous Menu and start Reading the menu via Timer
						Clean_Files
#						paused
						${Menus[$T2LMI]}
					fi
#				else
#					echo -e "${Cust_Error}Unexpected Situation Occured...  Pressed \"0\"${STD}"
#					paused
				fi
				unset choice;continue
			fi
			if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]];then 
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
					unset menu_reset
#					echo -e "${Cust_Error}Calling ${Menus[$LMI]} to check choice $choice${STD}"
					Menus+=("Menu_Timer")
#					paused
					${Menus[$LMI]}	# Call Read_Menu_* to check $choice
				fi
#			else
#				echo -e "${Cust_Error}Unexpected Situation Occured...  Expected Last Menu to be Read and Previous to be Print...${STD}"
#				paused
			fi
			unset choice
			continue
		else
			if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]];then
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
#					echo -e "${Cust_Error}No choice received... Relistining to ${Menus[$LMI]}${STD}"
					Menus+=("Menu_Timer")
					continue
				fi
			fi
#			echo -e "${Cust_Error}Unexpected Situation Occured...  Expected a choice...  None received${STD}"
#			paused
		fi
#		echo -e "${Cust_Error}No conditions met...${STD}"
#		paused
		Clean_Files
		${Menus[$LMI]}
	done
}

Hello_SNOC
Goodbye_SNOC
