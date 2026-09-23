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
  description = "Основная зона доступности"
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
  default     = "tf-net"
}

variable "image_family" {
  type        = string
  description = "Семейство образов"
  default     = "ubuntu-2604-lts"
}

# Подсети: по одной в каждой зоне.
#
# Три зоны — не украшение. Машины в разных зонах переживают отказ
# одной зоны доступности. Но зональные ресурсы, такие как подсеть,
# машина и диск, к зоне привязаны: перенести подсеть из зоны в зону
# нельзя, её можно только создать заново.
variable "subnets" {
  type = map(object({
    zone = string
    cidr = string
  }))
  description = "Подсети сети: ключ — имя"

  default = {
    web-a = {
      zone = "ru-central1-a"
      cidr = "10.70.10.0/24"
    }
    web-b = {
      zone = "ru-central1-b"
      cidr = "10.70.20.0/24"
    }
    web-d = {
      zone = "ru-central1-d"
      cidr = "10.70.30.0/24"
    }
  }

  validation {
    condition     = length(var.subnets) >= 1
    error_message = "Нужна хотя бы одна подсеть."
  }
}

# Публичные порты веб-сервера и порт для SSH.
variable "web_ports" {
  type        = list(number)
  description = "Порты, открытые для клиентов из интернета"
  default     = [80]
}

variable "dns_zone" {
  type        = string
  description = "Доменная зона для записей (с точкой на конце)"
  default     = "tf-course.example.com."

  validation {
    condition     = endswith(var.dns_zone, ".")
    error_message = "Имя зоны указывается с точкой на конце: example.com."
  }
}

variable "dns_record_name" {
  type        = string
  description = "Имя записи внутри зоны"
  default     = "web"
}

variable "create_alb" {
  type        = bool
  description = "Создавать ли прикладной балансировщик (L7)"
  default     = true
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Создавать ли NAT-шлюз для выхода в интернет"
  default     = true
}
