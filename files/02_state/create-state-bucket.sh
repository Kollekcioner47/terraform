#!/bin/bash
# Подготовка хранилища состояния в Object Storage.
#
# Зачем скрипт, а не Terraform: бакет, в котором лежит состояние, нельзя
# создать тем же состоянием — получится замкнутый круг. Такой бакет
# создают отдельно: руками, скриптом или отдельной конфигурацией
# (вариант «bootstrap» разобран в практике).
#
# Скрипт создаёт:
#   1. бакет для состояния;
#   2. версионирование в нём — чтобы можно было откатить испорченное
#      состояние;
#   3. статический ключ доступа для сервисного аккаунта.
#
# Запуск:
#   BUCKET=tf-course-state-ivan SA_ID=ajeXXXXXXXXXXXXXX ./create-state-bucket.sh

set -euo pipefail

BUCKET="${BUCKET:?Укажите имя бакета: BUCKET=... }"
SA_ID="${SA_ID:?Укажите идентификатор сервисного аккаунта: SA_ID=... }"
FOLDER_ID="${FOLDER_ID:-$(yc config get folder-id)}"

echo "1. Создаём бакет ${BUCKET}"
yc storage bucket create --name "${BUCKET}"

echo "2. Включаем версионирование"
# Значение параметра именно versioning-enabled, а не enabled:
# командная строка принимает только значения из перечисления
# versioning-disabled, versioning-enabled, versioning-suspended.
yc storage bucket update --name "${BUCKET}" --versioning versioning-enabled

echo "3. Выдаём сервисному аккаунту права на бакет"
yc resource-manager folder add-access-binding "${FOLDER_ID}" \
  --role storage.editor \
  --service-account-id "${SA_ID}"

echo "4. Создаём статический ключ доступа"
yc iam access-key create \
  --service-account-id "${SA_ID}" \
  --description "доступ к бакету состояния" \
  --format json > s3-access-key.json

echo
echo "Готово. Что дальше:"
echo "  * значения access_key.key_id и secret из s3-access-key.json"
echo "    положите в backend.tfvars (файл в git не попадает);"
echo "  * имя бакета ${BUCKET} укажите в backend.tf;"
echo "  * если состояние уже существует локально, примените"
echo "    terraform init -migrate-state."
