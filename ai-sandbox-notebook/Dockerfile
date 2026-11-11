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
RUN cd $POETRY_HOME && $POETRY_HOME/bin/poetry install --no-interaction --no-ansi --no-root --no-cache --extras "agents rag"
RUN pip install --upgrade jupyter
RUN pip install \
    'jupyter-ai[jupyternaut,magics,rtc]==3.2.0' \
    'jupyter-ai-jupyternaut==0.1.0' \
    'jupyter-ai-magic-commands==0.0.4' \
    'jupyter-ai-litellm==0.1.0' \
    'jupyterlab-chat==0.25.1' \
    'jupyter-ydoc<3.5.0' \
    'jupyter-server-ydoc<2.4.1'

# RSNA Anonymizer pins numpy<2, so it gets its own environment and kernel.
# torch, torchvision and their CUDA libraries are not installed into it; it uses
# the notebook environment's copies via --system-site-packages, and the assert
# fails the build if those drift from the versions in rsna-anonymizer/uv.lock.
COPY rsna-anonymizer /opt/rsna-anonymizer
RUN cd /opt/rsna-anonymizer && \
    uv venv --system-site-packages --python $CONDA_DIR/bin/python .venv && \
    uv sync --frozen --no-cache --python $CONDA_DIR/bin/python \
        $(sed -En 's/^name = "(torch|torchvision|triton|nvidia-.*)"$/--no-install-package \1/p' uv.lock) && \
    .venv/bin/python -c "import torch, torchvision; assert (torch.__version__, torchvision.__version__) == ('2.5.1+cu121', '0.20.1+cu121'), (torch.__version__, torchvision.__version__)" && \
    ln -s /opt/rsna-anonymizer/.venv/bin/rsna-anonymizer /usr/local/bin/rsna-anonymizer && \
    .venv/bin/python -m ipykernel install --prefix $CONDA_DIR --name rsna-anonymizer --display-name "RSNA Anonymizer"

# Remove Poetry files from container, as they're no longer needed
RUN rm $POETRY_HOME/pyproject.toml $POETRY_HOME/poetry.lock

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER

CMD ["/init.sh"]
