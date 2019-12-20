#!/bin/bash
# Starting Off With a She-Bang

# Written by:			Corey Johnson

Set_Initial_Vars(){
	STD='\033[0;37;40m'
	std=$(echo $STD | sed 's/\\033/\\e/')
	StartTime=$(date "+%m-%d-%y.%M.%S.%N")
	Root_Test=$(whoami)
	if [ -z "$Main_User_Override" ];then Main_User=$(who am i | awk '{ print $1 }')
	else Main_User=$Main_User_Override;echo "Running script as $Main_User";paused;fi
	Script_Temp_Dir="/home/Dice"
	if [ "$Root_Test" != "root" ]; then clear; echo -e "\033[1;97;41mroot privileges required! Run with sudo${STD}"; exit 255;fi
	if [ ! -d "${Script_Temp_Dir}/${Main_User}" ]; then
		mkdir -p "${Script_Temp_Dir}/${Main_User}";
	fi
	Config_File="${Script_Temp_Dir}/${Main_User}/User_Config_File"
	Less_Volatile_Temp_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Less_Volatile_Temp_File-${StartTime}"
	Less_Volatile_Temp_File2="${Script_Temp_Dir}/${Main_User}/Dice_Script_Less_Volatile_Temp_File2-${StartTime}"
	Temp_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Temp_File-${StartTime}"
	Temp_Error_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Temp_Error_File-${StartTime}"
	Temp_Output_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Temp_Output_File-${StartTime}"
	Output_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Output_File-${StartTime}"
	Command_File="${Script_Temp_Dir}/${Main_User}/Dice_Script_Command_List-${StartTime}"
	Dice_File="${Script_Temp_Dir}/${Main_User}/Dice_File"
	Dice_Config_File="${Script_Temp_Dir}/${Main_User}/Dice_Config_File"
	Dice_Leaderboard="${Script_Temp_Dir}/Dice_Leaderboard"
	if [ ! -f "$Dice_Config_File" ]; then Create_Dice_Config;fi
	Read_Dice_Config;Update_Dice_Leaderboard
	if [ ! -f "$Config_File" ]; then Create_Config_File;fi;Read_Config_File
}

Create_Config_File(){
	echo "#   Script Config File" > $Config_File
	echo "#   NOTE: Spacing is Critical. There must be a space before and after the \"=\" sign" >> $Config_File
	echo "#         Manually Editing is probably a bad idea..." >> $Config_File
	echo "" >> $Config_File
	echo "Cust_Error = \\033[1;97;41m" >> $Config_File
	echo "Cust_Output = \\033[1;92;40m" >> $Config_File
	echo "Cust_Menu = \\033[1;94;40m" >> $Config_File
	echo "Remember_Colors = 0" >> $Config_File
	echo "Randomness = 0" >> $Config_File
	echo "Randomize = Cust_Output" >> $Config_File
	echo "Menu_Refresh_Rate = 500" >> $Config_File
	echo "sleep_max = 1000" >> $Config_File
}

Read_Config_File(){
	Read_Colors
	Randomness=$(cat $Config_File | grep "^Randomness" | awk '{ print $3 }')
	Randomize=$(cat $Config_File | grep "^Randomize" | awk '{$1=$2=""; print $0}')
	Color_Vars=($Randomize)
	Remember_Colors=$(cat $Config_File | grep "^Remember_Colors" | awk '{ print $3 }')
	Menu_Refresh_Rate=$(cat $Config_File | grep "^Menu_Refresh_Rate" | awk '{ print $3 }')
	sleep_max=$(cat $Config_File | grep "^sleep_max" | awk '{ print $3 }')
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
	if [ "$Opt_FG" == "FG_Bright" ]; then Seq_FG="90 97"; else Seq_FG="30 37"; fi
	if [ "$Opt_BG" == "BG_Bright" ]; then Seq_BG="100 107"; else Seq_BG="40 47"; fi
	for f in 29 $(seq $Seq_FG); do
		for b in 39 $(seq $Seq_BG); do
			FG="$f";BG="$b"
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
		if [ "$(shuf -i 0-1 -n 1)" -eq "0" ]; then Bold="1;";else unset Bold;fi
		if [ "$(shuf -i 0-1 -n 1)" -eq "0" ]; then Under="4;";else unset Under;fi
		if [ "$(shuf -i 0-1 -n 1)" -eq "0" ]; then FG=$(shuf -i 90-97 -n 1);else FG=$(shuf -i 30-37 -n 1);fi
		if [ "$(shuf -i 0-1 -n 1)" -eq "0" ]; then BG=$(shuf -i 100-107 -n 1);else BG=$(shuf -i 40-47 -n 1);fi
		while [ "$(( ($FG - $BG) % 10 ))" == "0" ]; do
			if [ "$(shuf -i 0-1 -n 1)" -eq "0" ]; then BG=$(shuf -i 100-107 -n 1);else BG=$(shuf -i 40-47 -n 1);fi
		done 
		code="\033[${Bold}${Under}${Blink}${FG}${Colon}${BG}m"
		sed -i "s/${Var} = .*/${Var} = \\$(echo "$code")/" $Config_File
	done
	Read_Colors
	unset Colon Bold Under FG BG code Dim Blink
}

pause(){
	read -p "Press [Enter] key to continue..." fackEnterKey
}

paused(){
	if [[ "$Dev_Mode" -eq "1" ]];then pause;fi
}


RM_Files(){
	unset Var_Check
	rm -f $Temp_File 2> /dev/null
	rm -f $Temp_Output_File 2> /dev/null
	rm -f $Output_File 2> /dev/null
}

