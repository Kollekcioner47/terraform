# Сеть, подсети и группа безопасности.
#
# Здесь собраны приёмы языка Terraform, которые чаще всего нужны
# на практике: for_each по словарю, динамический блок и условное
# создание ресурсов.

resource "yandex_vpc_network" "this" {
  name   = var.network_name
  labels = var.labels
}

# NAT-шлюз: выход в интернет для машин без публичных адресов.
#
# Выключен по умолчанию: шлюз платный, и в конфигурациях без приватных
# машин он не нужен. Включается переменной create_nat_gateway.
resource "yandex_vpc_gateway" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name = "${var.network_name}-nat"
  shared_egress_gateway {}
}

# Таблица маршрутизации: весь трафик «не в свою сеть» идёт через шлюз.
resource "yandex_vpc_route_table" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name       = "${var.network_name}-rt"
  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat[0].id
  }
}

# for_each по словарю подсетей.
#
# Почему for_each, а не count: ключом словаря служит ИМЯ подсети.
# Добавление подсети в середину словаря не сдвинет адреса остальных
# элементов состояния (в отличие от count, где всё зависит от позиции).
resource "yandex_vpc_subnet" "this" {
  for_each = var.subnets

  # Имя подсети включает имя сети, а имя сети — окружение.
  #
  # ПОЧЕМУ ТАК, А НЕ ПРОСТО each.key. Имя подсети должно быть
  # уникальным в пределах КАТАЛОГА. Когда в одном каталоге живут
  # два окружения (dev и prod), подсети с именем «app» из разных
  # сетей сталкиваются:
  #
  #   Error: Error while requesting API to create subnet:
  #   code = AlreadyExists desc = Subnet with name app already exists
  #
  # Мы получили эту ошибку, запуская итоговый стенд в двух
  # окружениях. Лечится это на уровне модуля — префиксом, а не
  # правкой каждого вызова.
  name = "${var.network_name}-${each.key}"
  zone = each.value.zone

  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]

  # Ссылка на таблицу маршрутизации появляется только вместе со шлюзом.
  route_table_id = var.create_nat_gateway ? yandex_vpc_route_table.nat[0].id : null

  labels = var.labels
}

# Динамический блок.
#
# Правила для каждого порта из списка однотипны, и писать их руками
# значит копировать один и тот же блок. dynamic "ingress" генерирует
# блоки по коллекции.
#
# Обратите внимание на имя переменной в content: это имя самого
# динамического блока (ingress), а не какое-то зарезервированное слово.
resource "yandex_vpc_security_group" "this" {
  name        = "${var.network_name}-sg"
  description = "Группа безопасности, созданная модулем vpc"
  network_id  = yandex_vpc_network.this.id

  labels = var.labels

  dynamic "ingress" {
    for_each = var.allowed_ports

    content {
      description    = "Порт ${ingress.value} из интернета"
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Исходящий трафик разрешён полностью.
  #
  # Это не «на всякий случай», а необходимость: установка пакетов идёт
  # на порты 80 и 443 к зеркалам репозиториев, разрешение имён — на 53-й,
  # обращения к API — тоже наружу. Ограничив исходящий трафик, вы
  # получите машину, которая грузится, но не может доустановить ни одного
  # пакета, а cloud-init завершится ошибкой вида:
  #
  #   Cannot initiate the connection to mirror.yandex.ru:80
  #   connection timed out
  #
  # В рабочей среде исходящий трафик принято сужать явно: разрешить
  # конкретные адреса обновлений, DNS и API облака, остальное закрыть.
  egress {
    description    = "Исходящий трафик"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
