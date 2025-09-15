-- Create database for Express API service
CREATE DATABASE IF NOT EXISTS express_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges to the microservices user
GRANT ALL PRIVILEGES ON laravel_auth.* TO 'microservices_user'@'%';
GRANT ALL PRIVILEGES ON laravel_catalog.* TO 'microservices_user'@'%';
GRANT ALL PRIVILEGES ON express_api.* TO 'microservices_user'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
