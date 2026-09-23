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

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов"
  default     = "tf-compute"
}

variable "image_family" {
  type        = string
  description = "Семейство образов загрузочного диска"
  default     = "ubuntu-2604-lts"
}

variable "web_vm_cores" {
  type        = number
  description = "Ядра веб-сервера"
  default     = 2
}

variable "web_vm_memory" {
  type        = number
  description = "Память веб-сервера, ГБ"
  default     = 2
}

variable "data_disk_size" {
  type        = number
  description = "Размер дополнительного диска, ГБ"
  default     = 5

  validation {
    condition     = var.data_disk_size >= 1 && var.data_disk_size <= 50
    error_message = "Размер диска: от 1 до 50 ГБ."
  }
}

variable "data_disk_type" {
  type        = string
  description = "Тип дополнительного диска"
  default     = "network-hdd"

  validation {
    condition = contains(
      ["network-hdd", "network-ssd", "network-ssd-nonreplicated"],
      var.data_disk_type
    )
    error_message = "Неизвестный тип диска."
  }
}

variable "create_snapshot" {
  type        = bool
  description = "Создавать ли снимок дополнительного диска"
  default     = true
}

variable "ig_size" {
  type        = number
  description = "Число машин в группе"
  default     = 2

  validation {
    condition     = var.ig_size >= 0 && var.ig_size <= 3
    error_message = "Для занятий: от 0 до 3 машин."
  }
}

variable "ig_autoscaling" {
  type        = bool
  description = "Включить автоматическое масштабирование группы"
  default     = false
}

variable "create_load_balancer" {
  type        = bool
  description = "Создавать ли сетевой балансировщик"
  default     = true
}
