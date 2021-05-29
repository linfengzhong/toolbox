cd /home/linfengzhong/git/repos/toolbox/
sleep 1
git pull
sleep 1
cp -rf /home/linfengzhong/git/repos/toolbox/Docker/docker-compose/all-in-one/ /home/linfengzhong/
sleep 1
sudo chown -R linfengzhong:linfengzhong /home/linfengzhong/all-in-one/
sleep 1
cd /home/linfengzhong/all-in-one/
sleep 1
sudo docker-compose up -d