#!/bin/bash

SSH='ssh -o StrictHostKeyChecking=no -o LogLevel=quiet -o NumberOfPasswordPrompts=1'
STD='\033[0;37;40m'
RED='\033[1;97;41m'
expect_ret_code=1
Main_User=$(who am i | awk '{ print $1 }')

#Define Session Names
session="${Main_User}-SNOC"


#	ladmin2p


# Define Window Names
Window0="menu_SNOC.sh"
Window1="Server1"
Window2="Server2"
Window3="Multi_Script"
Window4="Hot_Standby"
Window5="SNOC1"
Window6="SNOC2"
Window7="Server3"

Enter_Pass(){
	echo "Please enter your password:   "
	read -s Pass
}

Test_Pass(){
	# test password via scp
	echo "Tmux es increíble, al igual que vim. señor camisa azul disfruta jugando juegos." > ~/tmux.temporary
	/usr/bin/expect -f <(cat <<- EOF
		spawn scp tmux.temporary ${Main_User}@Server1:/home/C54917a/SNOC_Script/
		#######################
		expect {
			-re ".*es.*o.*" {
				exp_send "yes\r"
				exp_continue
			}
			"assword: " {
				send "${Pass}\r"
				expect {
					-re "temporary" {
						exit 0
					}
					"assword: " {
						exit 1
					}
				}
			}
		}
		EOF
	) > ~/.tmux.temp
	expect_ret_code=$?
}

Connect(){
	sleep 1
	tmux send-keys "$Pass" ENTER
	tmux send-keys "clear" ENTER
}

Switch_to_Root(){
        if [ ! -z "$su_to_root" ]; then
		tmux send-keys "clear" ENTER
		tmux send-keys "sudo -i" ENTER
		tmux send-keys "$Pass" ENTER
		tmux send-keys "clear" ENTER
	fi
}

#Test for tmux session
tmux has-session -t $session 2> /dev/null

if [ "$?" -eq 0 ] ; then
	clear
	echo -e "${RED}Tmux sessions already exist... Enter this command to connect\n\ntmux a -t $session\n\n\n${STD}"
else
	
	while true; do
		echo "Do you want to su to root?   ( Y / n)"
		read -s -n 1 su_to_root
    		case $su_to_root in
			y|Y) break ;;
			n|N) unset su_to_root; break ;;
			* ) echo "Please answer yes or no."
		esac
	done

	while [ $expect_ret_code -ne 0 ]; do
		Enter_Pass
		Test_Pass
	done
	rm -f ~/tmux.temporary

	# create a new tmux session and window
	tmux new-session -d -s $session -n $Window0

	# Select pane 1, connect to Server1
	tmux selectp -t 1 
	tmux send-keys "$SSH Server1" C-m 
	Connect
	tmux send-keys "vim" C-m 
	#Switch_to_Root


	# create a new window
	tmux selectp -t 1
	tmux new-window -t $session:1 -n $Window1
	tmux select-window -t $session:1

	# Select pane 1, connect to Server2
	tmux selectp -t 1 
	tmux send-keys "$SSH Server1" C-m 
	Connect
	Switch_to_Root

	# Split pane 1, connect to Server1
	tmux splitw -v
	tmux resize-pane -D 20
	tmux send-keys "$SSH Server1" C-m 
	Connect
	Switch_to_Root


	# create a new window
	tmux selectp -t 1
	tmux new-window -t $session:2 -n $Window2
	tmux select-window -t $session:2

	# Select pane 1, connect to Server2
	tmux selectp -t 1 
	tmux send-keys "$SSH Server2" C-m 
	Connect
	Switch_to_Root

	# Split pane 1, connect to Server2
	tmux splitw -v
	tmux resize-pane -D 20
	tmux send-keys "$SSH Server2"" C-m 
	Connect
	Switch_to_Root

	tmux selectp -t 1
	tmux new-window -t $session:3 -n $Window3
	tmux select-window -t $session:3

	# Select pane 1, connect to Server1
	tmux selectp -t 1 
	tmux send-keys "$SSH Server1" C-m 
	Connect
	Switch_to_Root

	# Split pane 1, connect to Server1
	tmux splitw -v
	tmux send-keys "$SSH Server1" C-m 
	Connect
	Switch_to_Root

	tmux new-window -t $session:4 -n $Window4
	tmux select-window -t $session:4
	tmux selectp -t 1 
	tmux splitw -v

	tmux new-window -t $session:5 -n $Window5
	tmux select-window -t $session:5
	tmux selectp -t 1 

	tmux new-window -t $session:6 -n $Window6
	tmux select-window -t $session:6
	tmux selectp -t 1 

GitLab_Server(){
	tmux new-window -t $session:7 -n $Window7
	tmux select-window -t $session:7
	tmux send-keys "$SSH Server3" C-m 
	Connect
	tmux selectp -t 1 
}
	# GitLab_Server

	# return to first window
	tmux select-window -t $session:0

	# Select pane 1
	tmux selectp -t 1

	# Finished setup, unset Password, attach to the tmux session!
	unset Pass
	clear
	echo -e "${RED}Tmux sessions are created... Enter this command to connect\n\ntmux a -t $session\n\n\n${STD}"
	exit
fi
