#!/bin/sh

USERNAME=$1
CONDA_ENV=$2
WHEEL=$3
DASK_SCHEDULER_IP=$4
TYPE=$5
JUPYTER_Token="test"

echo "Installing wheel..."
sudo -u $USERNAME -i /bin/bash -l -c "conda init bash"
sudo -u $USERNAME -i /bin/bash -l -c "conda activate $CONDA_ENV; pip install $WHEEL"

echo "Setting up service scripts..."
cat > /home/$USERNAME/dask-head.sh << EOM
#!/bin/bash
conda activate $CONDA_ENV

NUM_GPUS=\`nvidia-smi -L | wc -l\`

dask-scheduler

jupyter lab --ip 0.0.0.0 --port 8888 --NotebookApp.token=$JUPYTER_Token --allow-root --no-browser
EOM

cat > /home/$USERNAME/dask-worker.sh << EOM
#!/bin/bash
conda activate $CONDA_ENV

NUM_GPUS=\`nvidia-smi -L | wc -l\`

dask-worker tcp://$DASK_SCHEDULER_IP:8786
EOM

chmod +x /home/$USERNAME/dask-scheduler.sh
chmod +x /home/$USERNAME/dask-worker.sh

cat > /lib/systemd/system/dask.service << EOM
[Unit]
   Description=Dask
[Service]
   Type=simple
   User=$USERNAME
   ExecStart=/bin/bash -l /home/$USERNAME/dask-$TYPE.sh
[Install]
WantedBy=multi-user.target
EOM

echo "Configure dask to start at boot..."
systemctl enable dask

echo "Starting dask..."
systemctl start dask
