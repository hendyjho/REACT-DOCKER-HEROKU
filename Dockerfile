FROM python:3.8-slim AS compile-image
WORKDIR /app


RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update \
    && apt-get install --no-install-recommends --no-install-suggests --no-upgrade build-essential -y gcc git \
    && apt-get clean autoclean && rm -rf /var/lib/apt/lists/*

RUN pip3 install --ignore-installed distlib pipenv
RUN python3 -m venv /app/venv

ENV PATH="/app/venv/bin:$PATH" VIRTUAL_ENV="/app/venv"

COPY requirements.txt .
RUN pip3 install -r requirements.txt


FROM python:3.8-slim AS execute
WORKDIR /app

ENV PATH="/app/venv/bin:$PATH" VIRTUAL_ENV="/app/venv" LANG=C.UTF-8 DEBIAN_FRONTEND=noninteractive

COPY set.sh .
RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update \
    && apt-get install --no-install-recommends --no-install-suggests --no-upgrade build-essential -y gnupg2 \
    wget \
    curl \
    busybox \
    unzip \
    tar \
    xz-utils \
    && apt-get clean autoclean && rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://ftp-master.debian.org/keys/archive-key-10.asc | apt-key add - \
    && sh -c 'echo deb http://deb.debian.org/debian buster main contrib non-free | tee -a /etc/apt/sources.list' \
    && bash set.sh \
    && apt update \
    && apt install --no-install-recommends -y unrar \
    && apt-get clean autoclean && rm -rf /var/lib/apt/lists/* /app/rclone-* /app/ffmpeg-* /app/aria2-*

COPY --from=compile-image /app/venv venv
COPY . .

CMD ["python3", "-m", "bot"]
