# Входные переменные.
#
# Всё, что отличается от студента к студенту или от среды к среде,
# описывается переменными. В конфигурации не должно быть «магических»
# значений: идентификатор каталога, путь к ключу и имя проекта — снаружи.

variable "cloud_id" {
  type        = string
  description = "Идентификатор облака"

  validation {
    # Идентификаторы облака и каталога начинаются с b1.
    # Проверка ловит самую частую ошибку: в поле каталога оказался
    # идентификатор облака или наоборот.
    condition     = can(regex("^b1", var.cloud_id))
    error_message = "Идентификатор облака должен начинаться с b1."
  }
}

variable "folder_id" {
  type        = string
  description = "Идентификатор каталога"

  validation {
    condition     = can(regex("^b1", var.folder_id))
    error_message = "Идентификатор каталога должен начинаться с b1."
  }
}

variable "zone" {
  type        = string
  description = "Зона доступности по умолчанию"
  default     = "ru-central1-d"

  validation {
    # Зоны доступности Яндекс Облака. Зоны ru-central1-c больше нет:
    # конфигурации из старых статей с ней не работают.
    condition = contains(
      ["ru-central1-a", "ru-central1-b", "ru-central1-d", "ru-central1-e"],
      var.zone
    )
    error_message = "Зона должна быть одной из: ru-central1-a, -b, -d, -e."
  }
}

variable "sa_key_file" {
  type        = string
  description = "Путь к авторизованному ключу сервисного аккаунта"
}

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов, чтобы ресурсы разных студентов не путались"
  default     = "tf-course"

  validation {
    # Имена ресурсов в облаке: строчные латинские буквы, цифры и дефис.
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "Префикс: строчные буквы, цифры и дефис, от 2 до 31 символа."
  }
}

variable "image_family" {
  type        = string
  description = "Семейство образов загрузочного диска"
  default     = "ubuntu-2604-lts"
}

variable "vm_cores" {
  type        = number
  description = "Количество ядер виртуальной машины"
  default     = 2

  validation {
    condition     = contains([2, 4, 6, 8], var.vm_cores)
    error_message = "Допустимые значения: 2, 4, 6, 8."
  }
}

variable "vm_memory" {
  type        = number
  description = "Объём памяти виртуальной машины в гигабайтах"
  default     = 2
}

variable "ssh_public_key" {
  type        = string
  description = "Путь к публичному SSH-ключу для доступа к виртуальной машине"
}
