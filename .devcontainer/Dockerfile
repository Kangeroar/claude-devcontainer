FROM node:22-trixie-slim

ARG TZ
ENV TZ="$TZ"

RUN dpkg --add-architecture i386

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  wget \
  curl \
  openjdk-21-jdk \
  libc6:i386 \
  libncurses6:i386 \
  libstdc++6:i386 \
  libz1 \
  && apt install -y tmux \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -L https://services.gradle.org/distributions/gradle-9.1.0-bin.zip -o gradle-9.1.0-bin.zip
RUN apt-get install -y unzip
RUN unzip gradle-9.1.0-bin.zip
RUN /bin/bash -c "source $HOME/.bashrc"

ENV GRADLE_HOME=/gradle-9.1.0
ENV PATH=$PATH:$GRADLE_HOME/bin

ENV ANDROID_SDK_TOOLS=14742923
ENV ANDROID_SDK_URL=https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS}_latest.zip
ENV ANDROID_HOME=/usr/local/android-sdk-linux
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/bin

# Set user to root for necessary permissions
RUN echo 'root:Docker!' | chpasswd
USER root
# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip curl && \
    mkdir "$ANDROID_HOME" .android && \
    cd "$ANDROID_HOME" && \
    curl -o sdk.zip $ANDROID_SDK_URL && \
    unzip sdk.zip && \
    rm sdk.zip && \
# Install Fastlane
    apt-get install --no-install-recommends -y --allow-unauthenticated build-essential git ruby-full && \
    gem install rake && \
    gem install fastlane && \
    gem install bundler && \
    gem install screengrab && \
# Clean up
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get autoremove -y && \
    apt-get clean

ENV ANDROID_BUILD_TOOLS_VERSION_34=34.0.0
ENV ANDROID_VERSION_34=34

# Download Android SDK 34
RUN yes | sdkmanager --licenses --sdk_root=$ANDROID_HOME && \
    sdkmanager --update --sdk_root=$ANDROID_HOME && \
    sdkmanager --sdk_root=$ANDROID_HOME "build-tools;${ANDROID_BUILD_TOOLS_VERSION_34}" \
    "platforms;android-${ANDROID_VERSION_34}" \
    "platform-tools" \
    "extras;android;m2repository" \
    "extras;google;m2repository"


ENV ANDROID_BUILD_TOOLS_VERSION_35=35.0.0
ENV ANDROID_VERSION_35=35

# Download Android SDK 35
RUN yes | sdkmanager --licenses --sdk_root=$ANDROID_HOME && \
    sdkmanager --update --sdk_root=$ANDROID_HOME && \
    sdkmanager --sdk_root=$ANDROID_HOME "build-tools;${ANDROID_BUILD_TOOLS_VERSION_35}" \
    "platforms;android-${ANDROID_VERSION_35}" \
    "platform-tools" \
    "extras;android;m2repository" \
    "extras;google;m2repository"

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace && \
  chown -R node:node /workspace

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

RUN ARCH=$(dpkg --print-architecture) && \
    apt-get update && apt-get install -y --no-install-recommends zstd && \
    curl -L -o /tmp/ollama.tar.zst -H "User-Agent: Mozilla/5.0" "https://github.com/ollama/ollama/releases/latest/download/ollama-linux-${ARCH}.tar.zst" && \
    tar -xf /tmp/ollama.tar.zst -C /usr/local/bin && \
    rm /tmp/ollama.tar.zst && \
    apt-get autoremove -y zstd && apt-get clean

ENV PATH=$PATH:/usr/local/bin/bin/

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Pi
RUN npm install -g @mariozechner/pi-coding-agent
RUN npm install -g skills

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/

USER root

RUN sed -i 's/\r$//' /usr/local/bin/init-firewall.sh && \
  chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

USER node
