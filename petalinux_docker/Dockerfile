FROM ubuntu:18.04

# Не спрашивать вопросы при установке
ENV DEBIAN_FRONTEND=noninteractive

# Обновление и установка зависимостей для PetaLinux 2019.1
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    iproute2 gawk python python3 python3-pexpect build-essential gcc git make net-tools \
    libncurses5-dev zlib1g-dev libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath \
    socat xterm autoconf libtool tar unzip texinfo gcc-multilib automake screen pax gzip cpio \
    python-pip python3-pip python-git python3-git python-jinja2 python3-jinja2 \
    zlib1g:i386 libstdc++6:i386 libgtk2.0-0:i386 libcanberra-gtk-module:i386 \
    libsdl1.2-dev libegl1-mesa pylint rsync u-boot-tools \
    locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Переключить /bin/sh на bash
RUN echo "dash dash/sh boolean false" | debconf-set-selections && dpkg-reconfigure -p critical dash

# Рабочая директория
WORKDIR /mnt/work

CMD ["/bin/bash"]
