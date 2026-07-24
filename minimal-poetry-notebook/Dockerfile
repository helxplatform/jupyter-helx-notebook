FROM containers.renci.org/helxplatform/jupyter/docker-stacks/minimal-notebook:3.10

USER root

# Update available packages in the package index
RUN apt-get update && apt-get upgrade -y

# Add ppa for git install later
RUN sudo apt-get install software-properties-common -y && \
    sudo add-apt-repository ppa:git-core/ppa

# These packages are necessary for some Poetry packages to correctly install later (like xmlsec) and LDAP
RUN apt-get install -y pkg-config libxml2-dev libxmlsec1-dev \
    libxmlsec1-openssl curl git libc-bin locales libcurl3-gnutls libnss-ldap \
    unixodbc-dev gcc g++

# These packages are necessary for psycopg2 to be installed later
RUN apt-get install -y build-essential python3-dev libpq-dev libpq-dev

# Install psycopg2 using regular pip
RUN pip install psycopg2

# Fix vulnerabilities with old packages
RUN apt-get upgrade -y libaom3 openexr zlib1g-dev

# Update certificates
RUN curl -L https://curl.se/ca/cacert.pem -o /usr/local/share/ca-certificates/mozilla-latest.crt && \
    update-ca-certificates --fresh


# Install pipx
RUN python3 -m pip install pipx && pipx ensurepath

# Set $POETRY_HOME env var for child images to reference and add it to the $PATH
ENV POETRY_HOME="${HOME}/.local"
ENV PATH="${POETRY_HOME}/bin:$PATH"

# Install Poetry
RUN pipx install poetry==2.1.1

# Install Poetry's bundle plugin to install cleanly in a virtual environment
RUN pipx inject poetry poetry-plugin-bundle

# Make sure poetry is installed
RUN poetry --version

# Pin the JupyterLab real-time collaboration (RTC) stack. These versions must
# stay in lockstep across all derived notebook images and the collab broker
# deployment (helx-chart/charts/jupyter-collab-broker), which runs this image:
# ydoc schema or fileid behavior skew between user pods and the broker breaks
# shared-document rooms.
RUN pip install \
    'jupyterlab==4.4.7' \
    'jupyter-collaboration==4.2.1' \
    'jupyter-server-ydoc==2.2.1' \
    'jupyter-docprovider==2.4.1' \
    'jupyter-collaboration-ui==2.4.1' \
    'jupyter-ydoc==3.1.0' \
    'jupyter-server-fileid==0.9.3' \
    'pycrdt-websocket==0.16.0' \
    'jupyterlab-chat==0.17.0'

COPY root /

# Install the helx python helpers (helx_identity, helx_fileid) into
# site-packages so they are importable by every python process without
# depending on PYTHONPATH surviving the pod's runtime environment (init.sh
# still exports PYTHONPATH=/helx/lib as a fallback). helx_fileid is used by the
# collaboration broker; helx_identity by the notebook servers.
RUN cp /helx/lib/*.py "$(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')/"

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]