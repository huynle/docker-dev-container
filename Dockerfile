# our local base image
# Shut off VPN, and remove http_proxy from docker configuration
FROM ubuntu:18.04

LABEL description="Container for use for EFI" 
ARG USER_NAME=dev
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID
ARG GROUP_NAME=$GROUP_NAME

# install build dependencies 
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Denver
# set the variables as per $(pyenv init -)
ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN apt-get update && apt-get install -y \
  rsync \
  build-essential \
  openssh-server \
  tmux \
  gdb \
  gcc \
  g++ \
  clang-format \
  neovim \
  git \
  sudo \
  zsh \
  wget \
  ca-certificates \
  curl \
  git \
  libbz2-dev \
  libffi-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl1.0-dev \
  liblzma-dev \
  # libssl-dev \
  make \
  netbase \
  pkg-config \
  xz-utils \
  zlib1g-dev

RUN apt-get install -y python3-pip python3-virtualenv

RUN update-ca-certificates

RUN apt-get install -y software-properties-common && add-apt-repository ppa:neovim-ppa/stable && apt-get update && apt-get install -y neovim

RUN apt-get autoremove -y \
  && apt-get clean -y

# configure SSH for communication with Visual Studio 
RUN mkdir -p /var/run/sshd

RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \ 
   ssh-keygen -A 

# expose port 22 
EXPOSE 22

# Setup the default user.
# RUN useradd -rm -d /home/$USER_NAME -s /usr/bin/zsh -g root -G sudo $USER_NAME -p 1234
RUN useradd -rm -d /home/$USER_NAME -s /usr/bin/zsh -G sudo $USER_NAME
RUN echo "${USER_NAME}:1234" | chpasswd
# [Optional] Update UID/GID if needed
RUN if [ "$GROUP_ID" != "1000" ] || [ "$USER_ID" != "1000" ]; then \
      groupmod --gid $GROUP_ID $USER_NAME \
      && usermod --uid $USER_ID --gid $GROUP_ID $USER_NAME \
      && chown -R $USER_ID:$GROUP_ID /home/$USER_NAME; \
      fi

USER $USER_NAME
WORKDIR /home/$USER_NAME
ENV GIT_SSL_NO_VERIFY 1

ENV HOME /home/$USER_NAME
RUN git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv

RUN pyenv install 3.6.8
# RUN pyenv global 3.6.8
# RUN pyenv rehash

# RUN python3 -m venv $HOME/.cache/vim/venv/neovim
RUN pyenv virtualenv 3.6.8 neovim
COPY req-nvim.txt $HOME/req-nvim.txt
RUN $PYENV_ROOT/versions/neovim/bin/pip install -r $HOME/req-nvim.txt
RUN mkdir -p $HOME/.cache/vim
RUN echo "one" > $HOME/.cache/vim/theme.txt
RUN echo "dark" >> $HOME/.cache/vim/theme.txt

RUN pyenv virtualenv 3.6.8 efi_test
COPY efi-req.txt $HOME/efi-req.txt
RUN $PYENV_ROOT/versions/efi_test/bin/pip install -r $HOME/efi-req.txt


USER root
# CMD ["/usr/bin/sudo", "/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]
ENTRYPOINT service ssh restart && tail -f /dev/null

