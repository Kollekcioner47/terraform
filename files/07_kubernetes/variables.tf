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
  description = "Зона доступности для узлов и подсети"
  default     = "ru-central1-d"
}

variable "sa_key_file" {
  type        = string
  description = "Путь к авторизованному ключу сервисного аккаунта"
}

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

variable "ssh_public_key" {
  type        = string
  description = "Путь к публичному SSH-ключу (доступ к узлам кластера)"
}

variable "project_name" {
  type        = string
  description = "Префикс в именах ресурсов"
  default     = "tf-k8s"
}

# ------------------------------------------------------------------
# Kubernetes
# ------------------------------------------------------------------

# Создавать ли кластер Managed Service for Kubernetes.
#
# По умолчанию ВЫКЛЮЧЕНО, и это осознанно: мастер кластера платный
# круглосуточно, а создаётся он 10-15 минут. Включайте на время
# разбора, затем выключайте и удаляйте.
variable "create_cluster" {
  type        = bool
  description = "Создавать ли кластер Managed Service for Kubernetes"
  default     = false
}

# Тип мастера: zonal (один мастер, дешевле) или regional
# (три мастера в трёх зонах, отказоустойчивый).
variable "master_type" {
  type        = string
  description = "Тип мастера: zonal или regional"
  default     = "zonal"

  validation {
    condition     = contains(["zonal", "regional"], var.master_type)
    error_message = "Тип мастера: zonal или regional."
  }
}

variable "k8s_version" {
  type        = string
  description = "Версия Kubernetes (пустая строка — версия по умолчанию)"
  default     = ""
}

variable "node_count" {
  type        = number
  description = "Число узлов в группе"
  default     = 1

  validation {
    condition     = var.node_count >= 0 && var.node_count <= 3
    error_message = "Для занятий: от 0 до 3 узлов."
  }
}

variable "node_cores" {
  type        = number
  description = "Ядра узла"
  default     = 2
}

variable "node_memory" {
  type        = number
  description = "Память узла, ГБ"
  default     = 4
}

# ------------------------------------------------------------------
# Serverless
# ------------------------------------------------------------------

variable "create_serverless" {
  type        = bool
  description = "Создавать ли функцию и шлюз API"
  default     = true
}

variable "function_runtime" {
  type        = string
  description = "Среда выполнения функции"
  default     = "python312"

  validation {
    condition = contains(
      ["python311", "python312", "nodejs18", "nodejs20", "golang121"],
      var.function_runtime
    )
    error_message = "Выберите поддерживаемую среду выполнения функции."
  }
}

variable "function_memory" {
  type        = number
  description = "Память функции, МБ"
  default     = 128

  validation {
    condition     = var.function_memory >= 128 && var.function_memory <= 1024
    error_message = "Память функции: от 128 до 1024 МБ."
  }
}
