FROM node
LABEL maintainer="Nazar Mokrynskyi <nazar@mokrynskyi.com>"

COPY bin /code/bin
COPY src /code/src
COPY package.json /code

WORKDIR /code

RUN npm install --production

EXPOSE 16882/tcp
# Both environment variables are required for proper operation
CMD node bin/detox-bootstrap-node.js $SEED 0.0.0.0 $DOMAIN
