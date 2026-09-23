# Lockbox: хранилище секретов.
#
# Задача: пароль базы данных не должен лежать в коде, в репозитории
# и в переписке. Правильное место для него — хранилище секретов,
# где у каждого секрета свои права доступа, своя история версий
# и свой журнал обращений.

resource "yandex_lockbox_secret" "db" {
  count = var.create_secret ? 1 : 0

  name        = "${var.project_name}-db-secret"
  description = "Пароль базы данных курса Terraform"

  # Секрет шифруется нашим ключом KMS: без права на ключ его
  # содержимое не прочитает даже тот, у кого есть доступ к секрету.
  kms_key_id = yandex_kms_symmetric_key.secrets[0].id

  # Защита от удаления: секрет нельзя удалить, пока флаг не снят.
  deletion_protection = true

  labels = {
    course = "terraform"
    lesson = "6"
  }
}

# Версия секрета: именно в ней лежат значения.
#
# Секрет без версии бесполезен: сам объект — это «папка», а значения
# хранятся в версиях. Версий может быть много, и это удобно для
# ротации: добавили новую версию — приложения перешли на неё,
# старая осталась для отката.
resource "yandex_lockbox_secret_version" "db" {
  count = var.create_secret ? 1 : 0

  secret_id   = yandex_lockbox_secret.db[0].id
  description = "Параметры подключения к базе данных"

  entries {
    key        = "db_password"
    text_value = var.db_password
  }

  entries {
    key        = "db_user"
    text_value = var.db_user
  }

  entries {
    key        = "db_name"
    text_value = var.db_name
  }

  entries {
    key        = "db_host"
    text_value = var.create_database ? yandex_mdb_postgresql_cluster.db[0].host[0].fqdn : "база не создавалась"
  }
}

# ЧТО ЗДЕСЬ ВАЖНО ПОНЯТЬ
#
# 1. Значение секрета ЗАПИСЫВАЕТСЯ ЧЕРЕЗ TERRAFORM, а значит попадает
#    в файл состояния. Хранилище секретов защищает секрет от людей,
#    но не от состояния Terraform. Проверить это можно так:
#
#      terraform state pull | grep -i db_password
#
#    Увидите свой пароль в открытом виде.
#
# 2. Как избежать этого:
#    * создавать версию секрета средствами Lockbox (консоль, yc, API),
#      а в Terraform только читать её через источник данных;
#    * генерировать пароль внутри Lockbox:
#
#        password_payload_specification {
#          password_key = "db_password"
#          length       = 24
#        }
#
#      тогда значения нет ни в переменных, ни в конфигурации, ни в
#      состоянии — но и пароль для базы придётся брать из секрета
#      в момент настройки приложения, а не в момент apply;
#    * хранить состояние в бакете с ограниченным доступом (практика 2).
#
# 3. Роли. Чтение значения секрета — отдельная роль:
#    lockbox.payloadViewer. Просмотр метаданных секрета —
#    lockbox.viewer. Разница принципиальная: можно дать человеку
#    видеть список секретов, но не их содержимое.
