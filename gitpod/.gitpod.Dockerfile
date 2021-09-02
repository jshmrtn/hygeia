FROM gitpod/workspace-base

SHELL ["/bin/bash", "-c"]

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN install-packages software-properties-common




### C/C++ compiler and associated tools ###

LABEL dazzle/layer=lang-c

USER root

ENV TRIGGER_REBUILD=1

RUN curl -o /var/lib/apt/dazzle-marks/llvm.gpg -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
    && apt-key add /var/lib/apt/dazzle-marks/llvm.gpg \
    && echo "deb https://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list.d/llvm.list \
    && install-packages \
    clang \
    clangd \
    clang-format \
    clang-tidy \
    gdb \
    gcc \
    lld \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    libncurses-dev \
    openjdk-11-jdk




### Docker ###

LABEL dazzle/layer=tool-docker

USER root

ENV TRIGGER_REBUILD=2

# https://docs.docker.com/engine/install/ubuntu/
RUN curl -o /var/lib/apt/dazzle-marks/docker.gpg -fsSL https://download.docker.com/linux/ubuntu/gpg \
    && apt-key add /var/lib/apt/dazzle-marks/docker.gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && install-packages docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io

RUN curl -o /usr/bin/slirp4netns -fsSL https://github.com/rootless-containers/slirp4netns/releases/download/v1.1.11/slirp4netns-$(uname -m) \
    && chmod +x /usr/bin/slirp4netns

RUN curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

# https://github.com/wagoodman/dive
RUN curl -o /tmp/dive.deb -fsSL https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb \
    && apt install /tmp/dive.deb \
    && rm /tmp/dive.deb




### Project Root ###

LABEL dazzle/layer=project-root

USER root

ENV TRIGGER_REBUILD=3

RUN devDeps='zsh curl' && \
    install-packages $devDeps

RUN chsh -s "$(which zsh)" gitpod




### Project User ###

LABEL dazzle/layer=project-user

USER gitpod

ENV TRIGGER_REBUILD=4

ENV PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$HOME/.asdf/completions:$PATH"

COPY .tool-versions .tool-versions

# ZSH Setup
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone --depth=1 https://github.com/zsh-users/zsh-completions $HOME/.oh-my-zsh/custom/plugins/zsh-completions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search $HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search
RUN /usr/bin/zsh -ic 'omz plugin enable debian cp gcloud git-extras gitignore postgres ubuntu dotenv zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search'

ENV SHELL=zsh

# Install asdf
RUN git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf --branch v0.8.1

# Install nodejs plugin
RUN asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git && \
    $HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring

# Install erlang plugin
RUN asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git

RUN erlangDeps='build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk' && \
    sudo install-packages $erlangDeps 

# Install elixir plugin
RUN asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install deps
COPY .tool-versions .tool-versions
RUN asdf install




### Project Specific ###

LABEL dazzle/layer=project-specific

USER root

ENV TRIGGER_REBUILD=5

RUN buildDeps='binutils curl' && \
    set -x && \
    (echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections) && \
    install-packages $buildDeps wget xorg xz-utils fontconfig libxrender1 libxext6 libx11-6 openssl xfonts-base ttf-mscorefonts-installer xfonts-75dpi && \
    curl -L https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb -o wkhtmltopdf.deb && \
    install-packages ./wkhtmltopdf.deb && \
    rm ./wkhtmltopdf.deb && \
    apt-get purge -qq --auto-remove $buildDeps




### Prologue (built across all layers) ###

LABEL dazzle/layer=dazzle-prologue

USER root

ENV TRIGGER_REBUILD=6

RUN prologueDeps='curl' && \
    install-packages $prologueDeps

RUN curl -o /usr/bin/dazzle-util -fsSL https://github.com/csweichel/dazzle/releases/download/v0.0.3/dazzle-util_0.0.3_Linux_x86_64 \
    && chmod +x /usr/bin/dazzle-util
# merge dpkg status files
RUN cp /var/lib/dpkg/status /tmp/dpkg-status \
    && for i in $(ls /var/lib/apt/dazzle-marks/*.status); do /usr/bin/dazzle-util debian dpkg-status-merge /tmp/dpkg-status $i > /tmp/dpkg-status; done \
    && cp -f /var/lib/dpkg/status /var/lib/dpkg/status-old \
    && cp -f /tmp/dpkg-status /var/lib/dpkg/status
# correct the path as per https://github.com/gitpod-io/gitpod/issues/4508
ENV PATH=$PATH:/usr/games
# merge GPG keys for trusted APT repositories
RUN for i in $(ls /var/lib/apt/dazzle-marks/*.gpg); do apt-key add "$i"; done
