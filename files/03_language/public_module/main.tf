# Пример подключения готового модуля из библиотеки terraform-yc-modules.
#
# Это отдельный пример, а не часть основной конфигурации практики:
# положите его в отдельный каталог, если хотите попробовать.
#
# ЧТО МЕНЯЕТСЯ ПО СРАВНЕНИЮ СО СВОИМ МОДУЛЕМ
#
#   * источник (source) — адрес git-репозитория, а не путь на диске;
#   * обязателен параметр ref — версия (тег) модуля;
#   * модуль создаёт ресурсы по своим правилам, и его входные
#     переменные надо смотреть в документации модуля (README в
#     репозитории), а не угадывать.
#
# ПОЧЕМУ git::https, А НЕ git@github.com
#
#   Документация Яндекс Облака показывает источник в виде
#   git@github.com:terraform-yc-modules/terraform-yc-vpc.git.
#   Такой адрес требует настроенного SSH-ключа, добавленного в GitHub.
#   На учебной машине его обычно нет, и init падает с ошибкой
#   «Permission denied (publickey)».
#
#   Надёжнее использовать HTTPS — он работает без ключей:
#
#     source = "git::https://github.com/terraform-yc-modules/terraform-yc-vpc.git?ref=1.0.9"
#
#   Приставка git:: говорит Terraform, что источник надо скачать
#   средствами git.
#
# ЧТО ВАЖНО ПРО ВЕРСИИ
#
#   Параметр ref обязателен в рабочей среде: без него модуль будет
#   скачиваться из ветки по умолчанию, и однажды он изменится —
#   без предупреждения и в самый неподходящий момент. Допустимые
#   значения ref: тег (1.0.9), ветка (main), коммит.

terraform {
  required_version = ">= 1.6.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.229.0"
    }
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  service_account_key_file = var.sa_key_file
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-d"
}

variable "sa_key_file" {
  type = string
}

module "vpc" {
  source = "git::https://github.com/terraform-yc-modules/terraform-yc-vpc.git?ref=1.0.9"

  network_name        = "tf-lang-library-net"
  network_description = "Сеть, созданная готовым модулем из библиотеки"

  private_subnets = [
    {
      name           = "subnet-a"
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["10.50.0.0/24"]
    },
    {
      name           = "subnet-b"
      zone           = "ru-central1-b"
      v4_cidr_blocks = ["10.50.1.0/24"]
    },
  ]
}

output "vpc_id" {
  description = "Идентификатор сети, созданной модулем из библиотеки"
  value       = module.vpc.vpc_id
}

output "subnets" {
  description = "Подсети, созданные модулем"
  value       = module.vpc.private_subnets
}
