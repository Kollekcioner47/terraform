# Группа виртуальных машин.
#
# Группа — это способ сказать «мне нужно N одинаковых машин, следи
# за ними сам»: облако само создаст их по шаблону, заменит упавшие
# и (при желании) изменит их число под нагрузку.

# Сервисный аккаунт для группы. Группа действует от его имени:
# создаёт машины, подключает диски, регистрирует их в балансировщике.
resource "yandex_iam_service_account" "ig" {
  name        = "${var.project_name}-ig-sa"
  description = "Сервисный аккаунт для группы виртуальных машин"
}

# Права сервисного аккаунта группы.
#
# compute.editor — управлять виртуальными машинами и дисками;
# vpc.user — подключать машины к подсетям и группам безопасности.
#
# Выдавать группе роль editor на каталог не нужно: это шире, чем
# требуется. Чем меньше прав у сервисного аккаунта, тем меньше
# последствия, если он скомпрометирован.
resource "yandex_resourcemanager_folder_iam_member" "ig_compute" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ig_vpc" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.ig.id}"
}

resource "yandex_compute_instance_group" "web" {
  name               = "${var.project_name}-ig"
  description        = "Группа веб-серверов, создана Terraform"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.ig.id

  # Защита от случайного удаления. При true terraform destroy
  # не сможет удалить группу, пока флаг не снят руками.
  deletion_protection = false

  # Группа должна создаваться после выдачи прав сервисному аккаунту:
  # иначе облако откажет в создании машин.
  depends_on = [
    yandex_resourcemanager_folder_iam_member.ig_compute,
    yandex_resourcemanager_folder_iam_member.ig_vpc,
  ]

  # Шаблон машины. Всё, что описывает одну машину, живёт здесь.
  instance_template {
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
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.os.id
        type     = "network-hdd"
        size     = 10
      }
    }

    network_interface {
      network_id         = module.vpc.network_id
      subnet_ids         = [module.vpc.subnet_ids["web"]]
      security_group_ids = [module.vpc.security_group_id]

      # Внешние адреса машинам группы не нужны: трафик приходит
      # через балансировщик, а доступ для отладки — через него же.
      nat = false
    }

    metadata = {
      ssh-keys  = "ubuntu:${file(var.ssh_public_key)}"
      user-data = file("${path.module}/cloud-init/web.yaml")
    }

    labels = {
      course = "terraform"
      lesson = "4"
      role   = "web"
    }
  }

  # Сколько машин держать.
  #
  # fixed_scale — фиксированное число: просто и предсказуемо.
  # auto_scale  — облако само меняет число машин по нагрузке на CPU.
  # Ниже показаны оба варианта, выбор — переменной.
  dynamic "scale_policy" {
    for_each = var.ig_autoscaling ? [1] : []

    content {
      auto_scale {
        min_zone_size          = 1
        max_size               = 3
        initial_size           = var.ig_size
        measurement_duration   = 60
        warmup_duration        = 120
        cpu_utilization_target = 60
      }
    }
  }

  dynamic "scale_policy" {
    for_each = var.ig_autoscaling ? [] : [1]

    content {
      fixed_scale {
        size = var.ig_size
      }
    }
  }

  # В каких зонах размещать машины группы.
  # Для отказоустойчивости перечисляют несколько зон — тогда машины
  # распределятся между ними.
  allocation_policy {
    zones = [var.zone]
  }

  # Как обновлять машины группы при изменении шаблона.
  #
  # max_unavailable — сколько машин можно вывести из строя одновременно;
  # max_expansion   — сколько машин можно временно добавить.
  # Если оба значения нулевые, обновление невозможно: облаку негде
  # разместить новые машины и некого вывести из строя.
  #
  # strategy принимает только два значения:
  #   proactive     — машины меняются сразу после правки шаблона,
  #                   группа сама приводит себя к новому виду;
  #   opportunistic — замена происходит не сразу, а когда машина
  #                   пересоздаётся по другой причине (например,
  #                   её заменил health check).
  # Для учебного стенда удобнее proactive: изменения видны сразу.
  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
    strategy        = "proactive"
  }

  # Проверка состояния машин.
  #
  # Без проверки группа считает машину здоровой по факту запуска,
  # даже если приложение на ней не поднялось. С проверкой облако
  # само пересоздаст машину, которая не отвечает, — это и называется
  # самовосстановлением (autohealing).
  health_check {
    interval = 15
    timeout  = 5

    healthy_threshold   = 2
    unhealthy_threshold = 3

    http_options {
      port = 80
      path = "/"
    }
  }

  labels = {
    course = "terraform"
    lesson = "4"
  }
}
