# Use Node.js 20 LTS
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install Yarn if not present
RUN corepack enable && corepack prepare yarn@stable --activate

# Copy only package manifests for each Mercur subproject to leverage Docker cache.
# If these files change, deps will be reinstalled; otherwise this layer is cached.
COPY app/admin-panel/package.json app/admin-panel/yarn.lock ./admin-panel/
COPY app/backend/package.json app/backend/yarn.lock ./backend/
COPY app/storefront/package.json app/storefront/yarn.lock ./storefront/
COPY app/vendor-panel/package.json app/vendor-panel/yarn.lock ./vendor-panel/

# Install dependencies for each subproject based on the copied manifests.
RUN set -eux; \
    for d in admin-panel backend storefront vendor-panel; do \
      if [ -f "$d/package.json" ]; then \
        echo "Installing dependencies in /app/$d"; \
        if [ -f "$d/yarn.lock" ]; then \
          (cd "$d" && yarn install --frozen-lockfile); \
        else \
          (cd "$d" && yarn install); \
        fi; \
      else \
        echo "No package.json in /app/$d, skipping"; \
      fi; \
    done

# Now copy the rest of the application source. This is done after deps are installed
# so that changes to source files don't invalidate the dependency cache.
COPY app/ .

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

# Copy node_modules and project files from deps stage (which already contains /app)
COPY --from=deps /app .

# Set environment to production
ENV NODE_ENV=production

# Build application (if needed)
# RUN yarn build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 medusa

# Copy prepared application from builder (includes node_modules and project files)
COPY --from=builder --chown=medusa:nodejs /app .

# Switch to non-root user
USER medusa

# Expose port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:9000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["yarn", "start"]
