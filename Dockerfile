FROM ubuntu:14.04
MAINTAINER Marvin Winkler <marvambass@gmail.com>

ENV DISPLAY :0
ENV LANG C.UTF-8

RUN apt-get update; apt-get install -y \
    wget

RUN echo "deb http://download.videolan.org/pub/debian/stable/ /" > /etc/apt/sources.list.d/vlc-libdvdcss.list; \
    echo "deb-src http://download.videolan.org/pub/debian/stable/ /" >> /etc/apt/sources.list.d/vlc-libdvdcss.list; \
    wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc | sudo apt-key add -

RUN apt-get update; apt-get install -y \
    flac \
    mplayer2 \
    libdvdcss2

RUN mkdir /rips

ADD dvd2flac.sh /usr/local/bin/dvd2flac.sh
RUN chmod a+x /usr/local/bin/dvd2flac.sh

# Autostart bash and the app (might not be the best way, but it does the trick)
CMD chmod 777 -R /rips; /usr/local/bin/dvd2flac.sh; chmod 777 -R /rips
