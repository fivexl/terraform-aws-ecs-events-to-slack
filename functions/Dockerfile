# Stage 1: Builder
FROM python:3.11-slim AS builder
WORKDIR /app

# Create the User 2323 Explicitly
RUN groupadd -g 2323 appuser && \
    useradd -r -u 2323 -g appuser appuser

# Install only necessary runtime dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# Stage 2: Production (Distroless)
FROM gcr.io/distroless/python3-debian12

WORKDIR /var/task

# Copy User Definitions
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# 1. Copy libraries with correct ownership for UID 2323
COPY --from=builder --chown=2323:2323 /usr/local/lib/python3.11/site-packages /usr/lib/python3.11/site-packages
COPY --from=builder --chown=2323:2323 /usr/local/bin /usr/local/bin

# 2. Copy application code with correct ownership
COPY --chown=2323:2323 . .

# 3. Add lprobe for health checks (Anton's Request)
COPY --from=ghcr.io/fivexl/lprobe:0.0.7 --chown=2323:2323 /lprobe /usr/bin/lprobe

# 4. Set Python path
ENV PYTHONPATH=/usr/lib/python3.11/site-packages

# 5. HARDENING: Run as non-root user (Anton's 1:04 PM Request)
USER 2323

# 6. Runtime Interface Client
ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "slack_notifications.lambda_handler" ]