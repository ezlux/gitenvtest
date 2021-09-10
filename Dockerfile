##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
# modules.
##################################################

FROM alpine:3.13 AS builder

LABEL maintainer="Ranadeep Polavarapu <RanadeepPolavarapu@users.noreply.github.com>"

ENV NGINX_VERSION 1.19.6
ENV NGX_BROTLI_COMMIT 9aec15e2aa6feea2113119ba06460af70ab3ea62
ENV PCRE_VERSION 8.44
ENV ZLIB_VERSION 1.2.11
ENV QUICHE_VERSION 0.7.0


RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
  && CONFIG="\
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
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
  --with-pcre=/usr/src/pcre-${PCRE_VERSION} \
  --with-pcre-jit \
  --with-zlib=/usr/src/zlib-${ZLIB_VERSION} \
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
  --with-http_xslt_module=dynamic \
  --with-http_image_filter_module=dynamic \
  --with-http_geoip_module=dynamic \
  --with-http_perl_module=dynamic \
  --with-threads \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  --with-stream_realip_module \
  --with-stream_geoip_module=dynamic \
  --with-http_slice_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-compat \
  --with-file-aio \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-openssl=/usr/src/quiche/deps/boringssl \
  --with-quiche=/usr/src/quiche \
  --add-module=/usr/src/ngx_brotli \
  --add-module=/usr/src/headers-more-nginx-module \
  --add-module=/usr/src/njs/nginx \
  --add-module=/usr/src/nginx_cookie_flag_module \
  --with-cc-opt=-Wno-error \
  " \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  && apk update \
  && apk upgrade \
  && apk add --no-cache ca-certificates \
  #php install
  php8 \
  php8-fpm  \
  php8-soap \
  php8-openssl \
  php8-gmp \
  php8-pdo_odbc \
  php8-fileinfo \
  php8-tokenizer \
  php8-xmlwriter \
  php8-exif \
  php8-json \ 
  php8-dom \
  php8-pdo \
  php8-zip \
  php8-mysqli \
  php8-sqlite3 \
  php8-bcmath \
  php8-phar \
  php8-gd \
  php8-odbc \
  php8-pdo_mysql \
  php8-pdo_sqlite \
  php8-gettext \
  php8-xmlreader \
  php8-xml \
  php8-bz2 \
  php8-iconv \
  php8-pdo_dblib \
  php8-curl \
  php8-ctype \
  php8-session \
  php8-intl\
  php8-cli \
  php8-fileinfo \
  php8-simplexml \
  # end php install
  # Personal pref editor
  vim \
  && update-ca-certificates \
  && apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  curl \
  gnupg \
  libxslt-dev \
  gd-dev \
  geoip-dev \
  perl-dev \
  && apk add --no-cache --virtual .brotli-build-deps \
  autoconf \
  libtool \
  automake \
  git \
  g++ \
  cmake \
  go \
  perl \
  rust \
  cargo \
  patch \
  && mkdir -p /usr/src \
  && cd /usr/src \
  && git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli \
  && cd ngx_brotli \
  && git checkout -b $NGX_BROTLI_COMMIT \
  && cd .. \
  && wget -qO- https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz | tar zxvf - \
  && wget -qO- http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz | tar zxvf - \
  && git clone --depth=1 --recursive https://github.com/openresty/headers-more-nginx-module \
  && git clone --depth=1 --recursive https://github.com/nginx/njs \
  && git clone --depth=1 --recursive https://github.com/AirisX/nginx_cookie_flag_module \
  && git clone --depth=1 --recursive --branch ${QUICHE_VERSION} https://github.com/cloudflare/quiche \
  && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
  && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
  && export GNUPGHOME="$(mktemp -d)" \
  && found=''; \
  for server in \
  ha.pool.sks-keyservers.net \
  hkp://keyserver.ubuntu.com:80 \
  hkp://p80.pool.sks-keyservers.net:80 \
  pgp.mit.edu \
  ; do \
  echo "Fetching GPG key $GPG_KEYS from $server"; \
  gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
  gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
  && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
  && mkdir -p /usr/src \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && rm nginx.tar.gz \
  && cd /usr/src/nginx-$NGINX_VERSION \
  && patch -p01 < /usr/src/quiche/extras/nginx/nginx-1.16.patch \
  && ./configure $CONFIG --with-debug --build="pcre-${PCRE_VERSION} zlib-${ZLIB_VERSION} quiche-$(git --git-dir=/usr/src/quiche/.git rev-parse --short HEAD) ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-$(git --git-dir=/usr/src/headers-more-nginx-module/.git rev-parse --short HEAD) njs-$(git --git-dir=/usr/src/njs/.git rev-parse --short HEAD) nginx_cookie_flag_module-$(git --git-dir=/usr/src/nginx_cookie_flag_module/.git rev-parse --short HEAD)" \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && mv objs/nginx objs/nginx-debug \
  && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
  && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
  && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
  && mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
  && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
  && ./configure $CONFIG --build="pcre-${PCRE_VERSION} zlib-${ZLIB_VERSION} quiche-$(git --git-dir=/usr/src/quiche/.git rev-parse --short HEAD) ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-$(git --git-dir=/usr/src/headers-more-nginx-module/.git rev-parse --short HEAD) njs-$(git --git-dir=/usr/src/njs/.git rev-parse --short HEAD) nginx_cookie_flag_module-$(git --git-dir=/usr/src/nginx_cookie_flag_module/.git rev-parse --short HEAD)" \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && mkdir -p /usr/share/nginx/html/ \
  && install -m644 html/index.html /usr/share/nginx/html/ \
  && install -m644 html/50x.html /usr/share/nginx/html/ \
  && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
  && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
  && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
  && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
  && install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
  && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
  && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && strip /usr/lib/nginx/modules/*.so \
  && rm -rf /usr/src/nginx-$NGINX_VERSION \
  && rm -rf /usr/src/ngx_brotli \
  && rm -rf /usr/src/headers-more-nginx-module \
  && rm -rf /usr/src/njs \
  && rm -rf /usr/src/nginx_cookie_flag_module \
  && rm -rf /usr/src/quiche \
  \
  # Bring in gettext so we can get `envsubst`, then throw
  # the rest away. To do this, we need to install `gettext`
  # then move `envsubst` out of the way so `gettext` can
  # be deleted completely, then move `envsubst` back.
  && apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  \
  && runDeps="$( \
  scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .build-deps \
  && apk del .brotli-build-deps \
  && apk del .gettext \
  && mv /tmp/envsubst /usr/local/bin/

# Create self-signed certificate
RUN apk add openssl \
  && openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/ssl/private/localhost.key -out /etc/ssl/localhost.pem -days 365 -sha256 -subj '/CN=localhost'

FROM alpine:3.13

# For production only:
# ENV NODE_ENV production

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx-debug /usr/sbin/
COPY --from=builder /usr/lib /usr/lib/
COPY --from=builder /usr/lib/nginx /usr/lib/
COPY --from=builder /usr/share/nginx/html/* /usr/share/nginx/html/
COPY --from=builder /etc/nginx/* /etc/nginx/
COPY --from=builder /usr/local/bin/envsubst /usr/local/bin/
COPY --from=builder /etc/ssl/private/localhost.key /etc/ssl/private/
COPY --from=builder /etc/ssl/localhost.pem /etc/ssl/
COPY --from=builder /usr/sbin/php-fpm8 /usr/sbin/
#php8 is installed in bin in builder but php.ini point to share
COPY --from=builder /usr/bin/php8 /usr/bin/
COPY --from=builder /etc/php8 /etc/php8/

# Install dependencies for wkhtmltopdf
RUN apk add --no-cache \
  curl \
  wkhtmltopdf \
  libstdc++ \
  libx11 \
  libxrender \
  libxext \
  libssl1.1 \
  ca-certificates \
  fontconfig \
  freetype \
  ttf-dejavu \
  ttf-droid \
  ttf-freefont \
  ttf-liberation \
  ttf-ubuntu-font-family \
&& apk add --no-cache --virtual .build-deps \
  msttcorefonts-installer \
\
# Install microsoft fonts
&& update-ms-fonts \
&& fc-cache -f \
\
# Clean up when done 
&& rm -rf /tmp/* \
&& apk del .build-deps 

RUN \
  # Bring in tzdata so users could set the timezones through the environment
  # variables
  apk add --no-cache tzdata \
  pcre \
  libgcc \
  libintl \
  #need npm 
  npm \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  # forward request and error logs to docker log collector
  && mkdir -p /var/log/nginx \
  && touch /var/log/nginx/access.log /var/log/nginx/error.log \
  && chown nginx: /var/log/nginx/access.log /var/log/nginx/error.log \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log\
# php logs
  && mkdir -p /var/log/php8 \
  && touch /var/log/php8/access.log /var/log/php8/error.log \
#php8 symlink
  && ln -s /usr/bin/php8 /usr/bin/php \
#install composer
  && cd /usr/local/bin \
  && wget https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer -O - -q | php -- --quiet


# ENV for PHP
ENV PHP_FPM_USER="nginx" \
    PHP_FPM_GROUP="nginx" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="512M" \
    PHP_MAX_UPLOAD="50M" \
    PHP_MAX_FILE_UPLOAD="200"\
    PHP_MAX_POST="100M" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO=0 

# PHP conf
RUN   \
    sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php8/php-fpm.d/www.conf ; \
    sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php8/php-fpm.d/www.conf ; \
    sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php8/php-fpm.d/www.conf ;\
    sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php8/php-fpm.d/www.conf ;\
    sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php8/php-fpm.d/www.conf ;\
    sed -i "s|;log_level\s*=\s*notice|log_level = notice|g" /etc/php8/php-fpm.d/www.conf #uncommenting line ;

RUN  \
    sed -i "s|display_errors\s*=\s*Off|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php8/php.ini; \
    sed -i "s|display_startup_errors\s*=\s*Off|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php8/php.ini ; \
    sed -i "s|error_reporting\s*=\s*E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php8/php.ini ; \ 
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php8/php.ini ; \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php8/php.ini ; \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php8/php.ini ;\
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php8/php.ini ; \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php8/php.ini ; 

#################################### END  OF PHP FPM 

# Copy your configs.
COPY nginx.conf /etc/nginx/
COPY h3.nginx.conf /etc/nginx/conf.d/
COPY ezinvoice.conf /etc/nginx/conf.d/
COPY index.php /usr/share/nginx/www/

#####################################
# download the dev test
#
#####################################
# Personal pref editor an dgit
RUN apk add  vim \
  && apk add git
  
RUN git clone -b test https://c3534cefd92df5b753a114181a3e26fba2dbbba2@github.com/ezlux/ezinvoiceapi.git /usr/share/nginx/www/ezinvoice/

COPY .env /usr/share/nginx/www/ezinvoice/

RUN \
  cd /usr/share/nginx/www/ezinvoice/ \
  && composer.phar install

RUN \
  cd /usr/share/nginx/www/ezinvoice/ \
  && npm install \
  && npm run dev
  #production ???  may work better
  # && npm ci --only=production 
# cross env global ?
# npm install --global cross-env

RUN ln -s /usr/share/nginx/www /srv/www

#TODO better handle logs
RUN chown nginx: -R /usr/share/nginx/www/ezinvoice/storage
EXPOSE 80 443
CMD php-fpm8 -D && nginx -g "daemon off;"

STOPSIGNAL SIGTERM

# Build-time metadata as defined at http://label-schema.org
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-ref=$VCS_REF 
