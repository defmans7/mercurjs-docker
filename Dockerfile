# Use Node.js 20 LTS
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install Yarn if not present
RUN corepack enable && corepack prepare yarn@stable --activate

# Copy repository files early so mercur-cli can read config and generate package files
COPY . .

# Install mercur-cli globally and run it to generate package.json / lock files (if the project uses mercurjs-cli)
# After that, install dependencies. Prefer frozen lockfile if yarn.lock exists.
RUN npm install -g mercur-cli && \
    mercur-cli install && \
    if [ -f yarn.lock ]; then yarn install --frozen-lockfile; elif [ -f package.json ]; then yarn install; fi

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

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

# Copy necessary files
COPY --from=builder --chown=medusa:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=medusa:nodejs /app/package.json ./package.json
COPY --from=builder --chown=medusa:nodejs /app/medusa-config.ts ./medusa-config.ts
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
