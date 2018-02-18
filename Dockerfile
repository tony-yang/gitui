FROM ubuntu
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libffi-dev \
    libsqlite3-dev \
    nodejs \
    sqlite3 \
    ruby \
    ruby-dev \
    ruby-bundler \
    tcl \
    vim \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && gem install rails

WORKDIR /root

ADD . /root/gitui

EXPOSE 11111

CMD ["/root/gitui/gitui-starter.sh"]
