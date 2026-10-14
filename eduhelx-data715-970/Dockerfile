ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/helx-notebook/jupyter-lab-student
ARG BASE_IMAGE_TAG=latest
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /
COPY root .

# This is necessary because by default Poetry creates a virtual environment, which we don't want in production
RUN $POETRY_HOME/bin/poetry config virtualenvs.create false
# Install one package at a time. Poetry reinstalls many packages that conda already
# provides, and doing that in parallel intermittently crashes pip (SIGBUS) here.
RUN $POETRY_HOME/bin/poetry config installer.parallel false
# Copy poetry files to container
COPY pyproject.toml poetry.lock $POETRY_HOME/
# Run `poetry install`
RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry install --no-interaction --no-ansi --no-root
# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER
