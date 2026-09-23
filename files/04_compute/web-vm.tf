# Веб-сервер: загрузочный диск из образа, дополнительный диск для данных,
# начальная настройка через cloud-init.

data "yandex_compute_image" "os" {
  family = var.image_family
}

resource "yandex_compute_instance" "web" {
  name        = "${var.project_name}-web"
  description = "Учебный веб-сервер курса Terraform"

  zone        = var.zone
  platform_id = "standard-v3"

  allow_stopping_for_update = true

  resources {
    cores  = var.web_vm_cores
    memory = var.web_vm_memory

    # Гарантированная доля ядра. 20 % — дешёвый вариант для занятий.
    # В рабочей среде ставят 100 %: иначе производительность зависит
    # от того, насколько загружены соседи по физическому серверу.
    core_fraction = 20
  }

  scheduling_policy {
    # Прерываемая машина: облако вправе остановить её в любой момент.
    # Для веб-сервера в рабочей среде это недопустимо, для занятий —
    # экономия. Данные на загрузочном диске при этом сохраняются.
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
    subnet_id          = module.vpc.subnet_ids["web"]
    nat                = true
    security_group_ids = [module.vpc.security_group_id]
  }

  metadata = {
    # Формат ssh-keys: "пользователь:публичный ключ".
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"

    # Начальная настройка. Подробности — в файле cloud-init/web.yaml.
    user-data = file("${path.module}/cloud-init/web.yaml")

    # Включить последовательную консоль: помогает, когда машина
    # не поднимается и по SSH не пускает.
    serial-port-enable = "1"
  }

  labels = {
    course = "terraform"
    lesson = "4"
    role   = "web"
  }
}

# Дополнительный диск.
#
# Зачем отдельный ресурс, если диск можно описать внутри машины:
#   * диск живёт независимо от машины: её можно удалить и пересоздать,
#     а данные останутся;
#   * на диск можно делать снимки;
#   * диск можно перенести на другую машину.
#
# Обратите внимание на параметр attach_mode: для сетевых дисков
# в Яндекс Облаке используется READ_WRITE.
resource "yandex_compute_disk" "data" {
  name = "${var.project_name}-data"
  type = var.data_disk_type
  zone = var.zone
  size = var.data_disk_size

  labels = {
    course = "terraform"
    lesson = "4"
    role   = "data"
  }
}

resource "yandex_compute_instance" "web_with_disk" {
  # Пример условного создания: машина с дополнительным диском
  # создаётся только в том случае, когда диск действительно нужен.
  # count = 0 означает «ресурса нет».
  count = 0

  name        = "${var.project_name}-web-data"
  description = "Машина с дополнительным диском (пример монтирования)"
  zone        = var.zone
  platform_id = "standard-v3"

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

  secondary_disk {
    disk_id     = yandex_compute_disk.data.id
    auto_delete = false
  }

  network_interface {
    subnet_id          = module.vpc.subnet_ids["web"]
    nat                = true
    security_group_ids = [module.vpc.security_group_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  labels = {
    course = "terraform"
    lesson = "4"
  }
}
