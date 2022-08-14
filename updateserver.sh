#!/bin/bash
#set -x;

#Variables
DIR_NGINX="/var/www";
DIR_UPDATE="${DIR_NGINX}/r7-office/windows/updates";
URL_UPDATER="http://download.r7-office.ru/windows/updates/appcast.xml";

root_checking () {
	if [ ! $( id -u ) -eq 0 ]; then
		echo "To perform this action you must be logged in with root rights"
		exit 1;
	fi
}
root_checking

while [ "$1" != "" ]; do
	case $1 in	

		nginx | --nginx )
			if [ "$2" == "true" ]; then
				INSTALL="true";
				shift
			fi
		;;

		domain | --domain )
			if [ "$2" != "" ]; then
				NEW_UPDATER=$2
				shift
			fi
		;;
		
		cron | --cron )
			if [ "$2" == "true" ]; then
				CRON="true";
				shift
			fi
		;;

		-? | -h | --help )
			echo "  Используйте $0 [PARAMETER] [[PARAMETER], ...]"
			echo "    Параметры:"
			echo "       domain, --domain            задает адрес будущего сервера обновления, в формате http://domain.name "
			echo "       nginx,  --nginx             используйте для установки NGINX (true|false)"
			echo "       cron,   --cron              используйте для добавления правила в CRON (true|false)"
			echo "       -?, -h, --help              эта справка."
			echo
			exit 0
		;;

	esac
	shift
done

	if [ "$NEW_UPDATER" == "" ] ; then
		echo -e "Укажите адрес в формате https://domain.name или http://x.x.x.x";
		read -p "Введите адрес сервера: " NEW_UPDATER
	fi
	
	if [ -d ${DIR_UPDATE} ]; then
			echo "Directory ${DIR_UPDATE} already established";
		else
			echo "Directory ${DIR_UPDATE} not created.";
			echo "Directory ${DIR_UPDATE} creation...";
			mkdir -p ${DIR_UPDATE};
				if [ -d ${DIR_UPDATE} ]; then
					echo "DONE!";
				else
					echo "ERROR!";
				fi
	fi

	PWD_OLD=$(pwd);
	cd ${DIR_UPDATE};
	
	URL_ARR_UPDATER="$(curl -s -k ${URL_UPDATER} | grep "enclosure" |  cut -d"\"" -f2)" ;
	URL_ARR_UPDATER="${URL_ARR_UPDATER} ${URL_UPDATER} $(curl -s -k ${URL_UPDATER} | grep "releaseNotesLink" | cut -d">" -f2 | cut -d"<" -f1 | head -1)" ;

	for URL_CONTENT in $URL_ARR_UPDATER
		do
			if [[ "${URL_CONTENT}" == *.exe ]]; then
				wget -N --no-check-certificate -tries=3 --rejected-log=download.error.log ${URL_CONTENT};
			else
				wget -O "$(echo ${URL_CONTENT} | rev | cut -d"/" -f1 | rev)" --no-check-certificate -tries=3 --rejected-log=download.error.log ${URL_CONTENT};
			fi
     		done

	NEW_UPDATER=$(sed 's,/,\\/,g' <<< $NEW_UPDATER)

	if [[ $NEW_UPDATER != "" ]]; then
		sed -i "s/https:\/\/download.r7-office.ru/$NEW_UPDATER/" ${DIR_UPDATE}/appcast.xml ;
		sed -i "s/<h2>Новые функции<\/h2>/<h2>Локальный сервер обновления<\/h2><h2>Новые функции<\/h2>/" ${DIR_UPDATE}/changes.html ;
	fi

	cd ${PWD_OLD};
	chown -R www-data:www-data ${DIR_NGINX}/r7-office ;

#Install and Configure NGINX
	if [ "$INSTALL" == "true" ] ; then
		if [ -f /etc/altlinux-release ] ; then
			apt-get update;
			apt-get install nginx -y ;
			systemctl enable nginx ;
				if [ -f /etc/nginx/sites-enabled.d/default ]; then
					rm /etc/nginx/sites-enabled.d/default;
				fi
				if [ ! -f /etc/nginx/sites-available.d/r7-office.conf ]; then
					mv r7-office.conf /etc/nginx/sites-available.d/r7-office.conf;
				fi
			ln -s /etc/nginx/sites-available.d/r7-office.conf /etc/nginx/sites-enabled.d/
			systemctl restart nginx ;		
		elif [ -f /etc/debian_version ] ; then
			apt-get update;
			apt-get install nginx -y ;
			systemctl enable nginx ;
				if [ -f /etc/nginx/sites-enabled/default ]; then
					rm /etc/nginx/sites-enabled/default;
				fi
				if [ ! -f /etc/nginx/sites-available/r7-office.conf ]; then
					mv r7-office.conf /etc/nginx/sites-available/r7-office.conf;
				fi
			ln -s /etc/nginx/sites-available/r7-office.conf /etc/nginx/sites-enabled/
			systemctl restart nginx ;
		elif [ -f /etc/redhat-release ] ; then
			yum check-update ;
			yum -y install nginx ;
			systemctl enable nginx ;
	#			if [ -f /etc/nginx/conf.d/default ]; then
	#				rm /etc/nginx/conf.d/default;
	#			fi
	#			if [ ! -f /etc/nginx/conf.d/r7-office.conf ]; then
	#				mv r7-office.conf /etc/nginx/conf.d/r7-office.conf;
	#			fi
			systemctl restart nginx ;
		else
			echo "Not supported OS";
			exit 1;
		fi
	fi

#Install and Configure CRON
	if [ "$CRON" == "true" ] ; then
		systemctl enable cron ;
		if [ -d /usr/local/bin/ ]; then
			cp -f ${PWD_OLD}/$0 /usr/local/bin/$0
			if [ -f /usr/local/bin/$0 ]; then
				chmod +x /usr/local/bin/$0
				echo "0 0 * * *	root	bash /usr/local/bin/$0 --domain $NEW_UPDATER " >> /etc/crontab
			fi
		fi
	fi

