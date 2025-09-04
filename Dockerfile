# Dockerfile
FROM python:3.12-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential tini git && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USER=app
ARG UID=1000
RUN useradd -m -u ${UID} ${USER}

WORKDIR /work
COPY requirements.txt /work/requirements.txt

# Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Run as non-root from here on
USER ${USER}

# Jupyter port (for clarity)
EXPOSE 8888

# Proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# JupyterLab with no token/password; modern flags
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--ServerApp.token=", "--ServerApp.password="]
