# Опсание что мы используем в качестве провайдера, в нашем случае яндекс
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
locals {
  cloud_id = "b1g6o28sojslu5i7ejuu"
  folder_id = "b1girgsodhjtp9a0laq4"
}
# зададим в качаестве переменных наши ид облака и папки

# зона создания ресурсов, в некоторых провайдерах указывается region
provider "yandex" {
  zone = "ru-central1-a"
  cloud_id = local.cloud_id
  folder_id = local.folder_id
  service_account_key_file = "C:/tf_cloud/authorized_key.json"
  }