Goodbye(){
	rm -f ${Script_Temp_Dir}/${Main_User}/Dice_Script_*
	rm -f .${Script_Temp_Dir}/${Main_User}/Dice_Script_*
	Phrase=("Goodbye" "Cash me outside. How bout dah" "Leaving so soon?" "It just wasn't meant to be" "Perception is reality" "Failure is not an option" "Whatcha gonna do tho?" "Hate to see you go" "Leaving so soon?" ":(" "Dont forget to go outside..." "Bye Bye" "Bye Now!" "Hasta la vista, baby" "May the Force be with you" "Houston, we have a problem" "Never trust a computer you can't throw out a window."  "We are all in the gutter, but some of us are looking at the stars." "Just keep swimming!" "Until next time my friend..." "Don't cry because it's over. Smile because it happened" "It ain't over 'til it's over" "Have a supercalifragilisticexpialidocious day!" "Have a Great Day!  :)" "Be miserable. Or motivate yourself. Whatever has to be done, it's always your choice" "  -------                  \n< Bye Now >                \n  -------                  \n        \   ^__^           \n         \  (oo)\_______   \n            (__)\       )\/\\n                ||---w-||  \n                ||     ||  ")
	Phrase_num=${#Phrase[@]}
	echo -e "${Cust_Error}${Phrase[$((RANDOM % Phrase_num))]}${STD}"
}

I_Wanna_Play_A_Game(){
	clear;Max_Val="30000";Selected="-1";num="0";Target=$((RANDOM % Max_Val)); Min_Val="0";while [ "$Selected" != "$Target" ];do unset Selected; while [ -z "$Selected" ]; do echo -e "Guess a Number between ${Cust_Menu}$Min_Val${STD} - ${Cust_Menu}$Max_Val${STD}   ";read -p "" Selected;if ! [[ $Selected == +([0-9]) ]]; then unset Selected; echo Please Define a Positive Integer; fi;done;if [[ "$Selected" -ge "$Max_Val" ]] || [[ "$Selected" -le "$Min_Val" ]]; then echo -e "${Cust_Error}Outside of Range${STD}  ${Cust_Menu}( $Min_Val - $Max_Val )${STD}";else num=$(( $num + 1 ));if [ "$Selected" -lt "$Target" ]; then echo -e "${Cust_Menu}${num}${STD}:  ${Cust_Output}Guess Higher...${STD}"; Min_Val=$Selected; fi;if [ "$Selected" -gt "$Target" ]; then echo -e "${Cust_Menu}${num}${STD}:  ${Cust_Output}Guess Lower...${STD}"; Max_Val=$Selected; fi;if [ "$Selected" -eq "$Target" ]; then echo -e "${Cust_Output}You got the answer in ${Cust_Menu}$num${Cust_Output} guesses\n\n${Cust_Error}Now Get Back To Work!${STD}"; pause > /dev/null; fi;fi;if [ "$Selected" -eq "42" ]; then clear; echo -e "${Cust_Error}The Answear to Life, the Universe, and Everything!\n${Cust_Output}CONGRATULATIONS!!!!!!!!!!!!${STD}";Selected=$Target;pause > /dev/null;fi;done;unset Max_Val Selected num Target Min_Val
}

Read_Dice_Config(){
	Points=$(cat $Dice_Config_File | grep "^Points" | awk '{ print $3 }')
	Dice_Num=$(cat $Dice_Config_File | grep "^Dice_Num" | awk '{ print $3 }')
	Auto_Roll=$(cat $Dice_Config_File | grep "^Auto_Roll" | awk '{ print $3 }')
	Menu_Refresh_Rate=$(cat $Dice_Config_File | grep "^Menu_Refresh_Rate" | awk '{ print $3 }')
	Show_Leaderboard=$(cat $Dice_Config_File | grep "^Show_Leaderboard" | awk '{ print $3 }')
	sleep_max=$(cat $Dice_Config_File | grep "^sleep_max =" | awk '{ print $3 }')
	sleep_max_Cost=$(cat $Dice_Config_File | grep "^sleep_max_Cost" | awk '{ print $3 }')
	Max_Idle_Spins=$(cat $Dice_Config_File | grep "^Max_Idle_Spins =" | awk '{ print $3 }')
	Max_Idle_Spins_Cost=$(cat $Dice_Config_File | grep "^Max_Idle_Spins_Cost =" | awk '{ print $3 }')
	Roll_Timeout=$(cat $Dice_Config_File | grep "^Roll_Timeout =" | awk '{ print $3 }')
	Roll_Timeout_Cost=$(cat $Dice_Config_File | grep "^Roll_Timeout_Cost" | awk '{ print $3 }')
	Spins_Until_Save=$(cat $Dice_Config_File | grep "^Spins_Until_Save =" | awk '{ print $3 }')
	Dice1_LVL=$(cat $Dice_Config_File | grep "^Dice1_LVL" | awk '{ print $3 }')
	Dice1_Cost=$(cat $Dice_Config_File | grep "^Dice1_Cost" | awk '{ print $3 }')
	Dice1_Base=$(cat $Dice_Config_File | grep "^Dice1_Base" | awk '{ print $3 }')
	Dice1_Prestige=$(cat $Dice_Config_File | grep "^Dice1_Prestige" | awk '{ print $3 }')
	Dice2_LVL=$(cat $Dice_Config_File | grep "^Dice2_LVL" | awk '{ print $3 }')
	Dice2_Cost=$(cat $Dice_Config_File | grep "^Dice2_Cost" | awk '{ print $3 }')
	Dice2_Base=$(cat $Dice_Config_File | grep "^Dice2_Base" | awk '{ print $3 }')
	Dice2_Prestige=$(cat $Dice_Config_File | grep "^Dice2_Prestige" | awk '{ print $3 }')
	Dice3_LVL=$(cat $Dice_Config_File | grep "^Dice3_LVL" | awk '{ print $3 }')
	Dice3_Cost=$(cat $Dice_Config_File | grep "^Dice3_Cost" | awk '{ print $3 }')
	Dice3_Base=$(cat $Dice_Config_File | grep "^Dice3_Base" | awk '{ print $3 }')
	Dice3_Prestige=$(cat $Dice_Config_File | grep "^Dice3_Prestige" | awk '{ print $3 }')
	Dice4_LVL=$(cat $Dice_Config_File | grep "^Dice4_LVL" | awk '{ print $3 }')
	Dice4_Cost=$(cat $Dice_Config_File | grep "^Dice4_Cost" | awk '{ print $3 }')
	Dice4_Base=$(cat $Dice_Config_File | grep "^Dice4_Base" | awk '{ print $3 }')
	Dice4_Prestige=$(cat $Dice_Config_File | grep "^Dice4_Prestige" | awk '{ print $3 }')
	Dice5_LVL=$(cat $Dice_Config_File | grep "^Dice5_LVL" | awk '{ print $3 }')
	Dice5_Cost=$(cat $Dice_Config_File | grep "^Dice5_Cost" | awk '{ print $3 }')
	Dice5_Base=$(cat $Dice_Config_File | grep "^Dice5_Base" | awk '{ print $3 }')
	Dice5_Prestige=$(cat $Dice_Config_File | grep "^Dice5_Prestige" | awk '{ print $3 }')
	None_MP=$(cat $Dice_Config_File | grep "^None_MP =" | awk '{ print $3 }')
	None_MP_Base=$(cat $Dice_Config_File | grep "^None_MP_Base =" | awk '{ print $3 }')
	None_MP_LVL=$(cat $Dice_Config_File | grep "^None_MP_LVL =" | awk '{ print $3 }')
	None_MP_Cost=$(cat $Dice_Config_File | grep "^None_MP_Cost =" | awk '{ print $3 }')
	Pair_MP=$(cat $Dice_Config_File | grep "^Pair_MP =" | awk '{ print $3 }')
	Pair_MP_Base=$(cat $Dice_Config_File | grep "^Pair_MP_Base =" | awk '{ print $3 }')
	Pair_MP_LVL=$(cat $Dice_Config_File | grep "^Pair_MP_LVL =" | awk '{ print $3 }')
	Pair_MP_Cost=$(cat $Dice_Config_File | grep "^Pair_MP_Cost" | awk '{ print $3 }')
	Trip_MP=$(cat $Dice_Config_File | grep "^Trip_MP =" | awk '{ print $3 }')
	Trip_MP_Base=$(cat $Dice_Config_File | grep "^Trip_MP_Base =" | awk '{ print $3 }')
	Trip_MP_LVL=$(cat $Dice_Config_File | grep "^Trip_MP_LVL =" | awk '{ print $3 }')
	Trip_MP_Cost=$(cat $Dice_Config_File | grep "^Trip_MP_Cost" | awk '{ print $3 }')
	Two_Pair_MP=$(cat $Dice_Config_File | grep "^Two_Pair_MP =" | awk '{ print $3 }')
	Two_Pair_MP_Base=$(cat $Dice_Config_File | grep "^Two_Pair_MP_Base =" | awk '{ print $3 }')
	Two_Pair_MP_LVL=$(cat $Dice_Config_File | grep "^Two_Pair_MP_LVL =" | awk '{ print $3 }')
	Two_Pair_MP_Cost=$(cat $Dice_Config_File | grep "^Two_Pair_MP_Cost" | awk '{ print $3 }')
	Four_MP=$(cat $Dice_Config_File | grep "^Four_MP =" | awk '{ print $3 }')
	Four_MP_Base=$(cat $Dice_Config_File | grep "^Four_MP_Base =" | awk '{ print $3 }')
	Four_MP_LVL=$(cat $Dice_Config_File | grep "^Four_MP_LVL =" | awk '{ print $3 }')
	Four_MP_Cost=$(cat $Dice_Config_File | grep "^Four_MP_Cost" | awk '{ print $3 }')
	Straight_MP=$(cat $Dice_Config_File | grep "^Straight_MP =" | awk '{ print $3 }')
	Straight_MP_Base=$(cat $Dice_Config_File | grep "^Straight_MP_Base =" | awk '{ print $3 }')
	Straight_MP_LVL=$(cat $Dice_Config_File | grep "^Straight_MP_LVL =" | awk '{ print $3 }')
	Straight_MP_Cost=$(cat $Dice_Config_File | grep "^Straight_MP_Cost" | awk '{ print $3 }')
	Full_House_MP=$(cat $Dice_Config_File | grep "^Full_House_MP =" | awk '{ print $3 }')
	Full_House_MP_Base=$(cat $Dice_Config_File | grep "^Full_House_MP_Base =" | awk '{ print $3 }')
	Full_House_MP_LVL=$(cat $Dice_Config_File | grep "^Full_House_MP_LVL =" | awk '{ print $3 }')
	Full_House_MP_Cost=$(cat $Dice_Config_File | grep "^Full_House_MP_Cost" | awk '{ print $3 }')
	Five_MP=$(cat $Dice_Config_File | grep "^Five_MP =" | awk '{ print $3 }')
	Five_MP_Base=$(cat $Dice_Config_File | grep "^Five_MP_Base =" | awk '{ print $3 }')
	Five_MP_LVL=$(cat $Dice_Config_File | grep "^Five_MP_LVL =" | awk '{ print $3 }')
	Five_MP_Cost=$(cat $Dice_Config_File | grep "^Five_MP_Cost" | awk '{ print $3 }')
	Temp_Points=0
	Temp_LB_Points=0
	unset LB_Points
}

Create_Dice_Config(){
	echo "#   Script Dice Config File" > $Dice_Config_File
	echo "#   NOTE: Spacing is Critical. There must be a space before and after the \"=\" sign" >> $Dice_Config_File
	echo "#         Manually Editing is probably a bad idea...  You shouldn't cheat anyways..." >> $Dice_Config_File
	echo "" >> $Dice_Config_File
	echo "Points = 0" >> $Dice_Config_File
	echo "Dice_Num = 1" >> $Dice_Config_File
	echo "Auto_Roll = 0" >> $Dice_Config_File
	echo "Menu_Refresh_Rate = 7500" >> $Dice_Config_File
	echo "Show_Leaderboard = 1" >> $Dice_Config_File
	echo "sleep_max = 15000" >> $Dice_Config_File
	echo "sleep_max_Cost = 5000" >> $Dice_Config_File
	echo "Max_Idle_Spins = 100" >> $Dice_Config_File
	echo "Max_Idle_Spins_Cost = 2000" >> $Dice_Config_File
	echo "Roll_Timeout = 3000" >> $Dice_Config_File
	echo "Roll_Timeout_Cost = 100" >> $Dice_Config_File
	echo "Spins_Until_Save = 10" >> $Dice_Config_File
	echo "Dice1_LVL = 1" >> $Dice_Config_File
	echo "Dice2_LVL = 0" >> $Dice_Config_File
	echo "Dice3_LVL = 0" >> $Dice_Config_File
	echo "Dice4_LVL = 0" >> $Dice_Config_File
	echo "Dice5_LVL = 0" >> $Dice_Config_File
	echo "Dice1_Cost = 10" >> $Dice_Config_File
	echo "Dice2_Cost = 100" >> $Dice_Config_File
	echo "Dice3_Cost = 1000" >> $Dice_Config_File
	echo "Dice4_Cost = 10000" >> $Dice_Config_File
	echo "Dice5_Cost = 100000" >> $Dice_Config_File
	echo "Dice1_Base = 1" >> $Dice_Config_File
	echo "Dice2_Base = 2" >> $Dice_Config_File
	echo "Dice3_Base = 4" >> $Dice_Config_File
	echo "Dice4_Base = 8" >> $Dice_Config_File
	echo "Dice5_Base = 16" >> $Dice_Config_File
	echo "Dice1_Prestige = 0" >> $Dice_Config_File
	echo "Dice2_Prestige = 0" >> $Dice_Config_File
	echo "Dice3_Prestige = 0" >> $Dice_Config_File
	echo "Dice4_Prestige = 0" >> $Dice_Config_File
	echo "Dice5_Prestige = 0" >> $Dice_Config_File
	echo "None_MP = 1" >> $Dice_Config_File
	echo "None_MP_Cost = 10" >> $Dice_Config_File
	echo "None_MP_Base = 0.1" >> $Dice_Config_File
	echo "None_MP_LVL = 10" >> $Dice_Config_File
	echo "Pair_MP = 2.2" >> $Dice_Config_File
	echo "Pair_MP_Cost = 50" >> $Dice_Config_File
	echo "Pair_MP_Base = 0.22" >> $Dice_Config_File
	echo "Pair_MP_LVL = 10" >> $Dice_Config_File
	echo "Trip_MP = 7.7" >> $Dice_Config_File
	echo "Trip_MP_Cost = 50" >> $Dice_Config_File
	echo "Trip_MP_Base = 0.77" >> $Dice_Config_File
	echo "Trip_MP_LVL = 10" >> $Dice_Config_File
	echo "Two_Pair_MP = 5.5" >> $Dice_Config_File
	echo "Two_Pair_MP_Cost = 50" >> $Dice_Config_File
	echo "Two_Pair_MP_Base = 0.55" >> $Dice_Config_File
	echo "Two_Pair_MP_LVL = 10" >> $Dice_Config_File
	echo "Four_MP = 66" >> $Dice_Config_File
	echo "Four_MP_Cost = 50" >> $Dice_Config_File
	echo "Four_MP_Base = 6.6" >> $Dice_Config_File
	echo "Four_MP_LVL = 10" >> $Dice_Config_File
	echo "Straight_MP = 22" >> $Dice_Config_File
	echo "Straight_MP_Cost = 50" >> $Dice_Config_File
	echo "Straight_MP_Base = 2.2" >> $Dice_Config_File
	echo "Straight_MP_LVL = 10" >> $Dice_Config_File
	echo "Full_House_MP = 33" >> $Dice_Config_File
	echo "Full_House_MP_Cost = 50" >> $Dice_Config_File
	echo "Full_House_MP_Base = 3.3" >> $Dice_Config_File
	echo "Full_House_MP_LVL = 10" >> $Dice_Config_File
	echo "Five_MP = 1650" >> $Dice_Config_File
	echo "Five_MP_Cost = 50" >> $Dice_Config_File
	echo "Five_MP_Base = 165.0" >> $Dice_Config_File
	echo "Five_MP_LVL = 10" >> $Dice_Config_File
}

G_Dice_Stats(){
	Dice_Stat_Total_Sum=0;Dice_Stat_Most_Rolled_Count=0;Dice_Stat_Least_Rolled_Count=99999999999
	if [[ "$choice" =~ [[:upper:]] ]]; then
		Rolls=$(cat $Dice_File | tail -n 1000 | wc -l)
	else
		Rolls="1"
	fi
	Dice_Stat=$(cat $Dice_File | tail -n $Rolls | awk '{$NF=""; print $0}' | sed 's/ $//g' | sed 's/ /\n/g')
	One_Percent=$(( $Rolls / 100 ))
	Full_House_Count=0;Triple_Count=0;Two_Pair_Count=0;Pair_Count=0;Four_Count=0;Five_Count=0;None_Count=0;count1=0;count2=0;Min_Points=984467440737095516;Max_Points=-1;Total_Points=0
	while read -r line; do
		count1=$(( $count1 + 1 ))
		if [[ "$count1" -eq "$One_Percent" ]];then count2=$(( $count2 + 1 ));count1=0;clear;echo "Gathering Roll Combo Stats for the last $Rolls rolls:  $count2 Percent Complete";fi
		Last_Roll=$(echo "$line" | awk '{$NF=""; print $0}' | sed 's/\ /\n/g' | sort -n)
		Last_Points=$(echo "$line" | awk '{print $NF}')
		Most=-1;Second_Most=0
		for i in $(seq 6);do
			Dice_Stat_i_Count=$(echo "$Last_Roll" | grep ^$i | wc -l)
			if [[ "$Dice_Stat_i_Count" -ge "$Most" ]];then
				Second_Most=$Most
				Most=$Dice_Stat_i_Count
			elif [[ "$Dice_Stat_i_Count" -lt "$Most" ]] && [[ "$Dice_Stat_i_Count" -gt "$Second_Most" ]];then
				Second_Most=$Dice_Stat_i_Count
			fi
		done
		if [[ "$Most" -eq "3" ]];then
			if [[ "$Second_Most" -eq "2" ]];then Full_House_Count=$(( $Full_House_Count + 1 ))
			else Triple_Count=$(( $Triple_Count + 1 ))
			fi
		elif [[ "$Most" -eq "2" ]];then
			if [[ "$Second_Most" -eq "2" ]];then Two_Pair_Count=$(( $Two_Pair_Count + 1 ))
			else Pair_Count=$(( $Pair_Count + 1 ))
			fi
		elif [[ "$Most" -eq "4" ]];then Four_Count=$(( $Four_Count + 1 ))
		elif [[ "$Most" -eq "5" ]];then Five_Count=$(( $Five_Count + 1 ))
		else None_Count=$(( $None_Count + 1 ))
		fi
		if [[ "$(echo "$Last_Points - $Max_Points" | bc -l)" == +([0-9]) ]];then Max_Points=$Last_Points;fi
		if [[ "$(echo "$Min_Points - $Last_Points" | bc -l)" == +([0-9]) ]];then Min_Points=$Last_Points;fi
		Total_Points=$(echo "$Total_Points + $Last_Points" | bc -l)
	done <<< "$(cat $Dice_File | tail -n $Rolls | sed 's/ $//g')"
	clear
	echo -e "Full Houses       $Full_House_Count"
	echo -e "Triples           $Triple_Count"
	echo -e "Two Pairs         $Two_Pair_Count"
	echo -e "Pairs             $Pair_Count"
	echo -e "Fours             $Four_Count"
	echo -e "Fives             $Five_Count"
	echo -e "No Combo          $None_Count\n\n"
	Dice_Stat_Total_Die_Rolled=$(echo "$Dice_Stat" | wc -l)
	for i in $(seq 6);do
		Dice_Stat_i_Count=$(echo "$Dice_Stat" | sort | grep ^$i | wc -l)
		echo "Times Rolling a $i   $Dice_Stat_i_Count" >> $Temp_File
		Dice_Stat_Total_Sum=$(echo "$Dice_Stat_Total_Sum + ( $Dice_Stat_i_Count * $i )" | bc -l)
		if [[ "$Dice_Stat_i_Count" -gt "$Dice_Stat_Most_Rolled_Count" ]];then
			Dice_Stat_Most_Rolled=$i
			Dice_Stat_Most_Rolled_Count=$Dice_Stat_i_Count
		fi
		if [[ "$Dice_Stat_i_Count" -lt "$Dice_Stat_Least_Rolled_Count" ]];then
			Dice_Stat_Least_Rolled=$i
			Dice_Stat_Least_Rolled_Count=$Dice_Stat_i_Count
		fi
	done
	Avg_Roll=$(echo "$Dice_Stat_Total_Sum / $Dice_Stat_Total_Die_Rolled" | bc -l)
	echo -e "Total Dice Rolled   $Dice_Stat_Total_Die_Rolled   individual die rolled for a total of  $Dice_Stat_Total_Sum"
	echo -e "Average Rolled      $Avg_Roll"
	cat $Temp_File
	echo -e "\nDie Least Rolled   $Dice_Stat_Least_Rolled  --  $Dice_Stat_Least_Rolled_Count Times"
	echo -e "Die Most  Rolled   $Dice_Stat_Most_Rolled  --  $Dice_Stat_Most_Rolled_Count Times"
	echo -e "\nPoints Total      $Total_Points"
	echo -e "Points Minimum    $Min_Points"
	echo -e "Points Maximum    $Max_Points"
	echo -e "Points Average    $(echo "$Total_Points / $Rolls" | bc -l)"
	pause
}

Save_Dice_Config(){
	sed -i "s/Points = .*/Points = $(echo $Points)/" $Dice_Config_File
	sed -i "s/Dice_Num = .*/Dice_Num = $(echo $Dice_Num)/" $Dice_Config_File
	sed -i "s/Auto_Roll = .*/Auto_Roll = $(echo $Auto_Roll)/" $Dice_Config_File
	sed -i "s/Menu_Refresh_Rate = .*/Menu_Refresh_Rate = $(echo $Menu_Refresh_Rate)/" $Dice_Config_File
	sed -i "s/Show_Leaderboard = .*/Show_Leaderboard = $(echo $Show_Leaderboard)/" $Dice_Config_File
	sed -i "s/sleep_max = .*/sleep_max = $(echo $sleep_max)/" $Dice_Config_File
	sed -i "s/sleep_max_Cost = .*/sleep_max_Cost = $(echo $sleep_max_Cost)/" $Dice_Config_File
	sed -i "s/Max_Idle_Spins = .*/Max_Idle_Spins = $(echo $Max_Idle_Spins)/" $Dice_Config_File
	sed -i "s/Max_Idle_Spins_Cost = .*/Max_Idle_Spins_Cost = $(echo $Max_Idle_Spins_Cost)/" $Dice_Config_File
	sed -i "s/Roll_Timeout = .*/Roll_Timeout = $(echo $Roll_Timeout)/" $Dice_Config_File
	sed -i "s/Roll_Timeout_Cost = .*/Roll_Timeout_Cost = $(echo $Roll_Timeout_Cost)/" $Dice_Config_File
	sed -i "s/Spins_Until_Save = .*/Spins_Until_Save = $(echo $Spins_Until_Save)/" $Dice_Config_File
	sed -i "s/Dice1_LVL = .*/Dice1_LVL = $(echo $Dice1_LVL)/" $Dice_Config_File
	sed -i "s/Dice2_LVL = .*/Dice2_LVL = $(echo $Dice2_LVL)/" $Dice_Config_File
	sed -i "s/Dice3_LVL = .*/Dice3_LVL = $(echo $Dice3_LVL)/" $Dice_Config_File
	sed -i "s/Dice4_LVL = .*/Dice4_LVL = $(echo $Dice4_LVL)/" $Dice_Config_File
	sed -i "s/Dice5_LVL = .*/Dice5_LVL = $(echo $Dice5_LVL)/" $Dice_Config_File
	sed -i "s/Dice1_Cost = .*/Dice1_Cost = $(echo $Dice1_Cost)/" $Dice_Config_File
	sed -i "s/Dice2_Cost = .*/Dice2_Cost = $(echo $Dice2_Cost)/" $Dice_Config_File
	sed -i "s/Dice3_Cost = .*/Dice3_Cost = $(echo $Dice3_Cost)/" $Dice_Config_File
	sed -i "s/Dice4_Cost = .*/Dice4_Cost = $(echo $Dice4_Cost)/" $Dice_Config_File
	sed -i "s/Dice5_Cost = .*/Dice5_Cost = $(echo $Dice5_Cost)/" $Dice_Config_File
	sed -i "s/Dice1_Base = .*/Dice1_Base = $(echo $Dice1_Base)/" $Dice_Config_File
	sed -i "s/Dice2_Base = .*/Dice2_Base = $(echo $Dice2_Base)/" $Dice_Config_File
	sed -i "s/Dice3_Base = .*/Dice3_Base = $(echo $Dice3_Base)/" $Dice_Config_File
	sed -i "s/Dice4_Base = .*/Dice4_Base = $(echo $Dice4_Base)/" $Dice_Config_File
	sed -i "s/Dice5_Base = .*/Dice5_Base = $(echo $Dice5_Base)/" $Dice_Config_File
	sed -i "s/Dice1_Prestige = .*/Dice1_Prestige = $(echo $Dice1_Prestige)/" $Dice_Config_File
	sed -i "s/Dice2_Prestige = .*/Dice2_Prestige = $(echo $Dice2_Prestige)/" $Dice_Config_File
	sed -i "s/Dice3_Prestige = .*/Dice3_Prestige = $(echo $Dice3_Prestige)/" $Dice_Config_File
	sed -i "s/Dice4_Prestige = .*/Dice4_Prestige = $(echo $Dice4_Prestige)/" $Dice_Config_File
	sed -i "s/Dice5_Prestige = .*/Dice5_Prestige = $(echo $Dice5_Prestige)/" $Dice_Config_File
	sed -i "s/None_MP = .*/None_MP = $(echo $None_MP)/" $Dice_Config_File
	sed -i "s/None_MP_Cost = .*/None_MP_Cost = $(echo $None_MP_Cost)/" $Dice_Config_File
	sed -i "s/None_MP_LVL = .*/None_MP_LVL = $(echo $None_MP_LVL)/" $Dice_Config_File
	sed -i "s/None_MP_Base = .*/None_MP_Base = $(echo $None_MP_Base)/" $Dice_Config_File
	sed -i "s/Pair_MP = .*/Pair_MP = $(echo $Pair_MP)/" $Dice_Config_File
	sed -i "s/Pair_MP_Cost = .*/Pair_MP_Cost = $(echo $Pair_MP_Cost)/" $Dice_Config_File
	sed -i "s/Pair_MP_LVL = .*/Pair_MP_LVL = $(echo $Pair_MP_LVL)/" $Dice_Config_File
	sed -i "s/Pair_MP_Base = .*/Pair_MP_Base = $(echo $Pair_MP_Base)/" $Dice_Config_File
	sed -i "s/Trip_MP = .*/Trip_MP = $(echo $Trip_MP)/" $Dice_Config_File
	sed -i "s/Trip_MP_Cost = .*/Trip_MP_Cost = $(echo $Trip_MP_Cost)/" $Dice_Config_File
	sed -i "s/Trip_MP_LVL = .*/Trip_MP_LVL = $(echo $Trip_MP_LVL)/" $Dice_Config_File
	sed -i "s/Trip_MP_Base = .*/Trip_MP_Base = $(echo $Trip_MP_Base)/" $Dice_Config_File
	sed -i "s/Two_Pair_MP = .*/Two_Pair_MP = $(echo $Two_Pair_MP)/" $Dice_Config_File
	sed -i "s/Two_Pair_MP_Cost = .*/Two_Pair_MP_Cost = $(echo $Two_Pair_MP_Cost)/" $Dice_Config_File
	sed -i "s/Two_Pair_MP_LVL = .*/Two_Pair_MP_LVL = $(echo $Two_Pair_MP_LVL)/" $Dice_Config_File
	sed -i "s/Two_Pair_MP_Base = .*/Two_Pair_MP_Base = $(echo $Two_Pair_MP_Base)/" $Dice_Config_File
	sed -i "s/Four_MP = .*/Four_MP = $(echo $Four_MP)/" $Dice_Config_File
	sed -i "s/Four_MP_Cost = .*/Four_MP_Cost = $(echo $Four_MP_Cost)/" $Dice_Config_File
	sed -i "s/Four_MP_LVL = .*/Four_MP_LVL = $(echo $Four_MP_LVL)/" $Dice_Config_File
	sed -i "s/Four_MP_Base = .*/Four_MP_Base = $(echo $Four_MP_Base)/" $Dice_Config_File
	sed -i "s/Straight_MP = .*/Straight_MP = $(echo $Straight_MP)/" $Dice_Config_File
	sed -i "s/Straight_MP_Cost = .*/Straight_MP_Cost = $(echo $Straight_MP_Cost)/" $Dice_Config_File
	sed -i "s/Straight_MP_LVL = .*/Straight_MP_LVL = $(echo $Straight_MP_LVL)/" $Dice_Config_File
	sed -i "s/Straight_MP_Base = .*/Straight_MP_Base = $(echo $Straight_MP_Base)/" $Dice_Config_File
	sed -i "s/Full_House_MP = .*/Full_House_MP = $(echo $Full_House_MP)/" $Dice_Config_File
	sed -i "s/Full_House_MP_Cost = .*/Full_House_MP_Cost = $(echo $Full_House_MP_Cost)/" $Dice_Config_File
	sed -i "s/Full_House_MP_LVL = .*/Full_House_MP_LVL = $(echo $Full_House_MP_LVL)/" $Dice_Config_File
	sed -i "s/Full_House_MP_Base = .*/Full_House_MP_Base = $(echo $Full_House_MP_Base)/" $Dice_Config_File
	sed -i "s/Five_MP = .*/Five_MP = $(echo $Five_MP)/" $Dice_Config_File
	sed -i "s/Five_MP_Cost = .*/Five_MP_Cost = $(echo $Five_MP_Cost)/" $Dice_Config_File
	sed -i "s/Five_MP_LVL = .*/Five_MP_LVL = $(echo $Five_MP_LVL)/" $Dice_Config_File
	sed -i "s/Five_MP_Base = .*/Five_MP_Base = $(echo $Five_MP_Base)/" $Dice_Config_File
}

Roll_Da_Dice(){
	for i in $(seq $Dice_Num);do echo -e -n "$(($RANDOM % 6 + 1)) " >> $Dice_File;done
	Last_Roll=$(cat $Dice_File | tail -n 1)
	Temp_Points=0
	echo "Rolled" > $Less_Volatile_Temp_File
	echo "Value" > $Less_Volatile_Temp_File2
	if [[ "$Dice1_LVL" -ge "1" ]];then num="1";Base=$Dice1_Base;LVL=$Dice1_LVL;Dice_Roll_Single_Die;fi
	if [[ "$Dice2_LVL" -ge "1" ]];then num="2";Base=$Dice2_Base;LVL=$Dice2_LVL;Dice_Roll_Single_Die;fi
	if [[ "$Dice3_LVL" -ge "1" ]];then num="3";Base=$Dice3_Base;LVL=$Dice3_LVL;Dice_Roll_Single_Die;fi
	if [[ "$Dice4_LVL" -ge "1" ]];then num="4";Base=$Dice4_Base;LVL=$Dice4_LVL;Dice_Roll_Single_Die;fi
	if [[ "$Dice5_LVL" -ge "1" ]];then num="5";Base=$Dice5_Base;LVL=$Dice5_LVL;Dice_Roll_Single_Die;fi
	Last_Roll=$(echo "$Last_Roll" | sed 's/\ /\n/g' | sort -n)
	Most=-1;Second_Most=0
	for i in $(seq 6);do
		Dice_Stat_i_Count=$(echo "$Last_Roll" | grep ^$i | wc -l)
		if [[ "$Dice_Stat_i_Count" -ge "$Most" ]];then
			Second_Most=$Most
			Most=$Dice_Stat_i_Count
		elif [[ "$Dice_Stat_i_Count" -lt "$Most" ]] && [[ "$Dice_Stat_i_Count" -gt "$Second_Most" ]];then
			Second_Most=$Dice_Stat_i_Count
		fi
	done
	unset Dice_Combo
	if [[ "$Most" -eq "3" ]];then
		if [[ "$Second_Most" -eq "2" ]];then Dice_Combo="Full House";Dice_Combo_MP=$(echo "$Full_House_MP_Base * $Full_House_MP_LVL" | bc -l)
		else Dice_Combo="Triple";Dice_Combo_MP=$(echo "$Trip_MP_Base * $Trip_MP_LVL" | bc -l)
		fi
	elif [[ "$Most" -eq "2" ]];then
		if [[ "$Second_Most" -eq "2" ]];then Dice_Combo="Two Pair";Dice_Combo_MP=$(echo "$Two_Pair_MP_Base * $Two_Pair_MP_LVL" | bc -l)
		else Dice_Combo="Pair";Dice_Combo_MP=$Pair_MP
		fi
	elif [[ "$Most" -eq "4" ]];then Dice_Combo="Four";Dice_Combo_MP=$Four_MP
	elif [[ "$Most" -eq "5" ]];then Dice_Combo="Five";Dice_Combo_MP=$Five_MP
	fi
	if [ -z "$Dice_Combo" ];then
		Last_Roll=$(echo "$Last_Roll" | sed ':a;N;$!ba;s/\n//g')
		if [[ "$Last_Roll" -eq "12345" ]] || [[ "$Last_Roll" -eq "23456" ]];then Dice_Combo="Straight";Dice_Combo_MP=$Straight_MP
		else Dice_Combo="No Combo";Dice_Combo_MP=$None_MP
		fi
	fi
	Last_Roll=$(echo "$Last_Roll")
	Temp_Points=$(echo "$Temp_Points * $Dice_Combo_MP" | bc -l | cut -d\. -f1 )
	Temp_LB_Points=$(echo "$Temp_LB_Points + $Temp_Points" | bc -l)
	Points=$(echo "$Points + $Temp_Points" | bc -l)
	echo "$Dice_Combo" >> $Less_Volatile_Temp_File
	echo "x$Dice_Combo_MP" >> $Less_Volatile_Temp_File2
	echo "Total" >> $Less_Volatile_Temp_File
	echo "$Temp_Points" >> $Less_Volatile_Temp_File2
	echo "$Temp_Points" >> $Dice_File
	Print_Dice_Menu
	echo -e "\nWaiting for $Roll_Timeout Milliseconds"
	sleep $(echo "$Roll_Timeout / 1000" | bc -l)
}

Update_Dice_Leaderboard(){
	sed -i -e :a -e '$q;N;1001,$D;ba' $Dice_File
	LB_Points=$(cat $Dice_Leaderboard | grep "^${Main_User}" | awk '{ print $3 }')
	if [ -z $LB_Points ];then 
		LB_Points=0
		echo "${Main_User} - $LB_Points" >> $Dice_Leaderboard
	fi
	if [ ! -z "$Temp_LB_Points" ];then
		LB_Points=$(echo "$LB_Points + $Temp_LB_Points" | bc -l)
	fi
	Temp_LB_Points=0
	sed -i "s/${Main_User}.*/${Main_User} - $(echo $LB_Points)/" $Dice_Leaderboard
	cat $Dice_Leaderboard | sort -nrk3 > $Temp_File
	cat $Temp_File > $Dice_Leaderboard
}

Dice_Roll_Single_Die(){
	Roll=$(echo "$Last_Roll" | sed "s/ //g" | sed "s/.//$(( $num + 1 ))g" | rev | sed "s/.//2g")
	Value=$(echo "$Roll * $Base * $LVL" | bc -l | cut -d\. -f1)
	echo -e "$Roll" >> $Less_Volatile_Temp_File
	echo -e "$Value" >> $Less_Volatile_Temp_File2
	Temp_Points=$(( $Temp_Points + $Value ))
}

Dice_Upgrade_Die(){
	Points=$(echo "$Points - $Cost" | bc -l)
	if [[ "$LVL" -eq "0" ]];then
		Dice_Num=$(( $Dice_Num + 1 ))
	fi
	LVL=$(( $LVL + 1 ))
	if [[ "$(( $LVL % 100 ))" -eq "0" ]];then
		Prestige=$(( $Prestige + 1 ))
		Base=$(echo "$Base * $LVL" | bc -l)
		LVL=1
		if [[ "$Prestige" -eq "1" ]];then Cost=100000;fi
		if [[ "$Prestige" -eq "2" ]];then Cost=4000000000;fi
		if [[ "$Prestige" -eq "3" ]];then Cost=12000000000000;fi
		if [[ "$Prestige" -eq "4" ]];then Cost=30000000000000000;fi
		if [[ "$Prestige" -eq "5" ]];then Cost=75000000000000000000;fi
		if [[ "$Prestige" -eq "6" ]];then Cost=180000000000000000000000;fi
		if [[ "$Prestige" -eq "7" ]];then Cost=370000000000000000000000000;fi
		if [[ "$Prestige" -eq "8" ]];then Cost=900000000000000000000000000000;fi
		Cost=$( echo "$Cost * 10 ^ $Die" | bc -l)
	else
		echo "$Cost * 1.08" | bc -l > $Temp_File
		int=$(cat $Temp_File | cut -d\. -f1)
		rem=$(cat $Temp_File | cut -d\. -f2 | sed "s/.//2g")
		if [[ "$rem" -ge "5" ]];then
			Cost=$(echo "$int + 1" | bc -l)
		else
			Cost=$int
		fi
	fi
}

Dice_Upgrade_MP(){
	Points=$(echo "$Points - $Cost" | bc -l)
	LVL=$(( $LVL + 1 ))
	Cost=$(echo "$Cost * 2.35" | bc -l | cut -d\. -f1)
}

Dice_Var_Dump(){
	echo -e "	Points = $Points
	Dice_Num = $Dice_Num
	Auto_Roll = $Auto_Roll
	Menu_Refresh_Rate = $Menu_Refresh_Rate
	Roll_Timeout = $Roll_Timeout
	Roll_Timeout_Cost = $Roll_Timeout_Cost
	Dice1_LVL = $Dice1_LVL
	Dice2_LVL = $Dice2_LVL
	Dice3_LVL = $Dice3_LVL
	Dice4_LVL = $Dice4_LVL
	Dice5_LVL = $Dice5_LVL
	Dice1_Cost = $Dice1_Cost
	Dice2_Cost = $Dice2_Cost
	Dice3_Cost = $Dice3_Cost
	Dice4_Cost = $Dice4_Cost
	Dice5_Cost = $Dice5_Cost
	Dice1_Base = $Dice1_Base
	Dice2_Base = $Dice2_Base
	Dice3_Base = $Dice3_Base
	Dice4_Base = $Dice4_Base
	Dice5_Base = $Dice5_Base
	Dice1_Prestige = $Dice1_Prestige
	Dice2_Prestige = $Dice2_Prestige
	Dice3_Prestige = $Dice3_Prestige
	Dice4_Prestige = $Dice4_Prestige
	Dice5_Prestige = $Dice5_Prestige
	None_MP = $None_MP
	None_MP_Cost = $None_MP_Cost
	None_MP_LVL = $None_MP_LVL
	None_MP_Base = $None_MP_Base
	Pair_MP = $Pair_MP
	Pair_MP_Cost = $Pair_MP_Cost
	Trip_MP = $Trip_MP
	Trip_MP_Cost = $Trip_MP_Cost
	Two_Pair_MP = $Two_Pair_MP
	Two_Pair_MP_Cost = $Two_Pair_MP_Cost
	Four_MP = $Four_MP
	Four_MP_Cost = $Four_MP_Cost
	Straight_MP = $Straight_MP
	Straight_MP_Cost = $Straight_MP_Cost
	Full_House_MP = $Full_House_MP
	Full_House_MP_LVL = $Full_House_MP_LVL
	Full_House_MP_Base = $Full_House_MP_Base
	Full_House_MP_Cost = $Full_House_MP_Cost
	Five_MP = $Five_MP
	Five_MP_Cost = $Five_MP_Cost" | sed 's/\t//g'
	pause
}

Menu_Timer(){
	unset choice
	if [ -z "$sleep_max" ];then sleep_max=1000;fi
	read_ms=$(echo "$Menu_Refresh_Rate / 1000" | bc -l)
	count="0"
	G_LMI
	read -t 0.001 -N 1000000	# Discard STDIN before reading
	while [[ -z "$choice" ]] && [[ "$count" -lt "$sleep_max" ]];do
		unset choice
		if [[ "${Menus[$LMI]}" == "Menu_Timer" ]] && [[ "${Menus[$S2LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$T2LMI]}" == "Print_"* ]];then
			${Menus[$T2LMI]}
		fi
		read -s -p "" -n 1 -t $read_ms choice
		count=$(($count+$Menu_Refresh_Rate))
	done
	if [[ "${Menus[$T2LMI]}" == "Print_Dice_Menu" ]]; then
		if [[ -z "$choice" ]];then
			if [[ "$Auto_Roll" -eq "1" ]];then
				if [[ "$dice_roll_count" -lt "$Max_Idle_Spins" ]];then
					dice_roll_count=$(( $dice_roll_count + 1 ))
					if [[ "$(( $dice_roll_count % $Spins_Until_Save ))" -eq "0" ]];then Save_Dice_Config;Update_Dice_Leaderboard;fi
					choice="@"
				fi
			fi
		else
			dice_roll_count=0
		fi
	fi
	unset Menus[${LMI}]
}

Print_Dice_Menu(){
	echo -e "${Cust_Output}Points:     $Points${STD}" > $Output_File
	echo -e "${Cust_Menu}/  Roll:       ROLL THE DICE!!!!!!!!!!${STD}" >> $Output_File
	if [[ "$(echo "$Points - $Dice1_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;
	else echo -e -n "${Cust_Error}" >> $Output_File;fi;
	echo -e "1  Upgrade Die #1   Prestige=$Dice1_Prestige  LVL=$Dice1_LVL  Multiplier=$(( $Dice1_Base * $Dice1_LVL ))  Cost=$Dice1_Cost${STD}" >> $Output_File
	if [[ "$(echo "$Points - $Dice2_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;
	else echo -e -n "${Cust_Error}" >> $Output_File;fi;
	echo -e "2  Upgrade Die #2   Prestige=$Dice2_Prestige  LVL=$Dice2_LVL  Multiplier=$(( $Dice2_Base * $Dice2_LVL ))  Cost=$Dice2_Cost${STD}" >> $Output_File
	if [[ "$(echo "$Points - $Dice3_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "3  Upgrade Die #3   Prestige=$Dice3_Prestige  LVL=$Dice3_LVL  Multiplier=$(( $Dice3_Base * $Dice3_LVL ))  Cost=$Dice3_Cost${STD}" >> $Output_File
	if [[ "$(echo "$Points - $Dice4_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "4  Upgrade Die #4   Prestige=$Dice4_Prestige  LVL=$Dice4_LVL  Multiplier=$(( $Dice4_Base * $Dice4_LVL ))  Cost=$Dice4_Cost${STD}" >> $Output_File
	if [[ "$(echo "$Points - $Dice5_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "5  Upgrade Die #5   Prestige=$Dice5_Prestige  LVL=$Dice5_LVL  Multiplier=$(( $Dice5_Base * $Dice5_LVL ))  Cost=$Dice5_Cost${STD}" >> $Output_File
	if [[ "$Dice_Num" -ge "2" ]];then if [[ "$(echo "$Points - $Pair_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "Q  Upgrade Pair Combo           LVL=$Pair_MP_LVL  Multiplier=$Pair_MP  Cost=$Pair_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "3" ]];then if [[ "$(echo "$Points - $Trip_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "W  Upgrade Triple Combo         LVL=$Trip_MP_LVL  Multiplier=$Trip_MP  Cost=$Trip_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "4" ]];then if [[ "$(echo "$Points - $Two_Pair_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "E  Upgrade Two Pair Combo       LVL=$Two_Pair_MP_LVL  Multiplier=$Two_Pair_MP  Cost=$Two_Pair_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "4" ]];then if [[ "$(echo "$Points - $Four_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "R  Upgrade Four Combo           LVL=$Four_MP_LVL  Multiplier=$Four_MP  Cost=$Four_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Straight_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "T  Upgrade Straight Combo       LVL=$Straight_MP_LVL  Multiplier=$Straight_MP  Cost=$Straight_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Full_House_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "Y  Upgrade Full House Combo     LVL=$Full_House_MP_LVL  Multiplier=$Full_House_MP  Cost=$Full_House_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Five_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "U  Upgrade Five Combo           LVL=$Five_MP_LVL  Multiplier=$Five_MP  Cost=$Five_MP_Cost${STD}" >> $Output_File;fi
	if [[ "$(echo "$Points - $None_MP_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "I  Upgrade No Match Combo       LVL=$None_MP_LVL  Multiplier=$None_MP  Cost=$None_MP_Cost${STD}" >> $Output_File
	if [[ "$Auto_Roll" -eq "0" ]];then if [[ "$(echo "$Points - 1000" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}"  >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi;echo -e "A  Unlock Auto Roll             Disabled  Cost=1000${STD}" >> $Output_File;fi
	if [[ "$(echo "$Points - $Roll_Timeout_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
	echo -e "L  Halve Roll Timeout Duration  $Roll_Timeout Milliseconds  Cost=$Roll_Timeout_Cost${STD}" >> $Output_File
	if [[ "$Auto_Roll" -eq "1" ]];then
		if [[ "$(echo "$Points - $sleep_max_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
		echo -e "K  Halve Auto Roll Duration     $sleep_max Milliseconds  Cost=$sleep_max_Cost${STD}" >> $Output_File
		if [[ "$(echo "$Points - $Max_Idle_Spins_Cost" | bc -l)" == +([0-9]) ]];then echo -e -n "${Cust_Output}" >> $Output_File;else echo -e -n "${Cust_Error}" >> $Output_File;fi
		echo -e "J  5x Idle Rolls       $Max_Idle_Spins Spins  Cost=$Max_Idle_Spins_Cost${STD}     ${Cust_Menu}$(( $Max_Idle_Spins - $dice_roll_count )) Spins Remain${STD}" >> $Output_File
	fi
	echo -e "S  Get:        Statistics     s for last roll     S for last 1000 rolls" >> $Output_File
	echo -e "(  ${Cust_Error}Reset:      All Progress${STD}" >> $Output_File
	echo -e ":  Var Dump" >> $Output_File
	echo -e ".  Toggle Show Leaderboard?" >> $Output_File
	echo -e "^  Switch User / Create New User" >> $Output_File
	if [[ "$Auto_Roll" -eq "1" ]];then echo -e "[  Set:        Save after every ${Cust_Menu}$Spins_Until_Save${STD} Auto Roll spins" >> $Output_File;fi
	echo -e "*  Save Current Progress Now" >> $Output_File
	clear
	if [ -f "$Less_Volatile_Temp_File2" ];then
		paste -s $Less_Volatile_Temp_File $Less_Volatile_Temp_File2 | column -ts $'\t'
	fi
	if [[ "$Show_Leaderboard" -eq "1" ]];then
		paste $Output_File $Dice_Leaderboard | awk -F '\t' '{ printf("%-120s%-40s\n", $1, $2) }' | awk -F '-' '{ printf("%-140s%s\n", $1, $2) }'
	else
		cat $Output_File
	fi
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Dice_Menu " ]];then
		Menus+=("Read_Menu_Dice_Menu" "Menu_Timer")
	fi
}

Read_Menu_Dice_Menu(){
	case $choice in
		\() read -n 1 -s -p "Do you want to reset all progress?   This cant be undone...    Y/n   " reset;if [[ "$reset" == "Y" ]] || [[ "$reset" == "y" ]];then Create_Dice_Config;Read_Dice_Config;rm -f $Dice_File 2> /dev/null;echo Game has been resest;else echo Reset Canceled;fi;pause;unset reset ;;
		1) if [[ "$(echo "$Points - $Dice1_Cost" | bc -l)" == +([0-9]) ]] && [[ "$Dice1_Prestige" -lt "9" ]];then Die=1;Prestige=$Dice1_Prestige;Base=$Dice1_Base;LVL=$Dice1_LVL;Cost=$Dice1_Cost;Dice_Upgrade_Die;Dice1_Prestige=$Prestige;Dice1_Base=$Base;Dice1_LVL=$LVL;Dice1_Cost=$Cost;fi ;;
		2) if [[ "$(echo "$Points - $Dice2_Cost" | bc -l)" == +([0-9]) ]] && [[ "$Dice2_Prestige" -lt "9" ]];then Die=2;Prestige=$Dice2_Prestige;Base=$Dice2_Base;LVL=$Dice2_LVL;Cost=$Dice2_Cost;Dice_Upgrade_Die;Dice2_Prestige=$Prestige;Dice2_Base=$Base;Dice2_LVL=$LVL;Dice2_Cost=$Cost;fi ;;
		3) if [[ "$(echo "$Points - $Dice3_Cost" | bc -l)" == +([0-9]) ]] && [[ "$Dice3_Prestige" -lt "9" ]];then Die=3;Prestige=$Dice3_Prestige;Base=$Dice3_Base;LVL=$Dice3_LVL;Cost=$Dice3_Cost;Dice_Upgrade_Die;Dice3_Prestige=$Prestige;Dice3_Base=$Base;Dice3_LVL=$LVL;Dice3_Cost=$Cost;fi ;;
		4) if [[ "$(echo "$Points - $Dice4_Cost" | bc -l)" == +([0-9]) ]] && [[ "$Dice4_Prestige" -lt "9" ]];then Die=4;Prestige=$Dice4_Prestige;Base=$Dice4_Base;LVL=$Dice4_LVL;Cost=$Dice4_Cost;Dice_Upgrade_Die;Dice4_Prestige=$Prestige;Dice4_Base=$Base;Dice4_LVL=$LVL;Dice4_Cost=$Cost;fi ;;
		5) if [[ "$(echo "$Points - $Dice5_Cost" | bc -l)" == +([0-9]) ]] && [[ "$Dice5_Prestige" -lt "9" ]];then Die=5;Prestige=$Dice5_Prestige;Base=$Dice5_Base;LVL=$Dice5_LVL;Cost=$Dice5_Cost;Dice_Upgrade_Die;Dice5_Prestige=$Prestige;Dice5_Base=$Base;Dice5_LVL=$LVL;Dice5_Cost=$Cost;fi ;;
		q|Q) if [[ "$Dice_Num" -ge "2" ]];then if [[ "$(echo "$Points - $Pair_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Pair_MP_LVL;Cost=$Pair_MP_Cost;Dice_Upgrade_MP;Pair_MP_LVL=$LVL;Pair_MP_Cost=$Cost;Pair_MP=$(echo "$Pair_MP_Base * $Pair_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		w|W) if [[ "$Dice_Num" -ge "3" ]];then if [[ "$(echo "$Points - $Trip_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Trip_MP_LVL;Cost=$Trip_MP_Cost;Dice_Upgrade_MP;Trip_MP_LVL=$LVL;Trip_MP_Cost=$Cost;Trip_MP=$(echo "$Trip_MP_Base * $Trip_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		e|E) if [[ "$Dice_Num" -ge "4" ]];then if [[ "$(echo "$Points - $Two_Pair_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Two_Pair_MP_LVL;Cost=$Two_Pair_MP_Cost;Dice_Upgrade_MP;Two_Pair_MP_LVL=$LVL;Two_Pair_MP_Cost=$Cost;Two_Pair_MP=$(echo "$Two_Pair_MP_Base * $Two_Pair_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		r|R) if [[ "$Dice_Num" -ge "4" ]];then if [[ "$(echo "$Points - $Four_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Four_MP_LVL;Cost=$Four_MP_Cost;Dice_Upgrade_MP;Four_MP_LVL=$LVL;Four_MP_Cost=$Cost;Four_MP=$(echo "$Four_MP_Base * $Four_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		t|T) if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Straight_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Straight_MP_LVL;Cost=$Straight_MP_Cost;Dice_Upgrade_MP;Straight_MP_LVL=$LVL;Straight_MP_Cost=$Cost;Straight_MP=$(echo "$Straight_MP_Base * $Straight_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		y|Y) if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Full_House_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Full_House_MP_LVL;Cost=$Full_House_MP_Cost;Dice_Upgrade_MP;Full_House_MP_LVL=$LVL;Full_House_MP_Cost=$Cost;Full_House_MP=$(echo "$Full_House_MP_Base * $Full_House_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		u|U) if [[ "$Dice_Num" -ge "5" ]];then if [[ "$(echo "$Points - $Five_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$Five_MP_LVL;Cost=$Five_MP_Cost;Dice_Upgrade_MP;Five_MP_LVL=$LVL;Five_MP_Cost=$Cost;Five_MP=$(echo "$Five_MP_Base * $Five_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi;fi ;;
		i|I) if [[ "$(echo "$Points - $None_MP_Cost" | bc -l)" == +([0-9]) ]];then LVL=$None_MP_LVL;Cost=$None_MP_Cost;Dice_Upgrade_MP;None_MP_LVL=$LVL;None_MP_Cost=$Cost;None_MP=$(echo "$None_MP_Base * $None_MP_LVL" | bc -l | grep -o '^[0-9]*\.[0-9]*');fi ;;
		a|A) if [[ "$(echo "$Points - 1000" | bc -l)" == +([0-9]) ]] && [[ "$Auto_Roll" -eq "0" ]];then Auto_Roll="1";Points=$(echo "$Points - 1000" | bc -l);fi ;;
		l|L) if [[ "$(echo "$Points - $Roll_Timeout_Cost" | bc -l)" == +([0-9]) ]];then Roll_Timeout=$(echo "$Roll_Timeout / 2" | bc -l | cut -d\. -f1);Points=$(echo "$Points - $Roll_Timeout_Cost" | bc -l);Roll_Timeout_Cost=$(echo "$Roll_Timeout_Cost * 1000" | bc -l);fi ;;
		k|K) if [[ "$Auto_Roll" -eq "1" ]];then if [[ "$(echo "$Points - $sleep_max_Cost" | bc -l)" == +([0-9]) ]];then sleep_max=$(echo "$sleep_max / 2" | bc -l | cut -d\. -f1);Menu_Refresh_Rate=$(( $sleep_max / 2 + 1 ));Points=$(echo "$Points - $sleep_max_Cost" | bc -l);sleep_max_Cost=$(echo "$sleep_max_Cost * 700" | bc -l);fi;fi ;;
		j|J) if [[ "$Auto_Roll" -eq "1" ]];then if [[ "$(echo "$Points - $Max_Idle_Spins_Cost" | bc -l)" == +([0-9]) ]];then Max_Idle_Spins=$(echo "$Max_Idle_Spins * 5" | bc -l);Points=$(echo "$Points - $Max_Idle_Spins_Cost" | bc -l);Max_Idle_Spins_Cost=$(echo "$Max_Idle_Spins_Cost * 30" | bc -l);fi;fi ;;
		/|\?) Roll_Da_Dice ;;
		\@) Roll_Da_Dice ;;
		s|S) G_Dice_Stats ;;
		:) Dice_Var_Dump ;;
		\^) ls -b1 $Script_Temp_Dir;read -p "Set User to Emulate...  (Blank to reset):   " Main_User_Override;Set_Initial_Vars;unset Menus[${LMI}];unset Menus[${S2LMI}] ;;
		\.) if [ "$Show_Leaderboard" -lt "1" ]; then Show_Leaderboard=$(( $Show_Leaderboard + 1 ));else Show_Leaderboard=0;fi;sed -i "s/Show_Leaderboard = .*/Show_Leaderboard = $(echo $Show_Leaderboard)/" $Dice_Config_File ;;
		\[) read -p "Save automatically after how many spins?   " Spins_Until_Save;if ! [[ $Spins_Until_Save == +([0-9]) ]] || [[ "$Spins_Until_Save" -lt "0" ]] || [[ "$Spins_Until_Save" -gt "100" ]]; then echo -e "${Cust_Error}Please enter a Whole Number between 0 - 100${STD}" && sleep 3;Spins_Until_Save="40";fi;sed -i "s/Spins_Until_Save = .*/Spins_Until_Save = $(echo $Spins_Until_Save)/" $Dice_Config_File ;;
		\*) Save_Dice_Config;Update_Dice_Leaderboard ;;
		*) echo >> /dev/null
	esac
}

Print_Menu_Main(){
	clear
	echo "G. Number Guessing Game"
	echo "R. Randomize Colors Once"
	echo "D. Roll Dice --- Earn Points --- Earn The #1 Spot"
	echo "0. Exit"
	if [[ ! " ${Menus[@]} " =~ " Read_Menu_Main " ]];then
		Menus+=("Read_Menu_Main" "Menu_Timer")
	fi
}

Read_Menu_Main(){
	case $choice in
		d|D) Menus+=("Print_Dice_Menu");dice_roll_count="0";if [ ! -f "$Dice_Config_File" ]; then Create_Dice_Config;fi;Read_Dice_Config;Update_Dice_Leaderboard ;;
		r|R) Randomness=0;sed -i "s/Randomness = .*/Randomness = $(echo $Randomness)/" $Config_File;Randomize_Colors ;;
		g|G) I_Wanna_Play_A_Game ;;
		0) unset Menus ;;
		*) echo -n ""
	esac
}

G_LMI(){	# Get Last Menu Index number...  Gets Last few index numbers in the array  "Menus"
	Old_Menus_Size=$New_Menus_Size
	Last_3_Menu_Indexs=$(for index in "${!Menus[@]}"; do echo "$index -- ${Menus[$index]}"; done | awk '{ print $1 }' | tail -n 3 | tac)
	LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '1p')		# LMI   = Last Menu Index
	S2LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '2p')	# S2LMI = Second To Last Menu Index
	T2LMI=$(echo "$Last_3_Menu_Indexs" | sed -n '3p')	# T2LMI = Third To Last Menu Index
	New_Menus_Size=${#Menus[@]}
}

Hello(){
	if [[ "$Remember_Colors" -eq "0" ]];then Reset_Colors;Read_Config_File;fi
	Menus=("Print_Menu_Main");unset choice
	while [[ ! -z "$Menus" ]]; do
		G_LMI	#	Ensure you are working with latest "Menus" elements
		if [[ "${Menus[$LMI]}" == "Menu_Timer" ]];then
			${Menus[$LMI]}
			continue
		fi
		if [[ ! -z "$choice" ]];then
			RM_Files
			if [[ $choice == +([0-9]) ]] && [[ "$choice" -eq "0" ]]; then
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
					if [[ "${Menus[$S2LMI]}" == "Print_Dice_Menu" ]];then Read_Dice_Config;fi
					unset Menus[${LMI}]
					unset Menus[${S2LMI}]
					if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
						Menus+=("Menu_Timer")
						${Menus[$T2LMI]}
					fi
				fi
				unset choice;continue
			fi
			if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]];then 
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
					unset menu_reset
					if [[ "${Menus[$S2LMI]}" == "Print_Dice_Menu" ]];then
						${Menus[$S2LMI]}
					else
						if [[ "$(( $New_Menus_Size - $Old_Menus_Size ))" -ge "2" ]] || [[ "$(( $New_Menus_Size - $Old_Menus_Size ))" -le "-2" ]];then Read_Config_File;fi
					fi
					Menus+=("Menu_Timer")
					${Menus[$LMI]}
				fi
			fi
			unset choice
			continue
		else
			if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]];then
				if [[ "${Menus[$LMI]}" == "Read_Menu_"* ]] && [[ "${Menus[$S2LMI]}" == "Print_"* ]];then
					Menus+=("Menu_Timer")
					continue
				fi
			fi
		fi
		RM_Files
		${Menus[$LMI]}
	done
}

Set_Initial_Vars
Hello
Goodbye
