terraform {
  required_version = ">= 1.6.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.229.0"
    }
  }

  # Хранилище состояния. Ключ (key) и имя бакета НЕ указаны здесь
  # намеренно: они передаются при инициализации и отличаются для
  # окружений. Так одна и та же конфигурация обслуживает и dev, и prod,
  # а состояния у них разные:
  #
  #   terraform init -backend-config=env/backend-dev.tfvars
  #   terraform init -backend-config=env/backend-prod.tfvars
  #
  # Альтернатива — отдельные каталоги на окружение. Она нагляднее,
  # но приводит к копированию конфигурации. Про выбор — в тексте.
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    region = "ru-central1"

    use_lockfile = true

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
