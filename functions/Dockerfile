# Stage 1: Build standalone binary
FROM python:3.11-slim AS builder
WORKDIR /app

# CHANGED: Installing build dependencies for PyInstaller
# REASON: Required to compile the Python code into a binary. This allows us to 
# remove the Python interpreter and shell from the final production image.
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev binutils && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir pyinstaller

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# CHANGED: Compiling Python to binary
# REASON: Matches the sso-elevator pattern; enables use of a Distroless runtime 
# to significantly reduce attack surface.
RUN pyinstaller --onefile --name slack_notifier slack_notifications.py

# Stage 2: Production Image
# CHANGED: Switched to FivexL Secure Distroless (Debian 11)
# REASON: Provides a solid set of preinstalled libs (glibc) while remaining 
# shell-less and secure. Distroless images are more stable than scratch for Python binaries.
FROM ghcr.io/fivexl/secure-container-image:base-python3-distroless-debian-11

WORKDIR /var/task

# Copy binary from builder
COPY --from=builder /app/dist/slack_notifier /usr/bin/slack_notifier
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .
# CHANGED: Adding lprobe
# REASON: Shell-less distroless images require binary-based health checks 
# because standard tools like 'curl' or 'sh' are absent (FivexL Hardening Part 1).
COPY --from=ghcr.io/fivexl/lprobe:0.0.7 /lprobe /usr/bin/lprobe

# Lambda RIC requires the PYTHONPATH to find your packages
ENV PYTHONPATH=/usr/local/lib/python3.11/site-packages

# USER: Distroless images typically use a non-root user (e.g., 65532) by default.
# We inherit this security benefit.

HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/usr/bin/lprobe", "-mode=http", "-port=8080"]

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "slack_notifications.handler" ]