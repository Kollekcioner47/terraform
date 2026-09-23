# Сетевой балансировщик.
#
# Задача: у нас несколько одинаковых веб-серверов, и нужен один адрес,
# по которому к ним обращаться. Балансировщик распределяет запросы
# между машинами и перестаёт отправлять их на нездоровые.

resource "yandex_lb_target_group" "web" {
  count = var.create_load_balancer ? 1 : 0

  name      = "${var.project_name}-tg"
  folder_id = var.folder_id

  # Цели — это машины, между которыми распределяется трафик.
  # Мы не перечисляем их руками: берём из группы машин, чтобы список
  # целей сам следовал за изменениями группы.
  dynamic "target" {
    for_each = yandex_compute_instance_group.web.instances

    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }

  labels = {
    course = "terraform"
    lesson = "4"
  }
}

resource "yandex_lb_network_load_balancer" "web" {
  count = var.create_load_balancer ? 1 : 0

  name      = "${var.project_name}-nlb"
  folder_id = var.folder_id
  type      = "external"

  # Слушатель: какой порт балансировщик принимает снаружи.
  listener {
    name        = "http"
    port        = 80
    target_port = 80
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.web[0].id

    # Проверка состояния на стороне балансировщика. Она независима
    # от healthcheck группы машин: балансировщик сам решает, какие
    # цели считать живыми.
    healthcheck {
      name     = "http-check"
      interval = 5
      timeout  = 3

      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_options {
        port = 80
        path = "/"
      }
    }
  }

  labels = {
    course = "terraform"
    lesson = "4"
  }
}
