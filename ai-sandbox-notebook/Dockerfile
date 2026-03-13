ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=python-3.10
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /
# COPY root .

RUN apt-get update
# This is necessary because by default Poetry creates a virtual environment, which we don't want in production
RUN $POETRY_HOME/bin/poetry config virtualenvs.create false
RUN apt-get install -y graphviz libgraphviz-dev vim poppler-utils
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN mkdir -p /usr/local/lib/node_modules && \
    chmod -R 777 /usr/local/lib/node_modules && \
    chmod -R 777 /usr/local/bin && \
    npm i -g @openai/codex
# RUN npm i -g @openai/codex
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# Copy poetry files to container
COPY pyproject.toml poetry.lock $POETRY_HOME/
# Run `poetry install`
RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry lock

RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry install --no-interaction --no-ansi --no-root --no-cache --extras "agents rag jupyter-ai"
RUN pip install --upgrade jupyter
RUN pip install --upgrade ipywidgets
# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER
