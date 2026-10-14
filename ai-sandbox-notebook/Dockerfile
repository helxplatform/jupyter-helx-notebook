ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=latest
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /
COPY root .

RUN apt-get update
# This is necessary because by default Poetry creates a virtual environment, which we don't want in production
RUN $POETRY_HOME/bin/poetry config virtualenvs.create false
RUN apt-get install -y graphviz libgraphviz-dev vim poppler-utils git
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
# Upgrade Node.js first. Node 20 is EOL and @anthropic-ai/claude-code needs >=22.
# The npm bundled with Node lags behind; update it so its vendored deps (tar,
# minimatch, brace-expansion, ...) pick up security fixes. Then drop the conda
# package cache, which otherwise keeps a second copy of the old npm around.
RUN conda install -c conda-forge nodejs=24 -y && \
    npm i -g npm@11 && \
    npm cache clean --force && \
    conda clean -afy

RUN npm i -g @openai/codex
RUN npm i -g @anthropic-ai/claude-code

# Copy poetry files to container
COPY pyproject.toml poetry.lock $POETRY_HOME/
RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry install --no-interaction --no-ansi --no-root --no-cache --extras "agents rag"
RUN pip install --upgrade jupyter
RUN pip install --upgrade ipywidgets
RUN pip install \
    'jupyter-ai==3.0.0b7' \
    'jupyter-ai-magics==3.0.0b7' \
    'jupyter-ai-litellm==0.1.0' \
    'jupyterlab-chat==0.17.0' \
    'jupyter-ydoc<3.5.0' \
    'jupyter-server-ydoc<2.4.1'

# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]
