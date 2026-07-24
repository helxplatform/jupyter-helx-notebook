FROM docker.io/library/minimal-poetry-notebook

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
RUN pip install \
    'jupyter-ai==3.0.0b7' \
    'jupyter-ai-magics==3.0.0b7' \
    'jupyterlab-chat==0.17.0' \
    'jupyter-ydoc==3.1.0' \
    'pyopenssl==25.3.0'

# jupyter-ai-litellm 0.0.2 caps litellm<=1.82.6 only because that was the
# newest release when it was published; it imports just two stable litellm
# attributes. pyproject and semantic-router 0.1.15 require litellm>=1.83.7,
# so install it without deps to keep it from downgrading litellm. Its real
# deps (jupyter-server, litellm) are already installed above.
RUN pip install --no-deps 'jupyter-ai-litellm==0.0.2'

# pipx (installed unpinned in the base image) now requires platformdirs>=4.6,
# but the poetry resolution above lands 4.3.8. Nothing in the environment caps
# platformdirs, so lift it to satisfy pipx instead of whitelisting the conflict.
RUN pip install --upgrade 'platformdirs>=4.6'

# The RTC stack (jupyter-collaboration & friends) is pinned in the
# minimal-poetry-notebook base and must not drift here: the collab broker runs
# the base image, and version skew between user pods and the broker breaks
# shared-document rooms. The poetry install and `pip install --upgrade` lines
# above can silently move shared dependencies, so fail the build on conflicts.
# The single tolerated conflict is jupyter-ai-litellm's stale litellm cap
# (see --no-deps install above).
RUN pip check > /tmp/pip-check.txt 2>&1 || true; \
    cat /tmp/pip-check.txt; \
    if grep -v 'jupyter-ai-litellm' /tmp/pip-check.txt | grep -q 'requirement'; then \
        echo 'ERROR: unexpected dependency conflicts (see above)'; exit 1; \
    fi

# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]
