# Виртуальные машины: два способа создать несколько однотипных ресурсов.

data "yandex_compute_image" "os" {
  family = local.image_family
}

# СПОСОБ 1: for_each по словарю.
#
# Ключ словаря становится ключом элемента: each.key, а значения —
# each.value. В состояние ресурс попадает по адресу
# yandex_compute_instance.app["app"] — с ключом, а не с индексом.
#
# Это значит, что если из словаря убрать одну запись или добавить
# новую, остальные машины не будут пересозданы.
resource "yandex_compute_instance" "app" {
  for_each = var.instances

  name        = local.instance_names[each.key]
  description = "Машина роли ${each.key}, созданная циклом for_each"
  zone        = var.subnets[each.value.subnet].zone

  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
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
    subnet_id = module.vpc.subnet_ids[each.value.subnet]

    # Внешний адрес нужен только машинам окружения dev:
    # условное выражение внутри ресурса.
    nat = var.environment != "prod"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  labels = merge(local.common_labels, { role = each.key })
}

# СПОСОБ 2: count по числу.
#
# count создаёт ресурсы с индексами: yandex_compute_instance.worker[0],
# [1], [2]. Внутри ресурса номер доступен как count.index.
#
# Когда что применять:
#   count    — ресурсы полностью взаимозаменяемы (три одинаковых
#              исполнителя очереди);
#   for_each — у ресурсов есть осмысленный ключ (роли, зоны, имена).
#
# Опасность count: если удалить элемент из середины списка, все
# последующие сдвинут индексы, и Terraform пересоздаст их.
resource "yandex_compute_instance" "worker" {
  count = var.worker_count

  name        = "${var.project_name}-${var.environment}-worker-${count.index + 1}"
  description = "Машина-исполнитель номер ${count.index + 1}, созданная циклом count"

  # Зона берётся из подсети, а не из переменной zone: иначе при
  # несовпадении зон облако откажет в создании машины.
  zone = var.subnets[local.subnet_in_default_zone].zone

  platform_id               = "standard-v3"
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
    # Обращаемся к подсети по имени: если такой подсети нет,
    # Terraform сообщит об этом на этапе плана.
    subnet_id = module.vpc.subnet_ids[local.subnet_in_default_zone]
    nat       = var.environment != "prod"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  labels = merge(local.common_labels, { role = "worker" })
}

# Условное создание ресурса.
#
# Если enable_debug_vm = false, count равен нулю и ресурса нет вовсе.
# Так удобно включать отладочные машины на время разбора инцидента.
resource "yandex_compute_instance" "debug" {
  count = var.enable_debug_vm ? 1 : 0

  name        = "${var.project_name}-${var.environment}-debug"
  description = "Отладочная машина, создаётся по требованию"
  zone        = var.subnets[local.subnet_in_default_zone].zone

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

  network_interface {
    subnet_id = module.vpc.subnet_ids[local.subnet_in_default_zone]
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  labels = merge(local.common_labels, { role = "debug" })
}
