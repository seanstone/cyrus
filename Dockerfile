FROM base/devel:latest

RUN pacman --noconfirm -Syu && pacman --noconfirm -S wget cpio python unzip rsync bc git ccache

RUN useradd --create-home builduser && \
    echo 'builduser ALL=(ALL) NOPASSWD: ALL' \
    | EDITOR='tee -a' visudo

USER builduser
WORKDIR /home/builduser
