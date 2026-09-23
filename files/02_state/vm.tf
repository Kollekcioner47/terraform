# Виртуальная машина практики 2.
#
# Машина нужна, чтобы было что импортировать, переименовывать и выводить
# из-под управления. Всё то же можно проделать и с сетью, но на машине
# разница между «изменено» и «пересоздано» виднее.

data "yandex_compute_image" "os" {
  family = var.image_family
}

resource "yandex_compute_instance" "app" {
  name        = "${var.project_name}-vm"
  description = "Учебная машина курса Terraform, практика 2"

  zone        = var.zone
  platform_id = "standard-v3"

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  labels = {
    course = "terraform"
    lesson = "2"
  }
}
