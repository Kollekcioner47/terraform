# Версии. Отличие от практики 1 только в комментарии: здесь мы работаем
# с хранилищем состояния в Object Storage, а оно требует Terraform
# не старее 1.6.3.

terraform {
  required_version = ">= 1.6.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.229.0"
    }
  }
}
