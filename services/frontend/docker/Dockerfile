# Multi-stage build for production
FROM node:18-alpine AS builder

# Build arguments
ARG VITE_API_URL
ARG VITE_AUTH_URL
ARG VITE_CATALOG_URL

# Set environment variables
ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_AUTH_URL=${VITE_AUTH_URL}
ENV VITE_CATALOG_URL=${VITE_CATALOG_URL}

# Set working directory
WORKDIR /app

# Copy package files
COPY src/package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src/ .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Install Node.js for serving (if using Vite preview)
RUN apk add --no-cache nodejs npm

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy source code for development serving (optional)
COPY --from=builder /app /app
WORKDIR /app

# Create entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 3000

# Use custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "3000"]
