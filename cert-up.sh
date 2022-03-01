#!/bin/bash

# path of this script
BASE_ROOT=$(cd "$(dirname "$0")";pwd)
# date time
DATE_TIME=`date +%Y%m%d%H%M%S`
# base crt path
# 请在 config.env 中配置
# CRT_BASE_PATH="/mnt/user/appdata/acme.sh/certificate"
# PKG_CRT_BASE_PATH="/mnt/user/appdata/acme.sh/certificate"

mkdir -p ${CRT_BASE_PATH}
mkdir -p ${PKG_CRT_BASE_PATH}

ACME_BIN_PATH=${BASE_ROOT}/acme.sh
TEMP_PATH=${BASE_ROOT}/temp

# 备份老版本的证书
backupCrt () {
  echo 'begin backupCrt'
  BACKUP_PATH=${BASE_ROOT}/backup/${DATE_TIME}
  mkdir -p ${BACKUP_PATH}
  cp -r ${CRT_BASE_PATH} ${BACKUP_PATH}
#   cp -r ${PKG_CRT_BASE_PATH} ${BACKUP_PATH}/package_cert
  echo ${BACKUP_PATH} > ${BASE_ROOT}/backup/latest
  echo 'done backupCrt'
  return 0
}

installAcme () {
  echo 'begin installAcme'
  mkdir -p ${TEMP_PATH}
  cd ${TEMP_PATH}
  echo 'begin downloading acme.sh tool...'
  ACME_SH_ADDRESS=`curl -L https://cdn.jsdelivr.net/gh/nikejaycn/unraid-acme@master/acme.sh.address`
  SRC_TAR_NAME=acme.sh.tar.gz
  curl -L -o ${SRC_TAR_NAME} ${ACME_SH_ADDRESS}
  SRC_NAME=`tar -tzf ${SRC_TAR_NAME} | head -1 | cut -f1 -d"/"`
  tar zxvf ${SRC_TAR_NAME}
  echo 'begin installing acme.sh tool...'
  cd ${SRC_NAME}
  ./acme.sh --install --nocron --home ${ACME_BIN_PATH}
  echo 'done installAcme'
  rm -rf ${TEMP_PATH}
  return 0
}

generateCrt () {
  echo 'begin generateCrt'
  cd ${BASE_ROOT}
  source config.env
  echo 'begin updating default cert by acme.sh tool'
  source ${ACME_BIN_PATH}/acme.sh.env
  ${ACME_BIN_PATH}/acme.sh  --register-account  -m ${DOMAIN_EMAIL} --server zerossl
  ${ACME_BIN_PATH}/acme.sh --force --log --issue --dns ${DNS} --dnssleep ${DNS_SLEEP} -d "${DOMAIN}"
  ${ACME_BIN_PATH}/acme.sh --force --installcert -d ${DOMAIN} \
    --certpath ${CRT_BASE_PATH}/cert.pem \
    --keypath ${CRT_BASE_PATH}/server.key \
    --key-file ${CRT_BASE_PATH}/server.pem \
    --fullchain-file ${CRT_BASE_PATH}/fullchain.pem

  if [ -s "${CRT_BASE_PATH}/cert.pem" ]; then
    echo 'done generateCrt'
    return 0
  else
    echo '[ERR] fail to generateCrt'
    # echo "begin revert"
    # revertCrt
    exit 1;
  fi
}

updateCrt () {
  echo '------ begin updateCrt ------'
  backupCrt
  installAcme
  generateCrt
  echo '------ end updateCrt ------'
}

revertCrt () {
    echo 'begin revertCrt'
    echo 'waiting todo...'
}

case "$1" in
  update)
    echo "begin update cert"
    updateCrt
    ;;

  revert)
    echo "begin revert"
      revertCrt $2
      ;;

    *)
        echo "Usage: $0 {update|revert}"
        exit 1
esac
