FROM debian:jessie

MAINTAINER Revin Roman <roman@rmrevin.com>

ENV NGINX_VERSION 1.12.0

RUN set -xe \
 && useradd --no-create-home nginx \
 && apt-get update -qq \
 && apt-get install -y \
        apt-utils bash-completion ca-certificates gnupg2 net-tools ssh-client \
        gcc make rsync chrpath curl wget rsync git vim unzip bzip2 supervisor \
        libpcre3 libssl-dev libpcre3-dev libgd-dev \

 # get nginx
 && wget "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" \
 && mkdir -p /usr/src/nginx \
 && tar -xof nginx-$NGINX_VERSION.tar.gz -C /usr/src/nginx --strip-components=1 \
 && rm nginx-$NGINX_VERSION.tar.gz \

 # build
 && cd /usr/src/nginx \
 && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-ipv6 \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_v2_module \
        --with-http_image_filter_module \
    && make -j2 \
    && make install \
    && make clean \

 # clean
 && apt-get autoremove -yqq \
 && apt-get clean \

 # forward request and error logs to docker log collector
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

COPY supervisor.d/ /etc/supervisor/

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443

WORKDIR /usr/src/nginx

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
