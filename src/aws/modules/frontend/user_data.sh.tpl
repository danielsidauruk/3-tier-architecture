#!/bin/bash

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

echo "Setting up frontend..."

sudo apt-get update && sudo apt-get install -y nginx git

sudo systemctl start nginx
sudo systemctl enable nginx

sudo rm -f "/etc/nginx/sites-enabled/default"

sudo rm -rf "${REPO_CLONE_DIR}" "${NGINX_WEB_ROOT}"
git clone "${REPO_URL}" "${REPO_CLONE_DIR}"

if [ ! -d "${APP_SOURCE_DIR}" ]; then
    echo "Error: Application source directory not found at $APP_SOURCE_DIR"
    echo "Listing contents of cloned repository for debugging:"
    ls -la "${REPO_CLONE_DIR}"
    exit 1
fi

sudo mkdir -p "${NGINX_WEB_ROOT}"
sudo cp -r "${APP_SOURCE_DIR}/." "${NGINX_WEB_ROOT}/"

sudo chown -R www-data:www-data "${NGINX_WEB_ROOT}"
sudo chmod -R 755 "${NGINX_WEB_ROOT}"

sudo bash -c "cat > ${NGINX_SITE_CONF}" << EOL
server {
    listen 80 default_server;
    server_name _;

    root ${NGINX_WEB_ROOT};
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://${BACKEND_DNS}:${BACKEND_PORT}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    error_page 404 /404.html;
    location = /404.html {
        root ${NGINX_WEB_ROOT};
        internal;
    }

    access_log /var/log/nginx/frontend_access.log;
    error_log /var/log/nginx/frontend_error.log;
}
EOL

sudo nginx -t
echo "Restarting Nginx service..."
sudo systemctl restart nginx

echo "Frontend setup complete."
