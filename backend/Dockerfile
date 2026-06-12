# Stage 1: Build dependencies
FROM python:3.11-slim as builder

WORKDIR /app

COPY requirements.txt .

# Install dependencies globally in /usr/local
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final runtime image
FROM python:3.11-slim as runner

WORKDIR /app

# Create a system group and user to run the app securely
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser

# Copy installed libraries globally from builder
COPY --from=builder /usr/local /usr/local
# Copy source files, changing ownership to the unprivileged appuser
COPY --chown=appuser:appgroup . /app

RUN chmod +x entrypoint.sh

# Ensure PYTHONUNBUFFERED is set
ENV PYTHONUNBUFFERED=1

# Run the container as the non-root appuser
USER appuser

EXPOSE 8000

CMD ["sh", "entrypoint.sh"]
