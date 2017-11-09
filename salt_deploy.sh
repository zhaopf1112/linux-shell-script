#!/usr/bin/env bash
salt_deploy_version="20160830"
if [ ! -f  /usr/bin/lsb_release ];then
    if [ -f /usr/bin/apt-get ];then
        apt-get -y install lsb-release
    else
        yum -y install redhat-lsb-core
    fi
fi

OS_Distributor=`lsb_release -i|awk '{print $NF}'`
OS_release=`lsb_release -r|awk  '{print $2}'|awk -F. '{print $1}'`
OS="$OS_Distributor$OS_release"
URL_SCRIPT="http://xxxxxx"
URL_REPO="http://xxxxxxxxxxxxxx"
SALTAPI="http:xxxxxxxxxxx"
MINION_CONF="lin_minion_confs"

function sync_ntp()
{
    which ntpdate >>/dev/null 2>&1
    if [ "$?" -ne 0 ];then
        if [ "$OS_Distributor" = "CentOS" ];then
            yum install ntpdate -y
        else
            apt-get -y install ntpdate
        fi
    fi
    if [ "`pidof ntpd`" ];then
        [ "$OS" = "CentOS7" ]&&systemctl stop ntpd||killall -9 ntpd
    fi
    ntpdate xxxxxxxxxxxx
    [ "$?" -ne 0 ]&&ntpdate xxxxxxxxxxxx

}


exec 2>&1
exec &> /tmp/salt_status.txt

