FROM containers.renci.org/helxplatform/jupyter/docker-stacks/minimal-notebook:cuda-202309182143

USER root

# Update available packages in the package index
RUN apt update -y

# Add ppa for git install later
RUN sudo apt-get install software-properties-common -y && \
    sudo add-apt-repository ppa:git-core/ppa

# These packages are necessary for some Poetry packages to correctly install later (like xmlsec) and LDAP
RUN apt-get install -y pkg-config libxml2-dev libxmlsec1-dev \
    libxmlsec1-openssl curl git libc-bin locales libcurl3-gnutls libnss-ldap

# These packages are necessary for psycopg2 to be installed later
RUN apt-get install -y build-essential python3-dev libpq-dev libpq-dev

# Install psycopg2 using regular pip
RUN pip install psycopg2

# Fix vulnerabilities with old packages
RUN apt-get upgrade -y libaom3 openexr zlib1g-dev

# Install pipx
RUN python3 -m pip install pipx && pipx ensurepath

# Set $POETRY_HOME env var for child images to reference and add it to the $PATH
ENV POETRY_HOME="/${HOME}/.local"
ENV PATH="${POETRY_HOME}/bin:$PATH"

# Install Poetry
RUN pipx install poetry==2.1.1

# Install Poetry's bundle plugin to install cleanly in a virtual environment
RUN pipx inject poetry poetry-plugin-bundle

# Make sure poetry is installed
RUN poetry --version

COPY root /

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]