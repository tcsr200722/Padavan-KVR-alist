#!/bin/sh
#chongshengB 2020
caddy_enable=`nvram get caddy_enable`
caddy_wan=`nvram get caddy_wan`
caddy_file=`nvram get caddy_file`
caddy_storage=`nvram get caddy_storage`
caddy_dir=`nvram get caddy_dir`
http_username=`nvram get http_username`
caddyf_wan_port=`nvram get caddyf_wan_port`
caddyw_wan_port=`nvram get caddyw_wan_port`
caddy_wip6=`nvram get caddy_wip6`
caddybin="/tmp/caddy/caddy_filebrowser"
[ -f /etc/storage/bin/caddy_filebrowser ] && caddybin="/etc/storage/bin/caddy_filebrowser"
caddy_start () 
{
	if [ "$caddy_enable" = "1" ] ;then
 logger -t "caddy" "caddy_filebrowser正在启动！"
		mkdir -p $caddy_dir/caddy
		if [ ! -f "$caddybin" ]; then
   logger -t "caddy" "未找到$caddybin，开始下载！"
			if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
				 curl -L -k -S -o "$caddy_dir/caddy/caddy_filebrowser" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/chongshengB/rt-n56u@master/trunk/user/caddy/caddy_filebrowser"
                                 if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
					logger -t "caddy" "caddy_filebrowser二进制文件下载失败，重新下载！"
                                    curl -L -k -S -o "$caddy_dir/caddy/caddy_filebrowser" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/chongshengB/rt-n56u@master/trunk/user/caddy/caddy_filebrowser"
				else
					logger -t "caddy" "caddy_filebrowser二进制文件下载成功"
					chmod -R 777 $caddy_dir/caddy/caddy_filebrowser
				fi
                                
			fi
		fi
  chmod -R 777 "$caddybin"
  caddy-ver=$($caddybin -version | sed -n '1p')
  [[ "$($caddybin -v 2>&1 | wc -l)" -lt 2 ]] && logger -t "caddy" "程序不完整，重新下载" && rm -rf $caddybin && caddy_dl
		/etc/storage/caddy_script.sh
		if [ "$caddy_wan" = "1" ] ; then
			if [ "$caddy_file" = "0" ] || [ "$caddy_file" = "2" ]; then
				fport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyf_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$fport" = 0 ] ; then
					logger -t "caddy" "WAN放行 $caddyf_wan_port tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
					if [ "$caddy_wip6" = 1 ]; then
						ip6tables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
					fi
				fi
			fi
			if [ "$caddy_file" = "1" ] || [ "$caddy_file" = "2" ]; then
				wport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyw_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$wport" = 0 ] ; then
					logger -t "caddy" "WAN放行 $caddyw_wan_port tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
					if [ "$caddy_wip6" = 1 ]; then
						ip6tables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
					fi
				fi
			fi
		fi
		[ ! -z "`pidof caddy_filebrowser`" ] && logger -t "caddy" "caddy_filebrowser_${caddy-ver}文件管理服务已启动"
  [ -z "`pidof caddy_filebrowser`" ] && logger -t "caddy" "启动失败，看看什么问题？程序退出" 
	fi
}
caddy_dl () 
{
sleep 20
caddy_start
}
caddy_close () 
{
	iptables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
	iptables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
	if [ "$wipv6" = 1 ]; then
		ip6tables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
		ip6tables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
	fi
	if [ ! -z "`pidof caddy_filebrowser`" ]; then
		killall -9 caddy_filebrowser
		[ -z "`pidof caddy_filebrowser`" ] && logger -t "caddy" "已关闭文件管理服务."
	fi
}

case $1 in
start)
caddy_start &
;;
stop)
caddy_close &
;;
esac
