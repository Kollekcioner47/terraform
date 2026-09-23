provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  service_account_key_file = var.sa_key_file

  # Отдельные ключи для Object Storage.
  #
  # Object Storage работает по S3-совместимому API, и для него нужен
  # СТАТИЧЕСКИЙ КЛЮЧ ДОСТУПА — не тот же самый, что авторизованный
  # ключ сервисного аккаунта. Ключ создаётся отдельно:
  #
  #   yc iam access-key create --service-account-id <sa_id> \
  #     --description "доступ к Object Storage"
  #
  # В ответе два значения, и идентификатор лежит во вложенном объекте:
  #
  #   {
  #     "access_key": { "key_id": "YCAJEXXXXXXXXXXXXXXXXX" },
  #     "secret": "..."
  #   }
  #
  # В storage_access_key нужно значение key_id (начинается с YCAJE).
  # Если подставить весь объект целиком, Object Storage ответит
  # «400 Bad Request» вместо понятной ошибки про права.
  #
  # Значения можно не указывать здесь, а задать переменными окружения
  # AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY — так удобнее в конвейере.
  storage_access_key = var.storage_access_key
  storage_secret_key = var.storage_secret_key
}
