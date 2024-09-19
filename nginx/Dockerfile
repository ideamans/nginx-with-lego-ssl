FROM nginx:1

# 必要なパッケージをインストール
RUN apt update \
    && apt install -y ca-certificates logrotate \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# legoをインストール
COPY --from=goacme/lego:v4.18 /lego /usr/bin/lego

# entrypoint.shでnginxを改造
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# logrotateの設定ファイルを追加
ADD ./logrotate.conf /etc/logrotate.d/nginx
RUN chmod 0600 /etc/logrotate.d/nginx

# 独自のシェルスクリプトを起点にnginxを起動
CMD ["/entrypoint.sh"]