# --- Stage 1: Builder ---
# We use a full python image to install dependencies
FROM python:3.10-slim AS builder

# Install uv (The FivexL standard package manager)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Copy dependency files first to leverage Docker cache
COPY functions/pyproject.toml functions/uv.lock ./

# Install dependencies into a virtual environment
# --frozen ensures we use the exact lockfile versions
RUN uv venv /opt/venv && \
    uv sync --frozen --no-dev

# --- Stage 2: Runtime ---
# Hardening Part 1: Use a lean base image (or 'distroless' if ready)
FROM python:3.10-slim-bookworm

# Hardening Part 2: Always use a non-root user (UID 2323)
RUN groupadd -g 2323 appuser && \
    useradd -r -u 2323 -g appuser appuser

WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv
COPY functions/slack_notifications.py .

# Ensure the app user owns the files
RUN chown -R appuser:appuser /app

# Use the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

USER appuser

# Hardening Part 3: Set filesystem to Read-Only (handled at orchestrator level)
# ENTRYPOINT depends on if this is Lambda or ECS
CMD ["slack_notifications.lambda_handler"]
