# Входные переменные практики 2.
#
# По сравнению с практикой 1 добавлены две: имя бакета для состояния
# (нужно только для справки и для скрипта создания бакета) и имя проекта.

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

variable "sa_key_file" {
  type        = string
  description = "Путь к авторизованному ключу сервисного аккаунта"
}

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов"
  default     = "tf-state"
}

variable "image_family" {
  type        = string
  description = "Семейство образов загрузочного диска"
  default     = "ubuntu-2604-lts"
}

variable "ssh_public_key" {
  type        = string
  description = "Путь к публичному SSH-ключу"
}

variable "state_bucket" {
  type        = string
  description = "Имя бакета для хранения состояния (для справки и скриптов)"

  validation {
    # Имя бакета в Object Storage: строчные латинские буквы, цифры,
    # точка и дефис. Заглавные буквы и подчёркивания недопустимы.
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket))
    error_message = "Имя бакета: строчные буквы, цифры, точка и дефис, от 3 до 63 символов."
  }
}
