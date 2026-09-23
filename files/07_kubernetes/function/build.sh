#!/bin/bash
# Сборка архива с кодом функции.
#
# Зачем скрипт: провайдер Яндекс Облака принимает код функции
# не файлом с диска, а ссылкой на архив в Object Storage. Поэтому
# перед terraform apply архив нужно собрать.
#
# Запуск из каталога function/:
#
#   ./build.sh
#
# После правки index.py архив надо пересобрать: сам по себе he
# обновится, а Terraform сравнит хэш архива (user_hash и source_hash)
# и не увидит изменений.

set -euo pipefail

SOURCE="index.py"
ARCHIVE="function.zip"

if [ ! -f "$SOURCE" ]; then
  echo "Нет файла $SOURCE — запустите скрипт из каталога function/" >&2
  exit 1
fi

rm -f "$ARCHIVE"

if command -v zip >/dev/null 2>&1; then
  zip -q "$ARCHIVE" "$SOURCE"
else
  # Если утилиты zip нет — подойдёт Python (он есть на учебной машине).
  python3 -c "
import zipfile
with zipfile.ZipFile('$ARCHIVE', 'w', zipfile.ZIP_DEFLATED) as z:
    z.write('$SOURCE')
"
fi

echo "Собран архив $ARCHIVE:"
ls -l "$ARCHIVE"
echo
echo "Хэш архива (его видит Terraform в source_hash и user_hash):"
if command -v md5sum >/dev/null 2>&1; then
  md5sum "$ARCHIVE"
else
  python3 -c "
import hashlib
print(hashlib.md5(open('$ARCHIVE','rb').read()).hexdigest(), '$ARCHIVE')
"
fi
