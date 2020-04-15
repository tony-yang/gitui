FROM ubuntu
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    cmake \
    git \
    libffi-dev \
    libsqlite3-dev \
    libssl-dev \
    nodejs \
    pkg-config \
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
