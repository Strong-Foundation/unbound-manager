# Use the latest official Debian image as a base
FROM debian:latest

# Metadata to describe the maintainer of the image
LABEL maintainer="Prajwal Koirala <prajwalkoirala23@protonmail.com>"

# Install necessary packages (curl) and clean up unnecessary files to keep the image smaller
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    # Clean up cached files to reduce the size of the image
    rm -rf /var/lib/apt/lists/*

# Download and set up the Unbound Manager script from the GitHub repository
RUN curl -sSL https://raw.githubusercontent.com/Strong-Foundation/unbound-manager/refs/heads/main/unbound-manager.sh -o /usr/local/bin/unbound-manager.sh && \
    # Ensure the script is executable
    chmod +x /usr/local/bin/unbound-manager.sh

# Expose port 53 for DNS services (both TCP and UDP)
EXPOSE 53/tcp 53/udp