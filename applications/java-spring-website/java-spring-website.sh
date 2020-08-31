#!/usr/bin/env bash

# Stop Script on Error
set -e

# For Debugging (print env. variables into a file)  
printenv > /var/log/colony-vars-"$(basename "$BASH_SOURCE" .sh)".txt

# Update packages and Upgrade system
echo "****************************************************************"
echo "Updating System"
echo "****************************************************************"
apt-get update -y


echo "****************************************************************"
echo "Installing Java"
echo "****************************************************************"
apt-get install default-jdk -y



echo "****************************************************************"
echo "Installing Tomcat"
echo "****************************************************************"
apt-get install tomcat8 -y
apt-get install tomcat8-admin -y


echo "****************************************************************"
echo "Get the web application from github"
echo "****************************************************************"
mkdir /home/artifacts
cd /home/artifacts || exit

git clone https://github.com/cloudshell-colony/sample_java_spring_source.git


echo "****************************************************************"
echo "Prepare the environment configuration file that will be consumed by the servlet"
echo "****************************************************************"
mkdir /home/user/.config/colony-java-spring-sample -p

if [ "$DB_HOSTNAME" == "none" ]; then
    DB_HOSTNAME="mysql.$DOMAIN_NAME"
fi

jdbc_url=jdbc:mysql://$DB_HOSTNAME/$DB_NAME
if [ "$USE_SSL" = true ]; then
    jdbc_url="${jdbc_url}?useSSL=true"
fi

bash -c "cat >> /home/user/.config/colony-java-spring-sample/app.properties" <<EOL
# Dadabase connection settings:
jdbc.url=$jdbc_url
jdbc.username=$DB_USER
jdbc.password=$DB_PASS
EOL

echo "****************************************************************"
echo "Deploy to TomCat"
echo "****************************************************************"
#remove the tomcat default ROOT web application
rm -rf /var/lib/tomcat8/webapps/ROOT

# deploy the application as the ROOT web application

if ls $ARTIFACTS_PATH/java-spring-sample*.war 1> /dev/null 2>&1; then
    cp $(find $ARTIFACTS_PATH -name 'java-spring-sample*.war') /var/lib/tomcat8/webapps/ROOT.war >/dev/null
else
	cp sample_java_spring_source/artifacts/colony-java-spring-sample-1.0.0-BUILD-SNAPSHOT.war /var/lib/tomcat8/webapps/ROOT.war
fi

systemctl start tomcat8
