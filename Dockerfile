FROM python:3.7-alpine


# set working directory
RUN mkdir /src
WORKDIR /src 

# install and cache app dependencies
# COPY . /src/

# This requires a whole new dockerfile based on ubuntu bionic:
# RUN pip install -r requirements.txt && python setup.py build develop

# Just installing pika for rabbitmq demonstration purposes
RUN pip install pika
