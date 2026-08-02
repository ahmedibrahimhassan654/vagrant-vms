FROM ubuntu AS build_image

WORKDIR /root

RUN apt update && apt install wget unzip -y
RUN wget https://www.tooplate.com/zip-templates/2128_tween_agency.zip
RUN unzip 2128_tween_agency.zip

FROM ubuntu

RUN apt update && apt install apache2 git wget -y

COPY --from=build_image /root/2128_tween_agency/ /var/www/html/

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
VOLUME /var/log/apache2
