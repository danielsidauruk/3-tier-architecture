#!/bin/bash
set -e
set -o pipefail

sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv wget

sudo rm -rf "${REPO_CLONE_DIR}"
git clone "${REPO_URL}" "${REPO_CLONE_DIR}"

sudo mkdir -p "${APP_INSTALL_DIR}"
sudo cp -r "${REPO_CLONE_DIR}/src/app/backend/." "${APP_INSTALL_DIR}/"
sudo rm -rf "${REPO_CLONE_DIR}"

cd "${APP_INSTALL_DIR}"

if [ ! -d "env" ]; then
    python3 -m venv env
fi

source env/bin/activate

if [ ! -f "global-bundle.pem" ]; then
    echo "  > global-bundle.pem not found, downloading..."
    wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem
else
    echo "  > global-bundle.pem already exists, skipping download."
fi

pip install -r requirements.txt

sudo mkdir -p "${LOG_DIR}"
sudo chown -R "ubuntu":"ubuntu" "${LOG_DIR}"
sudo chmod -R 755 "${LOG_DIR}"

echo "  > Creating Gunicorn service script: ${APP_INSTALL_DIR}/start_gunicorn.sh"

sudo bash -c "cat > ${APP_INSTALL_DIR}/start_gunicorn.sh" << EOL
#!/bin/bash

cd "${APP_INSTALL_DIR}" || exit 1

source env/bin/activate || exit 1

exec gunicorn \
  --workers 3 \
  --bind "0.0.0.0:${BACKEND_PORT}" \
  --access-logfile "${LOG_DIR}/gunicorn_access.log" \
  --error-logfile "${LOG_DIR}/gunicorn_error.log" \
  "main:app"
EOL
sudo chmod +x "${APP_INSTALL_DIR}/start_gunicorn.sh"

sudo bash -c "cat > /etc/systemd/system/flask_backend.service" << EOL
[Unit]
Description=Gunicorn instance to serve Flask backend
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=${APP_INSTALL_DIR}
ExecStart=${APP_INSTALL_DIR}/start_gunicorn.sh

Restart=always

Environment="MONGODB_ENDPOINT=${MONGODB_ENDPOINT}"
Environment="MONGODB_PORT=${MONGODB_PORT}"
Environment="REDIS_PRIMARY_ENDPOINT=${REDIS_PRIMARY_ENDPOINT}"
Environment="REDIS_READER_ENDPOINT=${REDIS_READER_ENDPOINT}"
Environment="REDIS_PORT=${REDIS_PORT}"
Environment="MONGODB_USER=${MONGODB_USER}"
Environment="SECRET_NAME=${SECRET_NAME}"
Environment="PRIMARY_REGION=${PRIMARY_REGION}"

StandardOutput=append: ${LOG_DIR}/gunicorn_stdout.log
StandardError=append:${LOG_DIR}/gunicorn_stderr.log

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload 
sudo systemctl enable flask_backend
sudo systemctl restart flask_backend

echo "--- Flask Backend Application Deployment Complete! ---"
