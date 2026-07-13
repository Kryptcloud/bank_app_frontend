# STAGE 1: THE COMPILATION BUILDER
# ====================================================
FROM node:18-alpine AS builder
WORKDIR /app
ENV NODE_OPTIONS=--openssl-legacy-provider

#Dependency conflict resolution:
ENV CI=false 

# Copy dependency mappings first to maximize Docker layer caching
COPY package*.json ./
RUN npm ci --legacy-peer-deps

# Copy your actual JavaScript source files into the builder container
COPY . .


# Compile the React/JS source down into 100% pure static web assets
# This drops all backend dependencies and builds a minimal 'build' folder
RUN npm run build

# ===================================================
# STAGE 2: THE SECURE RUNTIME WEB SERVER
# ===================================================
FROM nginx:stable-alpine

# Copy the compiled static assets directly into Nginx's default hosting directory
# NOTE: Standard React applications output their production code to a folder named 'build'
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom Nginx config to support React Router client-side routing
# (falls back to index.html for any unmatched path instead of 404ing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose Port 80 to align with our production Kubernetes NodePort mapping rules
# (Instead of development port 3000)
EXPOSE 80

# Launch Nginx in the foreground to keep the Kubernetes Pod tracking loop alive
CMD ["nginx", "-g", "daemon off;"]