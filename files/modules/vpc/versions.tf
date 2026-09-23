# Модуль сети: версия Terraform и провайдеры.
#
# Модуль объявляет ограничения сам, а не надеется на корневую
# конфигурацию: так его можно подключать в любой проект.

terraform {
  required_version = ">= 1.6.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.229.0"
    }
  }
}
