FROM ghcr.io/astral-sh/uv:0.5.24-python3.12-alpine AS builder
RUN addgroup -g 2323 appuser && adduser -D -u 2323 -G appuser appuser
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv pip install --no-cache --target /app/pkgs .

FROM gcr.io/distroless/python3-debian12@sha256:773950b73c22421c97a5b3a8a30a1c35a639735d56411516086f6e52c80326e3
WORKDIR /var/task
COPY --from=builder /etc/passwd /etc/group /etc/
COPY --from=builder /app/pkgs /var/task/
COPY slack_notifications.py .
COPY --from=ghcr.io/fivexl/lprobe:0.0.7 /lprobe /usr/bin/lprobe
ENV PYTHONPATH=/var/task
USER 2323
ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "slack_notifications.lambda_handler" ]
HEALTHCHECK --interval=1m --timeout=3s CMD ["/usr/bin/lprobe", "-mode=http", "-port=8080"]
