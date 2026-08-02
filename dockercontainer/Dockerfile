FROM ubuntu:22.04 AS build_image

WORKDIR /root

RUN apt-get update && apt-get install -y --no-install-recommends wget unzip && rm -rf /var/lib/apt/lists/*
RUN wget https://www.tooplate.com/zip-templates/2128_tween_agency.zip
RUN unzip 2128_tween_agency.zip && rm 2128_tween_agency.zip

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends apache2 git wget && rm -rf /var/lib/apt/lists/*

COPY --from=build_image /root/2128_tween_agency/ /var/www/html/

USER www-data

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
VOLUME /var/log/apache2
