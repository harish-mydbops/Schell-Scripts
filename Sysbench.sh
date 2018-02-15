#!/bin/bash
prepare(){
sysbench /usr/share/sysbench/oltp_common.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=0 --tables=$tbl_num --table-size=$size cleanup >>/dev/null
sysbench /usr/share/sysbench/oltp_common.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=0 --tables=$tbl_num --table-size=$size prepare >>/dev/null
#echo $'\n##### Test table is prepared #####'
}
run(){
tstamp=$(date +%Y-%m-%d_%H:%M:%S)
mkdir -p ~/Sysbench_Mydbops/$tstamp
mkdir -p ~/Sysbench_Mydbops/Graphs/
Test=${$1~}
echo -e "Multiple $Test tests with different number of threads will be performed..\nProcess started.."
for i in 2 4 8 16 32 64 128;
do
sysbench /usr/share/sysbench/oltp_$1.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --mysql-socket=/tmp/mysql.sock --threads=$i --verbosity=5 --table-size=$size run >> ~/Sysbench_Mydbops/$tstamp/sysbench.log
done
cat ~/Sysbench_Mydbops/$tstamp/sysbench.log | egrep " cat|threads:|transactions:" | tr -d "\n" | sed 's/Number of threads: /\n/g' | sed 's/\[/\n/g' | sed 's/[A-Za-z\/]\{1,\}://g'| sed 's/ \.//g' | awk {'print $1 $3'} | sed 's/(/\t/g' > ~/Sysbench_Mydbops/$tstamp/sysbench.csv
echo -e "set terminal png
set output \"~/Sysbench_Mydbops/Graphs/Benchmark_$tstamp.png\"
set title \"MySQL Server Testing ($Test test) - Mydbops\"
set size 1,1
set grid y
set grid x
set xlabel \"Number of threads used\"
set ylabel \"Transactions (tps)\"
plot \"~/Sysbench_Mydbops/$tstamp/sysbench.csv\" using (log(\$1)):2:xtic(1) with linesp notitle" >> ~/Sysbench_Mydbops/$tstamp/mygraph
cd ~/Sysbench_Mydbops/Graphs/
gnuplot ~/Sysbench_Mydbops/$tstamp/mygraph
echo "Multiple $Test Tests completed and the Graph is saved as \"~/Sysbench_Mydbops/Graphs/Benchmark_$tstamp.png\""


}

cleanup(){
sysbench /usr/share/sysbench/oltp_$1.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --tables=$tbl_num --table-size=$size cleanup
#echo $'\n##### Test Table is Dropped #####'
}

exit_func(){
  sysbench /usr/share/sysbench/oltp_$1.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --tables=$tbl_num --table-size=$size cleanup
  echo $'\nThanks for using this script'
  exit 0;
}


installation(){
  if [[ $1 == rhel ]]; then
    while true;do echo -n \#; sleep 0.5; done &
    trap 'kill $!' SIGTERM SIGKILL
    echo -e "Installing Sysbench...\nProgress:"
    curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash >>/dev/null
    sudo yum -y install sysbench >>/dev/null
    echo -e"\nDone. Sysbench 1.0 Installed"
    kill $!
  else
    if [[ $1 == deb ]]; then
    while true;do echo -n \#; sleep 0.5; done &
    trap 'kill $!' SIGTERM SIGKILL
    echo -e "Installing Sysbench...\nProgress:"
    curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash >>/dev/null
    sudo apt -y install sysbench >>/dev/null
    echo -e"\nDone. Sysbench 1.0 Installed"
    kill $!
    fi
  fi
}

MySQL(){
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
     elif [ $? -eq 1 ]
      then
      echo $'\nUser or Password incorrect. Try again!\n'
     fi
    done   

   while :
    do
      read -p $'\nEnter the number of the table: ' tbl_num
      if [[ $tbl_num != *[!0-9]* ]];
       then break
      fi
      echo $'\nEnter a valid Number..'
      read -p $'\nEnter the size of the table: ' size
      if [[ $size != *[!0-9]* ]];
       then break
      fi
      echo $'\nEnter a valid Number..'
    done

all_tests(){
  for test_name in delete,insert,point_select,read_only,read_write,update_index,update_non_index,write_only;
   do
    prepare
    run $test_name
}all_tests
}

echo "
#########################################################
#                                                       #
#           Script for Sysbench - Mydbops               #
#                                                       #
#########################################################
# Version - 0.1.2
# Purpose - Sysbench Testing
# Author  - MyDBOPS
# Website - www.mydbops.com

"
if [[ -e /etc/redhat-release ]]; then
  rpm -qa | grep -i sysbench
  if [[ $? -eq 1 ]]; then
    installation rhel
  fi
else
    installation deb
fi

for i in $@
do
  if [[ $i == "cpu" ]]; then
    echo -e "\nPerforming CPU Test..."
    sysbench cpu --cpu-max-prime=20000 run
  fi
  if [[ $i == "fileio" ]]; then
    echo -e "Creating files for the File IO test...\n"
    while true;do echo -n \#; sleep 0.5; done &
    trap 'kill $!' SIGTERM SIGKILL
    sysbench fileio --file-total-size=150G prepare
    kill $!
    echo -e "\nPerforming File IO Test..."
    sysbench fileio --file-total-size=150G --file-test-mode=rndrw --init-rng=on --max-time=300 --max-requests=0 run
  fi
  if [[ $i == "mysql" ]]; then
    MySQL
  fi
