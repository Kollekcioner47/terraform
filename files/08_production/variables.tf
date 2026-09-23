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

variable "ssh_public_key" {
  type        = string
  description = "Путь к публичному SSH-ключу"
}

variable "storage_access_key" {
  type        = string
  description = "Идентификатор статического ключа доступа"
  default     = null
  sensitive   = true
}

variable "storage_secret_key" {
  type        = string
  description = "Секретная часть статического ключа доступа"
  default     = null
  sensitive   = true
}

# ОКРУЖЕНИЕ. Именно этот параметр отличает dev от prod: он попадает
# в имена ресурсов, в метки и в размеры машин.
variable "environment" {
  type        = string
  description = "Окружение: dev или prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Окружение: dev или prod."
  }
}

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов"
  default     = "tf-final"
}

variable "image_family" {
  type        = string
  description = "Семейство образов"
  default     = "ubuntu-2604-lts"
}

# Создавать ли приложение. В dev достаточно сети и бакета,
# в prod — полный набор. Это не «экономия ради экономии»:
# окружения действительно отличаются составом ресурсов.
variable "create_app" {
  type        = bool
  description = "Создавать ли виртуальную машину приложения"
  default     = true
}

variable "app_cores" {
  type        = number
  description = "Ядра машины приложения"
  default     = 2
}

variable "app_memory" {
  type        = number
  description = "Память машины, ГБ"
  default     = 2
}

variable "preemptible" {
  type        = bool
  description = "Прерываемая ли машина (в dev — да, в prod — нет)"
  default     = true
}

variable "site_bucket" {
  type        = string
  description = "Имя бакета сайта (уникально во всём Object Storage)"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.site_bucket))
    error_message = "Имя бакета: строчные латинские буквы, цифры, точка и дефис."
  }
}

# Защита ресурсов от удаления. В prod включается, в dev выключается:
# иначе учебный стенд не удалить одной командой.
variable "protect_resources" {
  type        = bool
  description = "Защищать ли ресурсы от случайного удаления"
  default     = false
}
