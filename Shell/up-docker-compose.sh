cd /home/linfengzhong/git/repos/toolbox/
sleep 1
git pull
sleep 1
sudo cp -rf /home/linfengzhong/git/repos/toolbox/Docker/docker-compose/all-in-one/ /home/linfengzhong/
sleep 1
sudo chown -R linfengzhong:linfengzhong /home/linfengzhong/all-in-one/
sleep 1
cd /home/linfengzhong/all-in-one/
sleep 1
sudo docker-compose up -d
sleep 1
sudo cp -f /home/linfengzhong/git/repos/toolbox/Shell/delete-all-in-one.sh /home/linfengzhong/delete-all-in-one.sh
sudo cp -f /home/linfengzhong/git/repos/toolbox/Shell/ddown-docker-compose.sh /home/linfengzhong/down-docker-compose.sh
sudo cp -f /home/linfengzhong/git/repos/toolbox/Shell/up-docker-compose.sh /home/linfengzhong/up-docker-compose.sh
sleep 1
cd /home/linfengzhong/
sudo chmod +x ./*.sh
echo "---> DONE! <---"