FROM python:3.11-slim AS builder
WORKDIR /app


RUN groupadd -g 2323 appuser && \
    useradd -r -u 2323 -g appuser appuser


COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt



FROM gcr.io/distroless/python3-debian12

WORKDIR /var/task


COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group


COPY --from=builder --chown=2323:2323 /usr/local/lib/python3.11/site-packages /usr/lib/python3.11/site-packages
COPY --from=builder --chown=2323:2323 /usr/local/bin /usr/local/bin


COPY --chown=2323:2323 . .


COPY --from=ghcr.io/fivexl/lprobe:0.0.7 --chown=2323:2323 /lprobe /usr/bin/lprobe


ENV PYTHONPATH=/usr/lib/python3.11/site-packages


USER 2323


ENTRYPOINT [ "/usr/bin/python3", "-m", "awslambdaric" ]
CMD [ "slack_notifications.lambda_handler" ]