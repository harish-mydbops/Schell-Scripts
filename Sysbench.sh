#!/bin/bash
prepare(){
sysbench /usr/share/sysbench/oltp_common.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size cleanup
sysbench /usr/share/sysbench/oltp_common.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size prepare
#echo $'\n##### Test table is prepared #####'
}
run(){
sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size run
#echo $'\n##### Sysbench '$tname' test is performed #####'
}
cleanup(){
sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size cleanup
#echo $'\n##### Test Table is Dropped #####'
}
exit_func(){
  sysbench /usr/share/sysbench/oltp_$tname.lua --db-driver=mysql --mysql-user=$user --mysql-password=$pswd --mysql-db=sbtest_mydbops --verbosity=5 --table-size=$size cleanup
  echo $'\nThanks for using this script'
  exit 0;
}
echo "
#########################################################
#                                                       #
#           Script for Sysbench - Mydbops               #
#                                                       #
#########################################################
# Version - 0.1.2
# Purpose - MySQL Server Testing
# Author  - MyDBOPS
# Website - www.mydbops.com

"
installation(){
  if [[ $1 == rhel ]]; then
    curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash >>/dev/null
    sudo yum -y install sysbench >>/dev/null
  else
    if [[ $1 == deb ]]; then
      curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash >>/dev/null
      sudo apt -y install sysbench >>/dev/null
    fi
  fi
}

if [[ -e /etc/redhat-release ]]; then
  installation rhel
else
  installation deb
fi

MySQL(){
   read -p 'Enter the MySQL user: ' user
   while :
    do
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
      read -p $'\nEnter the size of the table: ' size
      if [[ $size != *[!0-9]* ]];
       then break
      fi
      echo $'\nEnter a valid Number..'
    done

all_tests(){
  for test_name in delete,insert,point_select,read_only,read_write,update_index,update_non_index,write_only;
   do
    prepare test_name

}

test_name(){
  echo $'\nSelect a test name:\n\t1.Delete\n\t2.Insert\n\t3.Point Select\n\t4.Read Only\n\t5.Read and Write\n\t6.Update (Index)\n\t7.Update (Non-index)\n\t8.Write'
  while :
    do
      read -p $'\nYour Option: ' t_num
      case $t_num in
        1)
           all_tests
           break;;
        2)
           tname=delete
           break;;
        3)
           tname=insert
           break;;
        4)
           tname=point_select
           break;;
        5)
           tname=read_only
           break;;
        6)
           tname=read_write
           break;;
        7)
           tname=update_index
           break;;
        8)
           tname=update_non_index
           break;;
        9)
           tname=write_only
           break;;
        *)
           echo $'\nInvalid option'
           ;;
      esac
    done
}test_name

}
