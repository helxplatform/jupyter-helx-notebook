ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=latest
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /

# This turns off oneDNN custom operations, so that we don't see slightly different 
# numerical results due to floating-point round-off errors from different computation orders
ENV TF_ENABLE_ONEDNN_OPTS=0 \
    TF_CPP_MIN_LOG_LEVEL='2' \
    HOME_DIR=/home/jovyan

# The extension is only published as source, and building its labextension needs
# Node.js. The base image doesn't ship Node, so install it just for this step and
# remove it afterwards to keep it (and its CVEs) out of the final image.
RUN mamba install -y -n base -c conda-forge nodejs=22 && \
    pip install --no-cache-dir git+https://github.com/helxplatform/eduhelx-jupyterlab-student-ext.git && \
    mamba remove -y -n base nodejs && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"
RUN jupyter server extension enable eduhelx_jupyterlab_student

RUN pip install --upgrade git+https://github.com/helxplatform/eduhelx-utils.git

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER