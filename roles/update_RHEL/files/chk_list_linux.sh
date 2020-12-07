#!/bin/bash
# ===============================================================
# Script Name....: chk_list_linux
# Server.........: Linux servers
# Function.......: Operating system configuration checklist
# Creation Date..: May 07th, 2007
#
# Created by.....: Fabiano Souza
#                  T-Systems Brazil - Delivery - GCU Midmarket
# ***************************************************************
# Abstract.......: Run OS configuration checklist and put it in a
#                  timestamped file
#****************************************************************
#
Chk_FileSystems () #Active_Filesystems
     {
        echo Filesystem_chk_START:
        df -h|grep -v "$(df -h|head -1)"
        echo Filesystem_chk_END:
     }

Chk_NetworkCards () #Network_Interfaces
{
   echo IfConfig_chk_START:
   ifconfig -a |grep -v -E 'RX |TX '
   echo IfConfig_chk_END:
}

Chk_uname () #uname
{
   echo uname_chk_START:
   uname -a
   echo uname_chk_END:
}

Chk_realease () #release
{
   echo release_chk_START:
   cat /etc/*-release
   echo release_chk_END:
}

Chk_Disks () #PhisicalDisks
{
   echo Chk_Disks_START:
   fdisk -l | grep Disk | egrep -v '(identifier|mapper|dos)'
   echo Chk_Disks_END:
}

Chk_Pvs () #Checking_Pvs
{
   echo Chk_PVs_START:
   pvs
   echo Chk_PVs_END:
}

Chk_VGs () #Checking_VGs
{
   echo Chk_VGs_START:
   vgs
   echo Chk_VGs_END:
}

Chk_Kernel () #Kernel_Parameters
{
   echo sysctl.conf_chk_START:
   cat /etc/sysctl.conf
   echo sysctl.conf_chk_END:
}


Chk_resolv.conf () #resolv.conf
{
   echo resolv.conf_chk_START:
   cat /etc/resolv.conf
   echo resolv.conf_chk_END:
}

Chk_RoutingTable () #Routing_Table
{
   echo Routes_chk_START:
   netstat -rn
   echo Routes_chk_END:
}

Chk_LSBLK () #List_BLK
{
   echo lsblk_chk_START:
   lsblk
   echo lsblk_chk_END:
}

Chk_Crontab () #Crontab
{
   echo CronTab_chk_START:
   crontab -l
   echo CronTab_chk_END:
}

Chk_HostsFile () #Hosts_File
{
   echo Hosts_chk_START:
   cat /etc/hosts
   echo Hosts_chk_END:
}

Chk_PasswordFile () #Passwd_File
{
   echo Passwd_chk_START:
   cat /etc/passwd
   echo Passwd_chk_END:
}

Chk_Gateways () #Gateways_Configuration
{
   echo Gateways_chk_START:
   cat /etc/sysconfig/network
   echo Gateways_chk_END:
}

Chk_Installedpacks () #Installed_Packages
{
   echo InstalledPackages_chk_START:
   rpm -qa
   echo InstalledPackages_chk_END:
}

Chk_FilesystemTable () #Filesystems_Table
{
   echo FSTab_chk_START:
   cat /etc/fstab
   echo FSTab_chk_END:
}

# =======================================
# Generate new checklist timestamped file
# =======================================

check_generate ()
{
   # *** If checklist file has been generated
   # *** program is aborted and shows error message
   # ----------------------------------------------

   CHECK_EXIST=$(ls $CHECK_LIST_DIR/*.checklist 2>/dev/null)

   Create_Timestamped

   if [ "$CONFIG_FILE" != "" ];then
      CHECKLIST_COPY=$(cat $CONFIG_FILE)
      CHECKLIST_USER=$(echo $CHECKLIST_COPY|awk -F@ '{print $1}')

      su - $CHECKLIST_USER -c "scp $CHKLIST_FILE $CHECKLIST_COPY" >/dev/null 2>&1
   fi
}

# =======================================
# Compare two checklist timestamped files
# Create a new one if it does not exists
# =======================================

check_compare ()
{
   # *** If second checklist file is not present for comparison
   # *** the new one will be created
   # -----------------------------------------------------------

   CHKLIST_FILE=$(ls -tr $CHECK_LIST_DIR/*.checklist 2>/dev/null|tail -2|wc -l)

   if   (( $CHKLIST_FILE == 0 )) ;then
        echo '            *****                   '
        echo "No checklist files to be compared!!!"
        echo '            *****                   '
        echo ""

        return
   elif (( $CHKLIST_FILE == 1 )) ;then
      echo "Second timestamped file not found!!!"
      echo "Generating new one before start comparison..."
      echo ""

      sleep 2

      Create_Timestamped
   fi

   echo 'Comparing checklists...Please stand-by'



   # *** Create a workfile having checklist sections to be
   # *** compared and another one haivng the section descriptions
   # ------------------------------------------------------------

   grep _chk_START:$  $MAIN_MODULE|awk '{print $2}'|sed -e 's/_START://' >/tmp/TEMPxxx.$$
   grep ^Chk_ $MAIN_MODULE|awk -F\# '{print $2}' >/tmp/TEMPzzz.$$

   paste /tmp/TEMPxxx.$$ /tmp/TEMPzzz.$$ >$FUNCTIONS_LIST

   rm -r /tmp/TEMPzzz.* /tmp/TEMPxxx.*



   # *** Define the checklist comparison file to be recorded
   # *** during checklist verification
   # -------------------------------------------------------

   CHKLIST_COMP=$CHECK_LIST_DIR/$(hostname).$(date +"%d%m%Y.%H%M%S").compare

   LIST_CHKFILE=$(ls -tr $CHECK_LIST_DIR/*.checklist|tail -2 2>/dev/null)

   CHKFILE_1ST=$(echo $LIST_CHKFILE|awk '{print $1}')
   CHKFILE_2ND=$(echo $LIST_CHKFILE|awk '{print $2}')

   CHKLIST_RECORD=$(cat $FUNCTIONS_LIST|awk '{print $1}')



   # *** Compare checklist files (one section at a time)
   # ---------------------------------------------------

   echo '--------------------------------------------------------------------------'
   echo "Checklist files being compared:"
   echo "1st: $CHKFILE_1ST"
   echo "2nd: $CHKFILE_2ND"
   echo '--------------------------------------------------------------------------'

   for CHKLIST_SECTION in $CHKLIST_RECORD;do
       SECTION_NAME=$CHKLIST_SECTION

       SECTION_DESC=$(grep $CHKLIST_SECTION $FUNCTIONS_LIST|awk '{print $2}'|tr "_" " ")



       # *** Generate AWK command line and run it for each section
       # *** to be compared
       # ---------------------------------------------------------

       AWK_SEARCH_STRING="/${SECTION_NAME}_START:/,/${SECTION_NAME}_END:/"

       AWK_COMMAND_LINE="awk '"$AWK_SEARCH_STRING"'"

       cat $CHKFILE_1ST|eval $AWK_COMMAND_LINE >/tmp/checklist01.$$
       cat $CHKFILE_2ND|eval $AWK_COMMAND_LINE >/tmp/checklist02.$$

       printf "Checking section $SECTION_DESC: "

       diff /tmp/checklist01.$$ /tmp/checklist02.$$ >/dev/null
       RC=$?

       if [ $RC -eq 0 ];then
          echo '- OK'
       else
          echo '- Not OK for that section. Please check !!!'
          diff /tmp/checklist01.$$ /tmp/checklist02.$$
       fi
       echo '-----------------------------------------------------------------------------'

       sleep 1
   done|tee $CHKLIST_COMP

   if [ "$CONFIG_FILE" != "" ];then
      CHECKLIST_COPY=$(cat $CONFIG_FILE)
      CHECKLIST_USER=$(echo $CHECKLIST_COPY|awk -F@ '{print $1}')

      su - $CHECKLIST_USER -c "scp $CHKLIST_FILE $CHECKLIST_COPY" >/dev/null 2>&1
   fi

   echo ""
   echo 'Checklist comparing has completed.'
   echo "See file $CHKLIST_COMP if you cannot scroll back"
   echo ""
}

# =====================================================
# Create a timestamped file using recursive programming
# to run internal functions from this script program
# =====================================================

Create_Timestamped ()
{
   echo "Generating checklist for $(hostname). Please stand-by"
   echo ""

   grep ^Chk_ $MAIN_MODULE|awk '{print $1}' >$FUNCTIONS_LIST

   mkdir $CHECK_LIST_DIR/ 2>/dev/null

   CHKLIST_FILE=$CHECK_LIST_DIR/$(hostname).$(date +"%d%m%Y.%H%M%S").checklist

   for COMMAND_LINE in $(cat $FUNCTIONS_LIST);do
       COMMAND_DESC=$(grep ^$COMMAND_LINE $MAIN_MODULE|awk -F\# '{print $2}'|tr "_" " " )

       printf "Collecting $COMMAND_DESC..."

       $COMMAND_LINE >> $CHKLIST_FILE

       echo '======================================================================================' >> $CHKLIST_FILE

       sleep 1
       echo "Done!!!"
   done

   echo ""
   echo 'Checklist generation has finished!!!'
   echo ""
}

# ========================================
# Operating system checklist - Main Module
# ========================================

echo ""
echo "Red Hat Linux Operating System Checklist v2.00"
echo "By Fabiano Souza"
echo "---------------------------------------------"
echo ""

OS_NAME=$(uname)

if [ "$OS_NAME" != "Linux" ];then
   echo ""
   echo "*** Operating system not valid to run this command ***"
   echo "Aborted!!!"

   sleep 3

   exit
fi

export MAIN_MODULE=$0
export FUNCTIONS_LIST=/tmp/$(basename $MAIN_MODULE.dat)
export CHECK_LIST_DIR=/home/tech/data/checklist
export CONFIG_FILE=$(ls /etc/chk_list_aix.conf 2>/dev/null)

. /etc/profile

mkdir -p $CHECK_LIST_DIR 2>/dev/null

find $CHECK_LIST_DIR -name "*.checklist" -mtime +60 -exec rm {} \; >/dev/null 2>&1

# *** Help screen is shown if no argument is parsed

case $1 in
     -g|--generate) check_generate
     ;;
     -c|--compare)  check_compare
     ;;
       *) echo 'Correct syntax:'
          echo "$(basename $MAIN_MODULE) <-g|--generate|-c|--compare|-h|--help>"
          echo ""
          echo "-h|--help     - show this screen"
          echo ""
          echo "-g|--generate - create checklist file"
          echo ""
          echo "-c|--compare  - create a new checklist and"
          echo "                compare it to the previous one"
          echo ""
     ;;
esac

rm $FUNCTIONS_LIST 2>/dev/null
rm /tmp/checklist0[12].$$ 2>/dev/null