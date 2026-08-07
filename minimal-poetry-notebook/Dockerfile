###############################################################################
# Stage 1: builder
#
# psycopg2 is the only thing in this image that has to be compiled from source.
# The toolchain it needs (build-essential -> gcc -> libc6-dev -> linux-libc-dev)
# tends to introduce a large number (1k+) CVEs, so we want to keep them out of the
# final image
###############################################################################
FROM quay.io/jupyter/minimal-notebook:latest AS builder

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential python3-dev libpq-dev \
 && rm -rf /var/lib/apt/lists/*

RUN pip wheel --no-deps --wheel-dir /wheels psycopg2

###############################################################################
# Stage 2: runtime
###############################################################################
FROM quay.io/jupyter/minimal-notebook:latest

USER root

# Update available packages in the package index
RUN apt-get update && apt-get upgrade -y

# Add the git ppa, then drop software-properties-common again
RUN apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get purge -y --auto-remove software-properties-common

# Runtime shared libraries only. The matching -dev packages are build-time artifacts.
RUN apt-get install -y --no-install-recommends \
      curl libc-bin locales libcurl3-gnutls libnss-ldap \
      libpq5 libxml2 libxslt1.1 libxmlsec1t64 libodbc2 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install psycopg2 from the wheel built in stage 1 (links against libpq5)
RUN --mount=from=builder,source=/wheels,target=/wheels \
    pip install --no-cache-dir --no-index --find-links=/wheels psycopg2

# Update certificates
RUN curl -L https://curl.se/ca/cacert.pem -o /usr/local/share/ca-certificates/mozilla-latest.crt && \
    update-ca-certificates --fresh

# Install pipx
RUN python3 -m pip install --no-cache-dir pipx && pipx ensurepath

# Set $POETRY_HOME env var for child images to reference and add it to the $PATH
ENV POETRY_HOME="${HOME}/.local"
ENV PATH="${POETRY_HOME}/bin:$PATH"

# Install Poetry
RUN pipx install poetry==2.4.1

# Install Poetry's bundle plugin to install cleanly in a virtual environment
RUN pipx inject poetry poetry-plugin-bundle

# Make sure poetry is installed
RUN poetry --version

# Vulnerability fix
# nbclassic is the deprecated Notebook 6 UI. docker-stacks explicitly installs it,
# but nothing really depends on it, and the tree (nbclassic) UI is no longer in use.
# Could be added back just for the sake of supporting /tree (if a user were to want it)
# once downstream requirements have vuln fixes.
RUN mamba remove -y --force nbclassic && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

COPY root /

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]