function setup_salt() {
        #wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        echo "${salt_deploy_version}"
        echo "`date +%F' '%T`: rm -f /etc/salt/minion"
        rm -f /etc/salt/minion
        echo "`date +%F' '%T`: [ ! -d "/etc/salt/minion.d" ] && mkdir -p /etc/salt/minion.d"
        [ ! -d "/etc/salt/minion.d" ] && mkdir -p /etc/salt/minion.d
        echo "`date +%F' '%T`: rm -f /etc/salt/minion.d/*"
        rm -f /etc/salt/minion.d/*
        echo "`date +%F' '%T`: rm -f /etc/salt/pki/minion/minion_master.pub"
        [ -f /etc/salt/pki/minion/minion_master.pub ]&&rm -f /etc/salt/pki/minion/minion_master.pub
        echo "`date +%F' '%T`: wget $URL_SCRIPT/salt/$MINION_CONF"
        wget $URL_SCRIPT/salt/$MINION_CONF/log.conf -O /etc/salt/minion.d/log.conf
        wget $URL_SCRIPT/salt/$MINION_CONF/master.conf -O /etc/salt/minion.d/master.conf
        wget $URL_SCRIPT/salt/$MINION_CONF/minion_optimize.conf -O /etc/salt/minion.d/minion_optimize.conf
        #wget -N ${URL_SCRIPT}/saltkey.py -O /tmp/saltkey.py
}

function check_salt() {
        sleep 10
        mid=$(cat /etc/salt/minion_id)
        _stat=$(salt-call test.ping 2>&1)
        if [ $? -ne 0 ];then
                echo "`date +%F' '%T`: Try to Auto_fix"
                auto_fix
        fi
}


function auto_fix() {
        mid=$(cat /etc/salt/minion_id)
        delresult="`curl http://xxxxxxxxxxxxxxx`"
        echo "`date +%F' '%T`: delete salt key API result $delresult"
        sleep 10
        echo "`date +%F' '%T`: rm -f /etc/salt/pki/minion/minion_master.pub"
        rm -f /etc/salt/pki/minion/minion_master.pub
        echo "`date +%F' '%T`: service salt-minion restart"
        service salt-minion restart
        sleep 30
}

function CentOS5(){
        mkdir -p /tmp/backup_repo/
        mv /etc/yum.repos.d/* /tmp/backup_repo/
        echo "`date +%F' '%T`: wget $URL_REPO epel custom CentOS"
        wget $URL_REPO/epel.repo -O /etc/yum.repos.d/epel.repo
        wget $URL_REPO/custom5.repo -O /etc/yum.repos.d/custom5.repo
        wget $URL_REPO/CentOS5.repo -O /etc/yum.repos.d/CentOS5.repo
        echo "`date +%F' '%T`: yum clean all"
        yum clean all
        echo "`date +%F' '%T`: yum makecache"
	yum makecache
        echo "`date +%F' '%T`: yum --enablerepo custom --disablerepo 'epel' -y install salt-minion"
    	yum --enablerepo custom --disablerepo 'epel' -y install salt-minion
        echo "`date +%F' '%T`: yum install zeromq python-msgpack -y"
        yum install zeromq python-msgpack -y

	#wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        setup_salt

	#wget -q $URL_SCRIPT/salt/zmq.tgz
	#tar xzf zmq.tgz
	#rpm -Uvh zmq/*.rpm
	chkconfig salt-minion on
        
        HOSTNAME=$(cat /etc/sysconfig/network|awk -F= '/^HOSTNAME/{print $2}')
        #MINIONID=`[[ ${HOSTNAME} =~ VMS.* ]] && echo ${HOSTNAME} || echo ${HOSTNAME}|sed -n 's@.*\(SVR[0-9]\{1,\}\).*@\1@p'`
        MINIONID=${HOSTNAME}
	echo ${MINIONID}|tr a-z A-Z > /etc/salt/minion_id
        echo "`date +%F' '%T`: rm -f /etc/salt/pki/minion/*"
        rm -f /etc/salt/pki/minion/*
        echo "`date +%F' '%T`: service salt-minion restart"
	service salt-minion restart
        sleep 5
        echo "`date +%F' '%T`: salt-call test.ping"
        salt-call test.ping
	check_salt
	#service salt-minion restart
}


function CentOS6(){
        mkdir -p /tmp/backup_repo/
        mv /etc/yum.repos.d/* /tmp/backup_repo/
        echo "`date +%F' '%T`: wget $URL_REPO epel custom CentOS"
	wget $URL_REPO/epel.repo -O /etc/yum.repos.d/epel.repo
	wget $URL_REPO/custom6.repo -O /etc/yum.repos.d/custom6.repo
	wget $URL_REPO/CentOS6.repo -O /etc/yum.repos.d/CentOS6.repo

        echo "`date +%F' '%T`: yum clean all"
        yum clean all
        echo "`date +%F' '%T`: yum makecache"
	yum makecache
        echo "`date +%F' '%T`: yum -y install telnet.x86_64"
	yum -y install telnet.x86_64
        echo "`date +%F' '%T`: yum --enablerepo custom --disablerepo 'epel' -y install salt-minion"
	yum --enablerepo custom --disablerepo 'epel' -y install salt-minion
        echo "`date +%F' '%T`: yum install zeromq python-msgpack -y"
        yum install zeromq python-msgpack -y

	#wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        setup_salt

	chkconfig salt-minion on

        HOSTNAME=$(cat /etc/sysconfig/network|awk -F= '/^HOSTNAME/{print $2}')
        #MINIONID=`[[ ${HOSTNAME} =~ VMS.* ]] && echo ${HOSTNAME} || echo ${HOSTNAME}|sed -n 's@.*\(SVR[0-9]\{1,\}\).*@\1@p'`
	MINIONID=${HOSTNAME}
        echo ${MINIONID}|tr a-z A-Z > /etc/salt/minion_id
        echo "`date +%F' '%T`: rm -f /etc/salt/pki/minion/*"
        rm -f /etc/salt/pki/minion/*
        echo "`date +%F' '%T`: service salt-minion restart"
	service salt-minion restart
        sleep 5
        echo "`date +%F' '%T`: salt-call test.ping"
        salt-call test.ping
	check_salt
	#service salt-minion restart
}

function CentOS7(){
        mkdir -p /tmp/backup_repo/
        mv /etc/yum.repos.d/* /tmp/backup_repo/
        echo "`date +%F' '%T`: wget $URL_REPO epel custom CentOS"
	wget $URL_REPO/epel.repo -O /etc/yum.repos.d/epel.repo
	wget $URL_REPO/custom7.repo -O /etc/yum.repos.d/custom7.repo
	wget $URL_REPO/CentOS7.repo -O /etc/yum.repos.d/CentOS7.repo
        echo "`date +%F' '%T`: yum clean all"
        yum clean all
        echo "`date +%F' '%T`: yum makecache"
	yum makecache
        echo "`date +%F' '%T`: yum -y install telnet.x86_64"
	yum -y install telnet.x86_64
        echo "`date +%F' '%T`: yum --enablerepo custom --disablerepo 'epel' -y install salt-minion"
	yum --enablerepo custom --disablerepo 'epel' -y install salt-minion
        echo "`date +%F' '%T`: yum install zeromq python-msgpack -y"
        yum install zeromq python-msgpack -y

	#wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        setup_salt
	systemctl enable salt-minion

        HOSTNAME=$(cat /etc/sysconfig/network|awk -F= '/^HOSTNAME/{print $2}')
        #MINIONID=`[[ ${HOSTNAME} =~ VMS.* ]] && echo ${HOSTNAME} || echo ${HOSTNAME}|sed -n 's@.*\(SVR[0-9]\{1,\}\).*@\1@p'`
	#MINIONID=${HOSTNAME}
	MINIONID=`hostname`
        echo ${MINIONID}|tr a-z A-Z > /etc/salt/minion_id
        rm -f /etc/salt/pki/minion/*
        echo "`date +%F' '%T`: killall -9 salt-minion"
        killall -9 salt-minion
        sleep 3
        echo "`date +%F' '%T`: systemctl start salt-minion"
        systemctl start salt-minion
#	systemctl restart salt-minion
        sleep 5
        echo "`date +%F' '%T`: salt-call test.ping"
        salt-call test.ping
	check_salt
}

function Ubuntu_12(){
        echo "`date +%F' '%T`: wget -q -O- "http:xxxxxxxxxx/key" | sudo apt-key add -"
	wget -q -O- "http://xxxxxxxxxxxxxxxxxxxxx" | sudo apt-key add -
#	sudo add-apt-repository ppa:saltstack/salt
        echo "`date +%F' '%T`: wget http://xxxxxxxxxxxx/sources.list -O /etc/apt/sources.list"
	wget http://xxxxxxxxxxxxx/sources.list -O /etc/apt/sources.list
        [ -f /etc/apt/sources.list.d/salt.list ]&&rm -f /etc/apt/sources.list.d/salt.list
        if [ "`dpkg -l|grep -c msgpack`" -eq 1 ];then
            echo "`date +%F' '%T`: aptitude remove python-msgpack -y"
            aptitude remove python-msgpack -y
        fi 
        echo "`date +%F' '%T`: apt-get update"
        apt-get clean
        apt-get update
        echo "`date +%F' '%T`: apt-get install -y chkconfig libpam-cracklib"
        apt-get install -y chkconfig
        apt-get install -y libpam-cracklib
        if [ "`dpkg -l|grep -c salt-minion`" -eq 1 ];then
            echo "`date +%F' '%T`: aptitude remove salt-minion -y"
            aptitude remove salt-minion -y
        fi
        echo "`date +%F' '%T`: apt-get install -y salt-minion --force-yes"
	apt-get install -y salt-minion --force-yes

	#wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        setup_salt
        sudo ln -s /usr/lib/insserv/insserv /sbin/insserv
        if [ ! -f /usr/sbin/sysv-rc-conf ];then
            apt-get install -y sysv-rc-conf
        fi
        sysv-rc-conf salt-minion on
	#chkconfig --level 35 salt-minion on

        Ubuntu_HOSTNAME=$(cat /etc/hostname)
        #MINIONID=`[[ ${HOSTNAME} =~ VMS.* ]] && echo ${HOSTNAME} || echo ${HOSTNAME}|sed -n 's@.*\(SVR[0-9]\{1,\}\).*@\1@p'`
	MINIONID=${HOSTNAME}
        echo ${MINIONID}|tr a-z A-Z > /etc/salt/minion_id
        #service salt-minion restart
        
        #re-gen the key
        #rm -f /etc/salt/pki/minion/*
        echo "`date +%F' '%T`: service salt-minion restart" 
	service salt-minion restart
        sleep 5
        echo "`date +%F' '%T`: salt-call test.ping"
        salt-call test.ping
	check_salt
	#service salt-minion restart
}

function Ubuntu_14(){
        echo "`date +%F' '%T`: wget -q -O- "http://xxxxxxxxxxxxxx/salt/key" | sudo apt-key add -"
        wget -q -O- "http://xxxxxxxxxxxxxxx/x/salt/key" | sudo apt-key add -
        echo "`date +%F' '%T`: wget http://xxxxxxxxxxxxxx/sources.list -O /etc/apt/sources.list"
        wget http://xxxxxxxxxxxxx/ubuntu14.04-sources.list -O /etc/apt/sources.list
        if [ "`dpkg -l|grep -c msgpack`" -eq 1 ];then
            echo "`date +%F' '%T`: aptitude remove python-msgpack -y"
            aptitude remove python-msgpack -y
        fi
        echo "`date +%F' '%T`: apt-get update"
        apt-get clean
        apt-get update
        echo "`date +%F' '%T`: apt-get install -y chkconfig libpam-cracklib"
        apt-get install -y chkconfig
        apt-get install -y libpam-cracklib
        if [ "`dpkg -l|grep -c salt-minion`" -eq 1 ];then
            echo "`date +%F' '%T`: aptitude remove salt-minion -y"
            aptitude remove salt-minion -y
        fi
        echo "`date +%F' '%T`: apt-get install -y salt-minion --force-yes"
        apt-get install -y salt-minion --force-yes

        #wget $URL_SCRIPT/salt/minion -O /etc/salt/minion
        setup_salt
        sudo ln -s /usr/lib/insserv/insserv /sbin/insserv
        if [ ! -f /usr/sbin/sysv-rc-conf ];then
            apt-get install -y sysv-rc-conf
        fi
        sysv-rc-conf salt-minion on
        #chkconfig --level 35 salt-minion on

        Ubuntu_HOSTNAME=$(cat /etc/hostname)
        #MINIONID=`[[ ${HOSTNAME} =~ VMS.* ]] && echo ${HOSTNAME} || echo ${HOSTNAME}|sed -n 's@.*\(SVR[0-9]\{1,\}\).*@\1@p'`
        MINIONID=${HOSTNAME}
        echo ${MINIONID}|tr a-z A-Z > /etc/salt/minion_id
        #service salt-minion restart

        #re-gen the key
        #rm -f /etc/salt/pki/minion/*
        echo "`date +%F' '%T`: service salt-minion restart" 
        service salt-minion restart
        sleep 5
		echo "`date +%F' '%T`: salt-call test.ping"
        salt-call test.ping
        check_salt
        #service salt-minion restart
}

case $OS in 
	CentOS7)
		sync_ntp
		CentOS7
		;;
	CentOS6)
		sync_ntp
		CentOS6
		;;
	CentOS5)
		sync_ntp
		CentOS5
		;;		
	Ubuntu12)
		sync_ntp
		Ubuntu_12
		;;
	Ubuntu14)
		sync_ntp
		Ubuntu_14
		;;
	*)
		echo "Wrong OS or release!"
		;;
esac

