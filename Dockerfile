# Use the latest official Debian image as a base
FROM debian:latest

# Metadata to describe the maintainer of the image
LABEL maintainer="Prajwal Koirala <prajwalkoirala23@protonmail.com>"

# Install necessary packages (curl) and clean up unnecessary files to keep the image smaller
RUN apt-get update && \
    apt-get install -y curl

# Copy the local Unbound configuration file to the container
COPY unbound-manager.sh /usr/local/bin/unbound-manager.sh

# Make the unbound-manager.sh script executable
RUN chmod +x /usr/local/bin/unbound-manager.sh

# Run the unbound-manager.sh script to install Unbound and configure it
RUN /usr/local/bin/unbound-manager.sh

# Expose port 53 for DNS services (both TCP and UDP)
EXPOSE 53/tcp 53/udp

# Keep the container running with Unbound as the foreground process
CMD ["unbound"]