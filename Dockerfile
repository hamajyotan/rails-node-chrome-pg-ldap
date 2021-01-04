FROM ruby:2.6.2

ENV LANG C.UTF-8

RUN apt-get update -qq && apt-get install -q -y --no-install-recommends \
    build-essential zlib1g-dev libxslt-dev libxml2-dev libssl-dev locales libfontconfig1 unzip \
    vim lsb-release xvfb xauth fonts-takao fonts-takao-gothic fonts-takao-mincho \
    && rm -rf /var/lib/apt/lists/*

# localize.
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && dpkg-reconfigure -f noninteractive tzdata \
    && perl -p -i -e 's/^# ja_JP.UTF-8 UTF-8$/ja_JP.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=ja_JP.UTF-8 \
    && dpkg-reconfigure --frontend noninteractive locales \
    && fc-cache -fv

# entrykit
ENV ENTRYKIT_VERSION 0.4.0
RUN wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
    && tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
    && rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
    && mv entrykit /bin/entrykit \
    && chmod +x /bin/entrykit \
    && entrykit --symlink

# postgresql client
# RUN apt-get install -y --no-install-recommends psql
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends postgresql-client-9.6

# LDAP client.
RUN apt-get -qqy install ldap-utils

# node, npm, yarn
ENV NODEJS_VERSION v10.15.2
ENV YARN_VERSION 1.13.0
RUN mkdir /usr/local/lib/nodejs \
    && wget https://nodejs.org/dist/${NODEJS_VERSION}/node-${NODEJS_VERSION}-linux-x64.tar.xz \
    && tar -xJvf node-${NODEJS_VERSION}-linux-x64.tar.xz -C /usr/local/lib/nodejs \
    && rm node-${NODEJS_VERSION}-linux-x64.tar.xz \
    && mv /usr/local/lib/nodejs/node-${NODEJS_VERSION}-linux-x64 /usr/local/lib/nodejs/node-${NODEJS_VERSION}
ENV NODEJS_HOME=/usr/local/lib/nodejs/node-${NODEJS_VERSION}/bin
ENV PATH $NODEJS_HOME:$PATH
RUN npm install -g yarn@${YARN_VERSION}

# google chrome
RUN wget -q --no-check-certificate https://dl-ssl.google.com/linux/linux_signing_key.pub \
    && apt-key add linux_signing_key.pub \
    && rm linux_signing_key.pub \
    && sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/chrome.list' \
    && apt -y update && apt -y install google-chrome-stable

# create user.
RUN useradd rails
RUN mkdir -p /home/rails && chown -R rails:rails /home/rails

# application directory.
RUN mkdir /app
WORKDIR /app
RUN bundle config build.nokogiri --use-system-libraries

ENV DISPLAY :99
ENV EDITOR vim

USER rails

