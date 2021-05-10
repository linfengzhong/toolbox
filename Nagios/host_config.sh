#!/usr/bin/env bash
#
#-rw------- (600)    只有拥有者有读写权限。
#-rw-r--r-- (644)    只有拥有者有读写权限；而属组用户和其他用户只有读权限。
#-rwx------ (700)    只有拥有者有读、写、执行权限。
#-rwxr-xr-x (755)    拥有者有读、写、执行权限；而属组用户和其他用户只有读、执行权限。
#-rwx--x--x (711)    拥有者有读、写、执行权限；而属组用户和其他用户只有执行权限。
#-rw-rw-rw- (666)    所有用户都有文件读、写权限。
#-rwxrwxrwx (777)    所有用户都有读、写、执行权限。
#检测配置文件是否 OK 的命令
#/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg 

#切换root
sudo su
#切换到临时文件夹
cd /tmp
#从GitHub获取配置文件
wget --no-check-certificate https://github.com/linfengzhong/Nagios/archive/refs/tags/0.06.zip
#解压缩
unzip 0.06.zip
#给文件赋予权限
chmod 777 /tmp/Nagios-0.06/Libexec/check_*
#创建服务器配置文件夹
mkdir /usr/local/nagios/etc/objects/myservers
chmod 777 /usr/local/nagios/etc/objects/myservers
chmod 777 /usr/local/nagios/etc/objects/myservers/*

#复制check程序到指定文件夹
\cp -p -f /tmp/Nagios-0.06/Libexec/check_* /usr/local/nagios/libexec
#复制nrpe的主配置文件，加上要调用的check命令
\cp -p -f /tmp/Nagios-0.06/Remote/nrpe.cfg /usr/local/nagios/etc/
#复制Nagios主配置文件
\cp -p -f /tmp/Nagios-0.06/Host/nagios.cfg /usr/local/nagios/etc/
#复制remote servers的配置文件
\cp -p -f /tmp/Nagios-0.06/Host/myservers/* /usr/local/nagios/etc/objects/myservers
#检查nrpe服务状态
systemctl status nrpe
#重启nrpe服务
systemctl restart nrpe
#检测配置文件是否 OK 的命令
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

#检查Nagios服务的状态
systemctl status nagios
#重启Nagios服务 
systemctl restart nagios
