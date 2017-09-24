mkdir -p /opt/helloworld/

cd /opt/helloworld

wget https://github.com/ChristofferKarlsson/compute-engine-workshop/raw/files/helloworld.jar
wget https://github.com/ChristofferKarlsson/compute-engine-workshop/raw/files/start.sh
wget https://github.com/ChristofferKarlsson/compute-engine-workshop/raw/files/helloworld.sh
wget https://github.com/ChristofferKarlsson/compute-engine-workshop/raw/files/nginx-default

chmod +x helloworld.sh start.sh
mv helloworld.sh /etc/init.d/helloworld
mv start.sh start

systemctl daemon-reload

service helloworld start

mv nginx-default /etc/nginx/sites-available/default

service nginx reload
