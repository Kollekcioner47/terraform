# Строим вебсервис
# Опсание что мы используем в качестве провайдера, в нашем случае яндекс
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
# зона создания ресурсов, в некоторых провайдерах указывается region
provider "yandex" {
  zone = "ru-central1-a"
  service_account_key_file = "C:/tf_cloud/authorized_key.json"
}

resource "yandex_compute_instance" "vm-1" {
  name = "vm-1"

  resources {
    cores  = 2
    memory = 2
    
  }

  boot_disk {
    initialize_params {
# Образ - это какая операционка внутри, если говорим о сервере
      image_id = "fd807ed79a4kkqfvd1mb"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
# здесь мы укажем ключ, который используем для подключения к ВМ
  metadata = {
    ssh-keys = "ubuntu:${file("id_ed25519.pub")}"
    user-data = file("users.txt")
    
  }
}
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}