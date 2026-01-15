FROM debian:bookworm-slim

WORKDIR /app

# Copy RustFS binary (built via Makefile)
COPY ./rustfs-binary /usr/local/bin/rustfs

# Copy config
COPY config/config.toml /etc/rustfs/config.toml

# Mount host volume for persistent storage
VOLUME ["/data/rustfs"]

EXPOSE 8080 9090

CMD ["rustfs", "--config", "/etc/rustfs/config.toml"]
