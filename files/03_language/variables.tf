# Переменные: типы, значения по умолчанию, проверки, чувствительность.
#
# В этой практике важен не набор переменных, а приёмы:
#   * сложные типы (map(object({...})));
#   * проверки, которые ловят ошибку до обращения к облаку;
#   * чувствительные значения, которые не печатаются в выводе.

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
  description = "Зона доступности по умолчанию"
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
  default     = "tf-lang"
}

# Проверка значения по списку допустимых.
variable "environment" {
  type        = string
  description = "Окружение: dev, stage или prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Окружение должно быть одним из: dev, stage, prod."
  }
}

# Сложный тип: словарь объектов. Так описывают однотипные сущности,
# которых заранее неизвестное количество.
variable "subnets" {
  type = map(object({
    zone = string
    cidr = string
  }))
  description = "Подсети: ключ — имя, значения — зона и диапазон адресов"

  default = {
    app = {
      zone = "ru-central1-a"
      cidr = "10.30.10.0/24"
    }
    data = {
      zone = "ru-central1-b"
      cidr = "10.30.20.0/24"
    }
    edge = {
      zone = "ru-central1-d"
      cidr = "10.30.30.0/24"
    }
  }
}

variable "allowed_ports" {
  type        = list(number)
  description = "Порты, открытые на вход из интернета"
  default     = [22, 80, 443]
}

# Словарь машин. Ключ словаря становится частью имени ресурса,
# поэтому он должен быть осмысленным: app, queue, cache.
variable "instances" {
  type = map(object({
    subnet = string
    cores  = optional(number, 2)
    memory = optional(number, 2)
  }))
  description = "Виртуальные машины: ключ — роль машины"

  default = {
    app = {
      subnet = "app"
    }
    queue = {
      subnet = "data"
      cores  = 2
      memory = 4
    }
  }
}

# Число машин, создаваемых через count. Про разницу между count
# и for_each — в тексте практики.
variable "worker_count" {
  type        = number
  description = "Сколько машин-исполнителей создать"
  default     = 1

  validation {
    condition     = var.worker_count >= 0 && var.worker_count <= 3
    error_message = "Допустимое число машин-исполнителей: от 0 до 3."
  }
}

variable "enable_debug_vm" {
  type        = bool
  description = "Создавать ли отладочную машину (условное создание ресурса)"
  default     = false
}

variable "extra_labels" {
  type        = map(string)
  description = "Дополнительные метки, которые добавляются к общим"
  default     = {}
}

# Чувствительное значение: пароль базы данных. Флаг sensitive
# не прячет значение из файла состояния — об этом важная оговорка
# в тексте практики. Он лишь запрещает печатать значение в выводе
# команд и в плане.
variable "db_password" {
  type        = string
  description = "Пароль базы данных (учебный пример чувствительного значения)"
  default     = "ChangeMe_12345"
  sensitive   = true
}
