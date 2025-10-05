FROM ballerina/ballerina:2201.10.0

# Set working directory
WORKDIR /home/ballerina

# Copy the project files
COPY . .

# Build the Ballerina project
RUN bal build --offline

# Expose the service port
EXPOSE 8082

# Run the service
CMD ["bal", "run", "transport_service.jar"]
