# Прикладной балансировщик (Application Load Balancer, L7).
#
# Чем отличается от сетевого (NLB) из практики 4:
#
#   NLB работает на четвёртом уровне: распределяет TCP-соединения,
#   ничего не знает про HTTP, не умеет маршрутизировать по путям
#   и заголовкам.
#
#   ALB работает на седьмом уровне: понимает HTTP, умеет отправлять
#   разные запросы на разные группы бэкендов (маршрутизация по пути
#   и по имени хоста), терминировать HTTPS, добавлять и менять
#   заголовки, ограничивать скорость запросов.
#
# Из чего состоит ALB в Terraform — четыре ресурса, и это важно
# запомнить, потому что их часто путают:
#
#   yandex_alb_target_group    кто принимает трафик (машины и их адреса)
#   yandex_alb_backend_group   как обращаться к машинам и как их проверять
#   yandex_alb_http_router     правила маршрутизации (роутер)
#   yandex_alb_virtual_host    привязка правил и бэкендов (виртуальный хост)
#
# Плюс сам yandex_alb_load_balancer: слушатели, зоны и группы
# безопасности.

resource "yandex_alb_target_group" "web" {
  count = var.create_alb ? 1 : 0

  name = "${var.project_name}-alb-tg"

  target {
    # Цель — наша машина. Адрес внутренний: балансировщик общается
    # с бэкендами внутри облака, наружу смотрит только он сам.
    ip_address = yandex_compute_instance.web.network_interface[0].ip_address
    subnet_id  = yandex_compute_instance.web.network_interface[0].subnet_id
  }

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

resource "yandex_alb_backend_group" "web" {
  count = var.create_alb ? 1 : 0

  name = "${var.project_name}-alb-bg"

  http_backend {
    name = "web-backend"

    weight = 1
    port   = 80

    target_group_ids = [yandex_alb_target_group.web[0].id]

    # Проверка здоровья на стороне балансировщика. Интервалы
    # задаются строками с единицами измерения: "2s", "500ms".
    healthcheck {
      timeout  = "1s"
      interval = "2s"

      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  count = var.create_alb ? 1 : 0

  name = "${var.project_name}-alb-router"

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

resource "yandex_alb_virtual_host" "web" {
  count = var.create_alb ? 1 : 0

  name           = "${var.project_name}-alb-vh"
  http_router_id = yandex_alb_http_router.web[0].id

  # По каким именам хоста отвечает этот виртуальный хост.
  # Пустой список означает «любое имя».
  authority = ["*"]

  route {
    name = "main"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web[0].id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  count = var.create_alb ? 1 : 0

  name = "${var.project_name}-alb"

  network_id = yandex_vpc_network.this.id

  security_group_ids = [yandex_vpc_security_group.alb[0].id]

  # Где размещается балансировщик. Каждый узел живёт в своей подсети,
  # поэтому для отказоустойчивости перечисляют несколько зон со своими
  # подсетями.
  allocation_policy {
    location {
      zone_id   = var.zone
      subnet_id = yandex_vpc_subnet.this["web-d"].id
    }
  }

  # Слушатель: что и на каком порту принимает балансировщик.
  listener {
    name = "http"

    endpoint {
      # Тип адреса надо указать явно. Пустой блок address {}
      # облако не принимает:
      #
      #   Error: Either external ipv4 address or internal ipv4 address
      #   or external ipv6 address should be specified
      #
      # Пустой вложенный блок external_ipv4_address означает «выдай
      # публичный адрес сам». Тот же приём работает и с закреплённым
      # адресом:
      #
      #   external_ipv4_address {
      #     address = yandex_vpc_address.alb.external_ipv4_address[0].address
      #   }
      address {
        external_ipv4_address {}
      }

      ports = [80]
    }

    # Обработка HTTP поручена HTTP-роутеру: именно он решает,
    # на какую группу бэкендов отправить запрос.
    http {
      handler {
        http_router_id = yandex_alb_http_router.web[0].id

        # Здесь же настраивают редирект с HTTP на HTTPS и
        # терминирование TLS сертификатом из Certificate Manager:
        #
        #   redirect_http_to_https = true
        #   certificate_id = yandex_cm_certificate.this.id
      }
    }
  }

  labels = {
    course = "terraform"
    lesson = "5"
  }
}
