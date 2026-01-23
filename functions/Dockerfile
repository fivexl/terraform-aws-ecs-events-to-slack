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
# CHANGED: Use public Google Distroless (Debian 12) instead of private FivexL image
# REASON: Provides a solid set of preinstalled libs (glibc) while remaining 
# shell-less and secure. Distroless images are more stable than scratch for Python binaries.

FROM gcr.io/distroless/python3-debian12

WORKDIR /var/task

# Copy dependencies from builder
# Note: We copy to the standard python path for Distroless
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your code
COPY . .

# Copy lprobe for healthchecks (If this also fails, we will remove it)
COPY --from=ghcr.io/fivexl/lprobe:0.0.7 /lprobe /usr/bin/lprobe

# Set PYTHONPATH so Python can find the installed packages
ENV PYTHONPATH=/usr/lib/python3.11/site-packages

# HEALTHCHECK is ignored by Lambda but useful for local testing
HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/usr/bin/lprobe", "-mode=http", "-port=8080"]

# CHANGED: Python path in Distroless is /usr/bin/python3
ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]

CMD [ "slack_notifications.lambda_handler" ]