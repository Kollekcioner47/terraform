# Сеть, подсети в трёх зонах и выход в интернет.
#
# Разбираем три вещи, которые в учебных конфигурациях обычно
# пропускают: зональность ресурсов, маршрутизацию и разницу между
# «подсеть по умолчанию» и своей подсетью.

resource "yandex_vpc_network" "this" {
  name        = "${var.project_name}-net"
  description = "Учебная сеть курса Terraform, практика 5"

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

# Подсети в разных зонах.
#
# Обратите внимание: одна сеть — много подсетей. Сеть глобальная
# (не привязана к зоне), подсеть зональная. Машина может находиться
# только в подсети своей зоны.
resource "yandex_vpc_subnet" "this" {
  for_each = var.subnets

  name = "${var.project_name}-${each.key}"
  zone = each.value.zone

  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value.cidr]

  # Таблица маршрутизации появится ниже; ссылка на неё нужна, чтобы
  # машины без публичных адресов могли ходить в интернет.
  route_table_id = var.enable_nat_gateway ? yandex_vpc_route_table.nat[0].id : null

  labels = {
    course = "terraform"
    lesson = "5"
    zone   = each.value.zone
  }
}

# NAT-шлюз: выход в интернет для машин без публичных адресов.
#
# Подробно разобран в практике 4 — там без него не работала группа
# машин. Здесь он нужен по той же причине: веб-серверы мы ставим
# за балансировщик и публичных адресов им не выдаём.
resource "yandex_vpc_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name = "${var.project_name}-nat"
  shared_egress_gateway {}
}

# Таблица маршрутизации: «весь трафик не в свою сеть — через шлюз».
#
# Таблица создаётся одна на сеть, а подключается к подсетям.
# Если таблицу не подключить, шлюз не заработает: машины просто
# не будут знать, куда отправлять пакеты наружу.
resource "yandex_vpc_route_table" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name       = "${var.project_name}-rt"
  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat[0].id
  }

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

# ПРОВЕРКА ЗОНАЛЬНОСТИ
#
# Полезное наблюдение для самостоятельной работы: список зон облака
# и список ваших подсетей — разные вещи. Посмотреть, какие зоны
# доступны в облаке:
#
#   yc compute zone list
#
# А теперь сравните с тем, что создали мы: подсети есть в зонах a, b
# и d, а зоны e и m остались без подсетей. Машину в зоне без подсети
# создать нельзя — облако ответит ошибкой, что подсеть не найдена.
#
# Именно поэтому подсети создают заранее, по одной на каждую зону,
# в которой планируется размещать ресурсы.

