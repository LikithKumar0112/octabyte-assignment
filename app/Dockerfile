# Builde stage: install deps into environment
FROM python:3.12-slim as builder
WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --upgrade pip \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

# runtime stage: copy deps from builder and app code
FROM python:3.12-slim as runtime
RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app --no-create-home app
WORKDIR /app
COPY --from=builder /venv /venv
COPY src ./src
ENV PATH="/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PORT=8000
USER 1001:1001
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
