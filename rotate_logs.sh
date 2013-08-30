cd /root/wbam/log
now=$(date +"%Y-%m-%d-%S")
tar czvf development.$now.tgz development.log 
echo null > /root/wbam/log/development.log
cd ~
exit

