ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=python-3.10
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /
COPY root .

RUN apt-get update
# This is necessary because by default Poetry creates a virtual environment, which we don't want in production
RUN $POETRY_HOME/bin/poetry config virtualenvs.create false
RUN apt-get install -y graphviz libgraphviz-dev vim poppler-utils git
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
# Upgrade Node.js first
RUN conda install -c conda-forge nodejs=20 -y

RUN npm i -g @openai/codex
RUN npm i -g @anthropic-ai/claude-code

# Copy poetry files to container
COPY pyproject.toml poetry.lock $POETRY_HOME/
# Run `poetry install`
RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry lock

RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry install --no-interaction --no-ansi --no-root --no-cache --extras "agents rag"
RUN pip install --upgrade jupyter
RUN pip install --upgrade ipywidgets
RUN pip install 'jupyter-ai==3.0.0b7' 'jupyter-ai-magics==3.0.0b7' 'jupyter-ai-litellm==0.0.2' 'jupyterlab-chat==0.17.0' 'langgraph' 'openpyxl'

# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]
