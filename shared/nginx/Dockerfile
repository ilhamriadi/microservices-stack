FROM nginx:alpine

# Install necessary packages
RUN apk add --no-cache openssl

# Create directories for logs and SSL
RUN mkdir -p /var/log/nginx /etc/nginx/ssl

# Copy nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Generate self-signed SSL certificate (replace with real certificate in production)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=YourCompany/CN=156.67.24.197"

# Set proper permissions
RUN chmod 600 /etc/nginx/ssl/nginx.key
RUN chmod 644 /etc/nginx/ssl/nginx.crt

# Expose ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
