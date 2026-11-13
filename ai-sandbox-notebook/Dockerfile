FROM docker.io/library/minimal-poetry-notebook

USER root

WORKDIR /

RUN apt-get update
# This is necessary because by default Poetry creates a virtual environment, which we don't want in production
RUN $POETRY_HOME/bin/poetry config virtualenvs.create false
RUN apt-get install -y graphviz libgraphviz-dev vim poppler-utils git
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
# claude-agent-acp requires Node.js 22+
RUN conda install -c conda-forge nodejs=26 -y

RUN npm i -g @openai/codex
RUN npm i -g @anthropic-ai/claude-code
# jupyter-ai only enables its @Claude and @Codex chat personas when these ACP adapters are on PATH.
RUN npm i -g @agentclientprotocol/claude-agent-acp@0.106.0 @agentclientprotocol/codex-acp@2.6.0

# Skills and plugins live outside $HOME, since $HOME is the user's mounted volume at runtime.
# Claude Code loads the Slack plugin, which carries the Slack MCP server, from CLAUDE_CODE_PLUGIN_DIRS on every
# start, including jupyter-ai's @Claude sessions. Slack's Codex plugin ships only the skills, so Codex gets those.
ENV CLAUDE_CODE_PLUGIN_DIRS=/opt/claude-plugins
RUN git clone -q --depth 1 --branch v1.7.0 https://github.com/slackapi/slack-skills-plugin $CLAUDE_CODE_PLUGIN_DIRS/slack && \
    rm -rf $CLAUDE_CODE_PLUGIN_DIRS/slack/.git && \
    git clone -q https://github.com/langchain-ai/langchain-skills /tmp/langchain-skills && \
    git -C /tmp/langchain-skills checkout -q 79f69154930ae1bc62a74a495ede558391861710 && \
    mkdir -p /etc/claude-code/.claude/skills /etc/codex/skills && \
    cp -r /tmp/langchain-skills/config/skills/* /etc/claude-code/.claude/skills/ && \
    cp -r /tmp/langchain-skills/config/skills/* $CLAUDE_CODE_PLUGIN_DIRS/slack/skills/* /etc/codex/skills/ && \
    rm -rf /tmp/langchain-skills

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

COPY root .

USER $NB_USER

CMD ["/init.sh"]
