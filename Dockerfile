# Author : Yann-Aël Le Borgne - https://yannael.github.io/

FROM node:10.20.1-jessie

USER node

WORKDIR /home/node

RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh \
    && chmod a+x Anaconda3-2020.02-Linux-x86_64.sh \
    && bash Anaconda3-2020.02-Linux-x86_64.sh -b

# RUN git clone https://github.com/reichlab/covid19-forecast-hub
COPY --chown=node . /home/node/covid19-forecast-hub/

RUN echo "export PATH=/home/node/anaconda3/bin:$PATH" >> /home/node/.bashrc

RUN ln -s /home/node/anaconda3/bin/pip /home/node/anaconda3/bin/pip3

ENV PATH /home/node/anaconda3/bin:$PATH

WORKDIR /home/node/covid19-forecast-hub/visualization
RUN bash ./one-time-setup.sh
RUN bash ./0-init-vis.sh
RUN bash ./1-patch-vis.sh
RUN bash ./2-build-vis.sh

WORKDIR /home/node/covid19-forecast-hub/visualization/vis-master/dist

ENTRYPOINT python3 -m http.server



