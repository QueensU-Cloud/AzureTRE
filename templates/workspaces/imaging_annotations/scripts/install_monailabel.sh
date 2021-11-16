#!/bin/bash
###DRAFT###
set -e
su - adminuser <<END
cd ~
pip install monailabel --progress-bar off
monailabel apps --download --name deepedit --output apps
monailabel datasets --download --name Task02_Heart --output datasets
END

tee -a /etc/systemd/system/monailabel.service << END
[Unit]
Description=MonaiLabel Server
Wants=network-online.target
After=network-online.target

[Service]
User=adminuser
WorkingDirectory=/home/adminuser
ExecStart=/anaconda/envs/py38_default/bin/python3.8 -m monailabel.main start_server --app apps/deepedit --studies datasets/Task02_Heart/imagesTr --port 8008
Environment="PYTHONPATH=/anaconda/envs"
Environment="PATH=$PATH:/anaconda/envs/py38_default/bin"

[Install]
WantedBy=multiuser.target
END

systemctl daemon-reload
systemctl enable monailabel.service
systemctl start monailabel.service
