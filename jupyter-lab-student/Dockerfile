ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=v0.0.5
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root

WORKDIR /

# This turns off oneDNN custom operations, so that we don't see slightly different 
# numerical results due to floating-point round-off errors from different computation orders
ENV TF_ENABLE_ONEDNN_OPTS=0 \
    TF_CPP_MIN_LOG_LEVEL='2' \
    HOME_DIR=/home/jovyan

RUN pip install git+https://github.com/helxplatform/eduhelx-jupyterlab-student-ext.git
RUN jupyter server extension enable eduhelx_jupyterlab_student

RUN pip install --upgrade git+https://github.com/helxplatform/eduhelx-utils.git

RUN fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER