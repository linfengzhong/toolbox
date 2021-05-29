cd ~/git/toolbox/
sleep 1
git pull
sleep 1
sudo cp -rf ~/git/toolbox/Docker/docker-compose/all-in-one/ ~/
sleep 1
sudo chown -R root:root ~/all-in-one/
sleep 1
cd ~/all-in-one/
sleep 1
sudo docker-compose build
sleep 1
sudo docker-compose up -d
sleep 1
sudo cp -f ~/git/toolbox/Shell/delete-all-in-one.sh ~/delete-all-in-one.sh
sudo cp -f ~/git/toolbox/Shell/down-docker-compose.sh ~/down-docker-compose.sh
sudo cp -f ~/git/toolbox/Shell/up-docker-compose.sh ~/up-docker-compose.sh
sleep 1
cd ~
sudo chmod +x ./*.sh
echo "---> DONE! <---"