# Base Dockerfile for Ballerina Microservices
# This Dockerfile can be copied to each service directory

FROM ballerina/ballerina:2201.8.5

# Set working directory
WORKDIR /app

# Copy Ballerina.toml first for better caching
COPY Ballerina.toml .

# Copy Dependencies.toml if it exists
COPY Dependencies.toml* ./

# Copy source files
COPY *.bal ./

# Build the Ballerina application
RUN bal build

# Expose the service port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["bal", "run"]
