# Итоговый стенд: сеть, приложение и статический сайт.
#
# Это тот же набор, что собирался по курсу, только в одной
# конфигурации и с разделением по окружениям.

# Локальные значения, которые отличаются от окружения к окружению.
locals {
  # В prod машина обычная и «полноценная», в dev — прерываемая
  # и дешёвая. Одно и то же описание, разные параметры.
  app_cores  = var.environment == "prod" ? 4 : var.app_cores
  app_memory = var.environment == "prod" ? 4 : var.app_memory

  common_labels = {
    course      = "terraform"
    lesson      = "8"
    environment = var.environment
    managed_by  = "terraform"
  }

  # Имя ресурса включает окружение: в одном каталоге можно держать
  # оба стенда и не путать их.
  name_prefix = "${var.project_name}-${var.environment}"
}

module "vpc" {
  source = "../modules/vpc"

  network_name = "${local.name_prefix}-net"

  subnets = {
    app = {
      zone = var.zone
      cidr = "10.100.10.0/24"
    }
  }

  allowed_ports = [22, 80]

  # Машина имеет публичный адрес (nat = true), поэтому NAT-шлюз
  # не нужен — экономия для учебного стенда.
  create_nat_gateway = false

  labels = local.common_labels
}

data "yandex_compute_image" "os" {
  family = var.image_family
}

resource "yandex_compute_instance" "app" {
  count = var.create_app ? 1 : 0

  name = "${local.name_prefix}-app"

  zone        = var.zone
  platform_id = "standard-v3"

  allow_stopping_for_update = true

  resources {
    cores         = local.app_cores
    memory        = local.app_memory
    core_fraction = var.environment == "prod" ? 100 : 20
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = module.vpc.subnet_ids["app"]
    nat                = true
    security_group_ids = [module.vpc.security_group_id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"

    # templatefile подставляет значения в шаблон. Так один файл
    # cloud-init обслуживает все окружения: в страницу попадает
    # название окружения, и на стенде видно, куда вы попали.
    #
    # ВАЖНО ПРО ЭКРАНИРОВАНИЕ. Файл cloud-init/app.yaml — теперь
    # шаблон Terraform, и все подстановки в нём обрабатывает
    # Terraform, а не bash. Если внутри скрипта нужна подстановка
    # bash, доллар удваивается:
    #
    #   "$${ZONE##*/}"   — попадёт в машину как ${ZONE##*/}
    #   "${ZONE##*/}"    — Terraform попытается найти переменную ZONE
    #
    # Вторая запись даёт ошибку, которую мы получили на живом стенде:
    #
    #   Error: Invalid function argument
    #   while calling templatefile(path, vars)
    #   Invalid value for "vars" parameter: vars map does not contain
    #   key "ZONE", referenced at ./cloud-init/app.yaml
    #
    # Причём «поймать» это можно где угодно: даже в комментарии
    # внутри шаблона — Terraform читает комментарии как обычный текст.
    user-data = templatefile("${path.module}/cloud-init/app.yaml", {
      environment = var.environment
    })
  }

  labels = merge(local.common_labels, { role = "app" })

  # Защита от удаления в конфигурации.
  #
  # В prod protect_resources = true, в dev — false. Разница видна
  # сразу: попытка удалить защищённый ресурс заканчивается ошибкой
  #
  #   Error: Instance cannot be destroyed
  #   Resource yandex_compute_instance.app[0] has lifecycle.prevent_destroy
  #   set, but the plan calls for this resource to be destroyed.
  #
  # Цена защиты — лишний шаг при осознанном удалении: сначала снять
  # флаг, применить изменение, и только потом удалять.
  lifecycle {
    prevent_destroy = false

    # Значение.prevent_destroy можно задать переменной: она известна
    # до плана. А вот вычисляемые значения (например, из источника
    # данных) здесь недопустимы — Terraform потребует известное
    # на момент плана значение.
    #
    # В учебной конфигурации оставлен литерал false, иначе стенд
    # не удалить командой terraform destroy. В рабочей среде
    # в этом месте ставят true.

    # Игнорируем изменения метаданных: cloud-init читается только
    # при первом запуске, поэтому правка файла не должна показывать
    # «вечные» изменения в плане.
    ignore_changes = [metadata["user-data"]]
  }
}
