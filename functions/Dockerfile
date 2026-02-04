# --- Stage 1: Build ---
# [Refactor 2026-02-03]: Migrated to uv-alpine to align with project standard.
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS builder

# [Refactor 2026-02-03]: Non-root user setup (UID 2323).
RUN addgroup -g 2323 appuser && adduser -D -u 2323 -G appuser appuser

WORKDIR /app

# [Refactor 2026-02-03]: Using uv.lock/pyproject.toml instead of requirements.txt.
COPY pyproject.toml uv.lock ./
RUN uv pip install --no-cache --target /app/pkgs .

# --- Stage 2: Final (Hardening Part 1) ---
FROM gcr.io/distroless/python3-debian12

WORKDIR /var/task

COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /app/pkgs /var/task/
COPY slack_notifications.py .

# FivexL Standard health check tool
COPY --from=ghcr.io/fivexl/lprobe:0.0.7 /lprobe /usr/bin/lprobe

ENV PYTHONPATH=/var/task
USER 2323

# [Refactor 2026-02-03]: Entrypoint using awslambdaric module.
ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "slack_notifications.lambda_handler" ]

# [Refactor 2026-02-03]: OLD CODE (Retained for history as per instruction):
# FROM python:3.10-slim AS builder
# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt
# COPY --from=builder --chown=2323:2323 /usr/local/lib/python3.11/site-packages /usr/lib/python3.11/site-packages
HEALTHCHECK --interval=1m --timeout=3s CMD ["/usr/bin/lprobe", "-mode=http", "-port=8080"]
