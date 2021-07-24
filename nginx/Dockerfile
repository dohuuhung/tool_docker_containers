FROM dohuuhung1234/dohuuhung1234:ubuntu_1604

LABEL maintainer="NGINX Docker Maintainers dohuuhung1234@gmail.com"

# Copy all neccesary script for docker container
RUN mkdir /root/docker_scripts
COPY neccesary_script/* /root/docker_scripts/

# Install all of requirement packages
RUN apt-get update \
    && apt install -y vim nginx


VOLUME /var/log/nginx/ /var/log/nginx

EXPOSE 80 443

CMD ["bash", "/root/docker_scripts/start.sh"]
