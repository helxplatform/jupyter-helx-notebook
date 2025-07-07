ARG BASE_IMAGE=containers.renci.org/helxplatform/jupyter/docker-stacks/minimal-poetry-notebook
ARG BASE_IMAGE_TAG=security-upgrades
FROM $BASE_IMAGE:$BASE_IMAGE_TAG

USER root
COPY root /

# These are installed in scipy-notebook: pandas scikit-learn scipy seaborn sqlalchemy statsmodels
RUN apt-get update && apt-get -y upgrade && apt-get -y install pkg-config && \
    mamba install --yes \
        matplotlib \
        psycopg \
        pyodbc \
        pyperformance \
        numpy \
        tableone \
        xgboost

RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home" && \
    chmod 664 /etc/group

USER $NB_USER
WORKDIR /
CMD ["/init.sh"]
