# Android Dockerfile

FROM ubuntu:14.04

LABEL maintainer="Mobile Builds Eng <mobile-builds-eng@uber.com>"

ARG ANDROID_COMPONENTS="platform-tools,android-23,build-tools-23.0.2,build-tools-24.0.0"

# Sets language to UTF8: this works in pretty much all cases
ENV LANG en_US.UTF-8
RUN locale-gen $LANG

ENV DOCKER_ANDROID_LANG en_US
ENV DOCKER_ANDROID_DISPLAY_NAME mobileci-docker

# Never ask for confirmations
ENV DEBIAN_FRONTEND noninteractive

# Installing packages
# Install Java
# Clean Up Apt-get
RUN apt-get update && apt-get install -y --no-install-recommends \
  autoconf \
  build-essential \
  bzip2 \
  curl \
  gcc \
  git \
  groff \
  lib32stdc++6 \
  lib32z1 \
  lib32z1-dev \
  lib32ncurses5 \
  lib32bz2-1.0 \
  libc6-dev \
  libgmp-dev \
  libmpc-dev \
  libmpfr-dev \
  libxslt-dev \
  libxml2-dev \
  m4 \
  make \
  ncurses-dev \
  ocaml \
  openssh-client \
  pkg-config \
  python-software-properties \
  rsync \
  software-properties-common \
  unzip \
  wget \
  zip \
  zlib1g-dev \
  && apt-add-repository ppa:openjdk-r/ppa \
  && apt-get update \
  && apt-get -y install openjdk-8-jdk \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# Install Android SDK
RUN mkdir -p /tmp/android-sdk \
  && cd /tmp/android-sdk \
  && wget https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz \
  && tar -xvzf android-sdk_r24.4.1-linux.tgz \
  && mv android-sdk-linux /usr/local/android-sdk \
  && rm android-sdk_r24.4.1-linux.tgz \
  && echo y | /usr/local/android-sdk/tools/android update sdk --filter "$ANDROID_COMPONENTS" --no-ui -a \
  && rm -rf /tmp/android-sdk

# Install Android NDK
RUN mkdir -p /tmp/android-ndk \
  && cd /tmp/android-ndk \
  && wget http://dl.google.com/android/repository/android-ndk-r12-linux-x86_64.zip \
  && unzip android-ndk-r12-linux-x86_64.zip \
  && mv android-ndk-r12 /usr/local/android-ndk \
  && rm android-ndk-r12-linux-x86_64.zip \
  && rm -rf /tmp/android-ndk

# Environment variables
ENV ANDROID_HOME /usr/local/android-sdk
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV ANDROID_NDK_HOME /usr/local/android-ndk
ENV JENKINS_HOME $HOME
ENV PATH ${INFER_HOME}/bin:${PATH}
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/23.0.2
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/24.0.0
ENV PATH $PATH:$ANDROID_NDK_HOME

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms4096m -Xmx4096m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

# Add build user account, values are set to default below
ENV RUN_USER mobileci
ENV RUN_UID 5089

RUN id $RUN_USER || adduser --uid "$RUN_UID" \
    --gecos 'Build User' \
    --shell '/bin/sh' \
    --disabled-login \
    --disabled-password "$RUN_USER"

# Fix permissions
RUN chown -R $RUN_USER:$RUN_USER $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME
RUN chmod -R a+rx $ANDROID_HOME $ANDROID_SDK_HOME $ANDROID_NDK_HOME

# Creating project directories prepared for build when running
# `docker run`
ENV PROJECT /project
RUN mkdir $PROJECT
RUN chown -R $RUN_USER:$RUN_USER $PROJECT
WORKDIR $PROJECT

USER $RUN_USER
RUN echo "sdk.dir=$ANDROID_HOME" > local.properties
