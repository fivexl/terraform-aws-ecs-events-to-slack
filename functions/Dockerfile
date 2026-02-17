FROM ghcr.io/astral-sh/uv:0.9.5 AS uv

# First, bundle the dependencies into the task root
FROM public.ecr.aws/lambda/python:3.10 AS builder

# Enable bytecode compilation for better cold-start performance
ENV UV_COMPILE_BYTECODE=1

# Disable installer metadata to create a deterministic layer
ENV UV_NO_INSTALLER_METADATA=1

# Enable copy mode to support bind mount caching
ENV UV_LINK_MODE=copy

# Bundle the dependencies into the Lambda task root
# Convert lock file to requirements.txt, then install to target
# This ensures Docker layer cache is only invalidated when pyproject.toml or uv.lock change
RUN --mount=from=uv,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=/tmp/src/pyproject.toml \
    --mount=type=bind,source=uv.lock,target=/tmp/src/uv.lock \
    cd /tmp/src && \
    uv export --frozen --no-emit-workspace --no-dev --no-editable -o requirements.txt && \
    uv pip install --python-platform linux --target "${LAMBDA_TASK_ROOT}" -r requirements.txt

FROM public.ecr.aws/lambda/python:3.10

# Copy the runtime dependencies from the builder stage with proper ownership
COPY --from=builder --chown=1000:1000 ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}

# Copy the application code with proper ownership for non-root user
COPY --chown=1000:1000 slack_notifications.py ${LAMBDA_TASK_ROOT}/

# Run as non-root user for security
USER 1000

# Set the AWS Lambda handler
CMD ["slack_notifications.lambda_handler"]
