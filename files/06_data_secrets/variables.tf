variable "cloud_id" {
  type        = string
  description = "Идентификатор облака"
}

variable "folder_id" {
  type        = string
  description = "Идентификатор каталога"
}

variable "zone" {
  type        = string
  description = "Зона доступности"
  default     = "ru-central1-d"
}

# Статические ключи доступа к Object Storage.
#
# Значение key_id начинается с YCAJE — это не тот же ключ, что
# авторизованный ключ сервисного аккаунта. Подробности в provider.tf.
# Оба значения — секреты: в репозиторий они не попадают, передаются
# через terraform.tfvars (он в .gitignore) или переменными окружения
# AWS_ACCESS_KEY_ID и AWS_SECRET_ACCESS_KEY.
variable "storage_access_key" {
  type        = string
  description = "Идентификатор статического ключа доступа (key_id)"
  default     = null
  sensitive   = true
}

variable "storage_secret_key" {
  type        = string
  description = "Секретная часть статического ключа доступа"
  default     = null
  sensitive   = true
}

variable "sa_key_file" {
  type        = string
  description = "Путь к авторизованному ключу сервисного аккаунта"
}

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов"
  default     = "tf-data"
}

# Имя бакета должно быть уникальным во всём Object Storage.
# Добавьте к имени что-то своё: логин, название команды, дату.
variable "bucket_name" {
  type        = string
  description = "Имя бакета для статического сайта"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Имя бакета: строчные латинские буквы, цифры, точка и дефис."
  }
}

variable "site_index" {
  type        = string
  description = "Главная страница сайта"
  default     = "index.html"
}

variable "site_error" {
  type        = string
  description = "Страница ошибки"
  default     = "error.html"
}

# Версия PostgreSQL. Список допустимых версий смотрите в документации
# провайдера к ресурсу yandex_mdb_postgresql_cluster: сейчас это
# 15, 16, 17, 18 и 19 (варианты с суффиксом -1c — для 1С).
variable "db_version" {
  type        = string
  description = "Версия PostgreSQL"
  default     = "17"
}

variable "db_name" {
  type        = string
  description = "Имя базы данных"
  default     = "appdb"
}

variable "db_user" {
  type        = string
  description = "Имя пользователя базы данных"
  default     = "appuser"
}

# Пароль базы данных.
#
# Флаг sensitive запрещает печатать значение в выводе команд, но НЕ
# убирает его из файла состояния. Об этом подробно в тексте практики.
variable "db_password" {
  type        = string
  description = "Пароль пользователя базы данных"
  sensitive   = true
  default     = ""
}

# Создавать ли кластер базы данных.
#
# По умолчанию выключено: кластер стоит денег, и в учебном стенде его
# включают на время разбора, а потом выключают. Сайт в бакете при этом
# стоит копейки.
variable "create_database" {
  type        = bool
  description = "Создавать ли кластер Managed Service for PostgreSQL"
  default     = false
}

variable "db_disk_size" {
  type        = number
  description = "Размер диска кластера, ГБ"
  default     = 10

  validation {
    condition     = var.db_disk_size >= 10 && var.db_disk_size <= 50
    error_message = "Размер диска кластера: от 10 до 50 ГБ."
  }
}

variable "db_preset" {
  type        = string
  description = "Класс ресурсов хоста базы данных"
  default     = "s2.micro"
}

# Создавать ли секрет в Lockbox.
variable "create_secret" {
  type        = bool
  description = "Создавать ли секрет в Lockbox с паролем базы"
  default     = true
}
