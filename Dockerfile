FROM python:3.8.2-slim
MAINTAINER Hooram Nam <nhooram@gmail.com>

ENV MAPZEN_API_KEY mapzen-XXXX
ENV MAPBOX_API_KEY mapbox-XXXX
ENV ALLOWED_HOSTS=*

RUN apt-get update && \
    apt-get install -y \
    nginx \
    cmake \
    build-essential \
    libpq-dev \
    libffi-dev \
    libblas-dev \
    liblapack-dev \
    libglib2.0-0 \
    gfortran \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /code
WORKDIR /code
COPY . /code

# install prerequirements
RUN pip install -r prerequirements.txt && \
    rm -rf ~/.cache/pip
# install requirements
RUN pip install -r requirements.txt && \
    rm -rf ~/.cache/pip

RUN python -m spacy download en_core_web_sm

WORKDIR /code/api/places365
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/places365_model.tar.gz && \
    tar xf places365_model.tar.gz && \
    rm places365_model.tar.gz

WORKDIR /code/api/im2txt
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_model.tar.gz && \
    tar xf im2txt_model.tar.gz && \
    rm im2txt_model.tar.gz
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_data.tar.gz && \
    tar xf im2txt_data.tar.gz && \
    rm im2txt_data.tar.gz

VOLUME /data

# Application admin creds
ENV ADMIN_EMAIL admin@dot.com
ENV ADMIN_USERNAME admin
ENV ADMIN_PASSWORD changeme

# Django key. CHANGEME
ENV SECRET_KEY supersecretkey
# Until we serve media files properly (django dev server doesn't serve media files with with debug=false)
ENV DEBUG true 

# Database connection info
ENV DB_BACKEND postgresql
ENV DB_NAME ownphotos
ENV DB_USER ownphotos
ENV DB_PASS ownphotos
ENV DB_HOST database
ENV DB_PORT 5432

ENV BACKEND_HOST localhost
ENV FRONTEND_HOST localhost

# REDIS location
ENV REDIS_HOST redis
ENV REDIS_PORT 11211

# Timezone
ENV TIME_ZONE UTC

EXPOSE 80

RUN mv /code/config_docker.py /code/config.py

WORKDIR /code

ENTRYPOINT ./entrypoint.sh
