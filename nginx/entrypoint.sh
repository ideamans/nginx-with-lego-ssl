#!/bin/bash

# 毎日0時の処理のための定数

EVERYDAY=$(( 60 * 60 * 24 )) # 1日ごと
TZ_OFFSET=$(( 60 * 60 * 9 )) # 日本時間 +0900

# legoによるSSL証明書の処理

## 定数

LEGO_BASE_PATH="/var/lib/lego"
LEGO_CERT_PATH="${LEGO_BASE_PATH}/certificates/${LEGO_DOMAIN/\*/_}.crt"
LEGO_KEY_PATH="${LEGO_BASE_PATH}/certificates/${LEGO_DOMAIN/\*/_}.key"
LEGO_RENEW_EACH="${LEGO_RENEW_EACH:=10}"

## 証明書の新規取得関数

lego_new() {
  echo "Get new certificate for ${LEGO_DOMAIN}"
  /usr/bin/lego --accept-tos \
    --path="${LEGO_BASE_PATH}" \
    --email="${LEGO_EMAIL}" \
    --dns=route53 \
    --domains="${LEGO_DOMAIN}" \
    run
}

## 証明書の更新の定期実行関数

lego_renew_schedule() {
  while true; do
    # 次の0時までsleep
    NEXT_RENEW=$(( $(date "+%s") + $TZ_OFFSET ))
    sleep $(( ($NEXT_RENEW / $EVERYDAY + 1) * $EVERYDAY - $NEXT_RENEW ))

    echo "Renew certificate for ${LEGO_DOMAIN}"
    lego --accept-tos \
      --path="${LEGO_BASE_PATH}" \
      --email="${LEGO_EMAIL}" \
      --dns=route53 \
      --domains="${LEGO_DOMAIN}" \
      renew \
      --days ${LEGO_RENEW_EACH} && \
      nginx -s reload
  done
}

## 証明書がまだなければリクエスト

if [ ! -f "$LEGO_CERT_PATH" ]; then
  lego_new
fi

## 証明書の更新をサブプロセスで実行

lego_renew_schedule &

# logrotate関連の処理

## 毎日0時にlogrotateを実行する関数

logrotate_schedule() {
  while true; do
    # 次の0時までsleep
    NEXT_LOGROTATE=$(( $(date "+%s") + $TZ_OFFSET ))
    sleep $(( ($NEXT_LOGROTATE / $EVERYDAY + 1) * $EVERYDAY - $NEXT_LOGROTATE ))

    /usr/sbin/logrotate /etc/logrotate.d/nginx
  done
}

## logrotateをサブプロセスで実行

logrotate_schedule &

# nginx本体の起動

exec /usr/sbin/nginx -g "daemon off;"

# サブプロセスの完了待ち

wait