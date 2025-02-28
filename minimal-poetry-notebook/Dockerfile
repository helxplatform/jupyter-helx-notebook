FROM containers.renci.org/helxplatform/jupyter/docker-stacks/minimal-notebook:cuda-202309182143

USER root

# Update available packages in the package index
RUN apt update -y

# Add ppa for git install later
RUN sudo apt-get install software-properties-common -y && \
    sudo add-apt-repository ppa:git-core/ppa

# These packages are necessary for some Poetry packages to correctly install later (like xmlsec)
RUN apt-get install -y pkg-config libxml2-dev libxmlsec1-dev libxmlsec1-openssl curl git libc-bin locales libcurl3-gnutls

# These packages are necessary for psycopg2 to be installed later
RUN apt-get install -y build-essential python3-dev libpq-dev libpq-dev

# Install psycopg2 using regular pip
RUN pip install psycopg2

ENV POETRY_CONFIG_DIR=/opt/poetry/.config \
    POETRY_HOME=/opt/poetry \
    POETRY_CACHE_DIR=/opt/poetry/.cache \
    POETRY_VERSION=1.8.3

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

COPY root /

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]