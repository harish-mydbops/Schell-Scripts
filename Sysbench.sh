#!/bin/bash
prepare(){
  sysbench /usr/share/sysbench/oltp_common.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=0 --table-size=$size cleanup 2>/dev/null
  sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size prepare
  echo $'\n##### Test table is prepared #####'
}

run(){
  sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size run
  echo $'\n##### Sysbench '$tname' test is performed #####'
}

cleanup(){
  sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size cleanup
  echo $'\n##### Test Table is Dropped #####'
}

multiple_run(){
  echo -e "Process started..\n 7 tests with different number of threads from  will be completed in 70 seconds\n."
  rm -rf ./sysbench.log
  for i in 2 4 8 16 32 64 128;
   do
    sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest --threads=$i --verbosity=5 --table-size=$size run >> sysbench.log
   done
  cat sysbench.log | egrep " cat|threads:|transactions:" | tr -d "\n" | sed 's/Number of threads: /\n/g' | sed 's/\[/\n/g' | sed 's/[A-Za-z\/]\{1,\}://g'| sed 's/ \.//g' | awk {'print $1 $3'} | sed 's/(/\t/g' > sysbench.csv
  file=$(date +%Y-%m-%d_%H:%M:%S\ )
  echo -e "set terminal png\nset output \"$file.png\"
  set title \"MySQL Server Testing - Mydbops\"
  set size 1,1
  set grid y
  set grid x
  set xlabel \"Number of threads used\"
  set ylabel \"Transactions (tps)\"
  plot \"sysbench.csv\" using (log($1)):2:xtic(1) with linesp notitle"
}
operation(){
  while :
   do
     echo $'\nHow do you want to perform the Benchmark.?\n\t1.Single test\n\t2.Multiple tests - (Graphical output)'
     read -p $'\nEnter your Option: ' run_opt
     if [ $run_opt -eq 1 ] 
       then
         run
         break
     elif [ $run_opt -eq 2 ]
       then
         multiple_run
         break
     else
         if [[ $? != [!0-1] ]]
          then
            echo $'\nError\n'
         fi
     fi 
  done
  return 0
}

echo "
#########################################################
#                                                       #
#           Script for Sysbench - Mydbops               #
#                                                       #
#########################################################
# Version - 0.0.1
# Purpose - MySQL Server Testing
# Author  - Mydbops
# Website - www.mydbops.com
"

if [[ -e /etc/redhat-release ]]
 then
  echo "Installing Sysbench 1.0 and its dependencies..."
  curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash >>/dev/null
  sudo yum -y install sysbench >>/dev/null
else
  curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash >>/dev/null
  sudo apt -y install sysbench >>/dev/null
fi

while :
  do
   read -p 'Enter the MySQL user: ' user
   unset pswd
   unset char_count
   echo -n "Enter password: "
   stty -echo
   char_count=0
   while IFS= read -p "$star" -r -s -n 1 char
      do
        if [[ $char == $'\0' ]] ; then
          break
        fi
        if [[ $char == $'\177' ]] ; then
            if [ $char_count -gt 0 ] ; then
              char_count=$((char_count-1))
              star=$'\b \b'
              pswd="${pswd%?}"
            else
              star=''
        fi
        else
          char_count=$((char_count+1))
          star='*'
          pswd+="$char"
        fi
      done
   stty echo   
   mysql -u$user -p$pswd sbtest -e"quit" >>/dev/null
   if [ $? -eq 0 ]
    then
     mysql -u$user -p$pswd sbtest -e"create database if not exists 'sbtest_mydbops'" >>/dev/null
     echo $'\nUser,Password Verified. Good to go!'
     break
   elif [ $? -eq 1 ]
    then
     echo $'\nUser or Password incorrect, or Test DB \'sbtest\' not found. Try again!\n'
   fi
  done
while :
  do
   read -p $'\nEnter the size of the table: ' size
   if [[ $size != *[!0-9]* ]]
    then break
   fi
   echo $'\nEnter a valid Number..'
  done
test_name(){
  echo $'\nSelect a test name:\n\t1.Delete\n\t2.Insert\n\t3.Point Select\n\t4.Read Only\n\t5.Read and Write\n\t6.Update (Index)\n\t7.Update (Non-index)\n\t8.Write\n\t9.Exit'
  while :
   do
     read -p $'\nEnter your Option: ' num
     case $num in
	1)
	   tname=delete
	   break;;
	2)
	   tname=insert
	   break;;
        3)
           tname=point_select
           break;;
        4)
           tname=read_only
           break;;
        5)
           tname=read_write
           break;;
        6)
           tname=update_index
           break;;
        7)
           tname=update_non_index
           break;;
        8)
           tname=write_only
           break;;
	9)
	   echo $'Bye!\n'
	   exit 0;;
	*)
	   echo $'\nInvalid option'
	   ;;
     esac
   done
}
test_name
exit_func(){
  echo $'\nDo you want to Drop the Test table.?\n\t1.Yes,Drop the test table and Exit.\n\t2.No, Just Exit.\n'
  while :
   do
    read -p 'Enter your Option: ' exit_opt
    case $exit_opt in
	1)
	   cleanup
	   echo $'\nThanks for using this script\n'
	   exit 0;;
	2)
	   echo $'\nOkay then, drop it manually.Thanks for using this script.\n'
	   exit 0;;
	*)
	   echo $'\nInvalid option\n'
	   ;;
    esac
   done
}
while : 
  do
   echo $'\nSelect the Operation to do:\n\t1.Prepare\n\t2.Run (Note: Run only after preparing the test table)\n\t3.Cleanup and Change test\n\t4.Exit\n'
   read -p 'Enter your Option: ' opt_num
   case $opt_num in
        1)
           prepare
           ;;  
        2)
	   operation
	   ;;  
        3)
	   cleanup
	   test_name
	   ;;
	4)
	   exit_func
	   ;;
	*)
           echo $'\nInvalid option'
	   ;;
   esac
  done
