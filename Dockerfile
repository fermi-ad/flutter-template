# Use NGINX as the base image
FROM nginx:1.23

# Copy built web files to container
COPY ./build/web /usr/share/nginx/html

# Serve the wasm build's .mjs module as JavaScript (see the file).
COPY ./docker/mime.conf /etc/nginx/conf.d/mime.conf

# The NGINX container exposes port 80 by default
# and starts automatically, so there's no need
# to specify an entrypoint or command.
