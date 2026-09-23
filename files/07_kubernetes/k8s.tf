# Кластер Managed Service for Kubernetes и группа узлов.
#
# ЧТО СТОИТ ДЕНЕГ И ВРЕМЕНИ
#
#   Мастер кластера платный круглосуточно — независимо от того,
#   работают ли узлы. Создаётся он 10-15 минут, удаляется тоже
#   не мгновенно. Поэтому в курсе кластер включают переменной
#   create_cluster на время разбора.
#
#   Узлы — это обычные виртуальные машины: за них платят как за машины.
#   Мы делаем их прерываемыми, чтобы снизить цену занятий.

# ------------------------------------------------------------------
# Сервисные аккаунты: их два, и они разные
# ------------------------------------------------------------------

# Сервисный аккаунт КЛАСТЕРА. От его имени мастер создаёт и удаляет
# ресурсы: диски узлов, адреса, балансировщики. Роли —
# из документации Managed Service for Kubernetes:
#
#   k8s.clusters.agent      — управлять ресурсами кластера и узлов;
#   vpc.publicAdmin         — выдавать публичные адреса (нужно, если
#                             узлы получают внешний адрес);
#   container-registry.images.puller — забирать образы из реестра.
resource "yandex_iam_service_account" "k8s_cluster" {
  count = var.create_cluster ? 1 : 0

  name        = "${var.project_name}-cluster-sa"
  description = "Сервисный аккаунт кластера Kubernetes"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_agent" {
  count = var.create_cluster ? 1 : 0

  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc_admin" {
  count = var.create_cluster ? 1 : 0

  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster[0].id}"
}

# Сервисный аккаунт УЗЛОВ. Узлы забирают образы из реестра
# и подключают диски, поэтому роли другие.
resource "yandex_iam_service_account" "k8s_nodes" {
  count = var.create_cluster ? 1 : 0

  name        = "${var.project_name}-nodes-sa"
  description = "Сервисный аккаунт узлов кластера"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_puller" {
  count = var.create_cluster ? 1 : 0

  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_compute" {
  count = var.create_cluster ? 1 : 0

  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_vpc" {
  count = var.create_cluster ? 1 : 0

  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes[0].id}"
}

# ------------------------------------------------------------------
# Кластер
# ------------------------------------------------------------------

resource "yandex_kubernetes_cluster" "this" {
  count = var.create_cluster ? 1 : 0

  name        = "${var.project_name}-cluster"
  description = "Учебный кластер Kubernetes курса Terraform"

  network_id = module.vpc.network_id

  master {
    # ЗОНАЛЬНЫЙ мастер — один экземпляр в одной зоне: дешевле,
    # но при отказе зоны кластер недоступен.
    dynamic "zonal" {
      for_each = var.master_type == "zonal" ? [1] : []

      content {
        zone      = var.zone
        subnet_id = module.vpc.subnet_ids["k8s-d"]
      }
    }

    # РЕГИОНАЛЬНЫЙ мастер — три экземпляра в трёх зонах: дороже,
    # зато отказ одной зоны кластер переживает. Требует подсеть
    # в каждой из трёх зон.
    dynamic "regional" {
      for_each = var.master_type == "regional" ? [1] : []

      content {
        region = "ru-central1"

        location {
          zone      = "ru-central1-a"
          subnet_id = module.vpc.subnet_ids["k8s-a"]
        }

        location {
          zone      = "ru-central1-b"
          subnet_id = module.vpc.subnet_ids["k8s-b"]
        }

        location {
          zone      = "ru-central1-d"
          subnet_id = module.vpc.subnet_ids["k8s-d"]
        }
      }
    }

    # Публичный адрес API-сервера: без него kubectl с рабочей машины
    # не подключится. В рабочей среде доступ к API чаще закрывают:
    # оставляют только внутренний адрес и ходят через бастион
    # или VPN.
    public_ip = true

    version = var.k8s_version != "" ? var.k8s_version : null

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "monday"
        start_time = "03:00"
        duration   = "3h"
      }
    }

    security_group_ids = [yandex_vpc_security_group.k8s.id]
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster[0].id
  node_service_account_id = yandex_iam_service_account.k8s_nodes[0].id

  # Канал обновлений: STABLE — проверенные версии, RAPID — новые.
  # Для занятий STABLE предсказуемее.
  release_channel = "STABLE"

  labels = {
    course = "terraform"
    lesson = "7"
  }

  # Права выдаются до создания кластера, иначе он не сможет создать
  # свои ресурсы. Явная зависимость надёжнее, чем «обычно успевает».
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_agent,
    yandex_resourcemanager_folder_iam_member.k8s_vpc_admin,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_puller,
  ]
}

# ------------------------------------------------------------------
# Группа узлов
# ------------------------------------------------------------------

resource "yandex_kubernetes_node_group" "workers" {
  count = var.create_cluster ? 1 : 0

  cluster_id = yandex_kubernetes_cluster.this[0].id
  name       = "${var.project_name}-workers"

  # Версия узлов не может быть новее версии мастера. Пустая строка
  # означает «как у мастера».
  version = var.k8s_version != "" ? var.k8s_version : null

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = var.node_cores
      memory        = var.node_memory
      core_fraction = 20
    }

    scheduling_policy {
      preemptible = true
    }

    boot_disk {
      type = "network-hdd"

      # МИНИМАЛЬНЫЙ РАЗМЕР ДИСКА УЗЛА — 30 ГБ, и это не рекомендация,
      # а жёсткое требование облака. С диском 20 ГБ группа узлов
      # уходит в бесконечное создание машин, а в списке инстансов
      # видно причину:
      #
      #   STATUS: CREATING_INSTANCE [27m]
      #   [INVALID_ARGUMENT] Request validation error:
      #   Disk size must be greater or equal than 30.0 GB
      #
      # Мы получили эту ошибку на живом стенде. Обратите внимание:
      # Terraform при этом не падает — группа узлов просто не
      # становится готовой, а apply ждёт. Смотреть надо в состояние
      # группы машин, а не в вывод Terraform.
      size = 30
    }

    network_interface {
      # Узлы размещаются без публичных адресов, но с доступом
      # в интернет для загрузки образов: помогает NAT-шлюз (модуль
      # создаёт его при create_nat_gateway = true).
      nat                = false
      subnet_ids         = [module.vpc.subnet_ids["k8s-d"]]
      security_group_ids = [yandex_vpc_security_group.k8s.id]
    }

    container_runtime {
      type = "containerd"
    }

    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
    }

    labels = {
      course = "terraform"
      lesson = "7"
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  deploy_policy {
    max_expansion   = 1
    max_unavailable = 0
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
