# Группы безопасности: правила отдельными ресурсами.
#
# Разбираем два подхода к описанию правил:
#
#  1. Вложенные блоки ingress/egress внутри группы безопасности.
#     Компактно, но при изменении одного правила Terraform пересоздаёт
#     блок целиком, и в истории изменений это выглядит как правка
#     всей группы.
#
#  2. Отдельные ресурсы yandex_vpc_security_group_rule.
#     Правила видны поштучно, их можно добавлять и удалять
#     независимо, а в плане видно, какое именно правило меняется.
#
# Здесь используем второй подход: он ближе к рабочей практике.

# Группа безопасности веб-серверов.
resource "yandex_vpc_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Доступ к веб-серверам из интернета"
  network_id  = yandex_vpc_network.this.id

  labels = {
    course = "terraform"
    lesson = "5"
    role   = "web"
  }
}

# Веб-порты из интернета.
resource "yandex_vpc_security_group_rule" "web_public" {
  for_each = toset([for p in var.web_ports : tostring(p)])

  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  description            = "Порт ${each.value} для клиентов"

  protocol       = "TCP"
  port           = tonumber(each.value)
  v4_cidr_blocks = ["0.0.0.0/0"]
}

# SSH. В учебной конфигурации открыт всем, в рабочей — только
# адресам офиса или через бастион:
#
#   v4_cidr_blocks = ["203.0.113.10/32"]
#
# Оставлять 0.0.0.0/0 на 22-й порт в рабочей среде недопустимо:
# перебор паролей и попытки подбора ключей начинаются в первые часы.
resource "yandex_vpc_security_group_rule" "web_ssh" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "ingress"
  description            = "SSH для администратора (в занятиях — отовсюду)"

  protocol       = "TCP"
  port           = 22
  v4_cidr_blocks = ["0.0.0.0/0"]
}

# Исходящий трафик: разрешён полностью (см. практику 4 — иначе
# cloud-init не сможет установить пакеты).
resource "yandex_vpc_security_group_rule" "web_egress" {
  security_group_binding = yandex_vpc_security_group.web.id
  direction              = "egress"
  description            = "Исходящий трафик"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["0.0.0.0/0"]
}

# Группа безопасности внутренних сервисов.
#
# Правило «откуда» задаётся не адресами, а ССЫЛКОЙ НА ДРУГУЮ ГРУППУ
# БЕЗОПАСНОСТИ. Это важный приём: адреса в облаке меняются (машины
# пересоздаются, подсети расширяются), а группы остаются.
#
# Так описывают доступ «приложение -> база данных», не перечисляя
# адреса приложений.
resource "yandex_vpc_security_group" "internal" {
  name        = "${var.project_name}-internal-sg"
  description = "Доступ к внутренним сервисам только с веб-серверов"
  network_id  = yandex_vpc_network.this.id

  labels = {
    course = "terraform"
    lesson = "5"
    role   = "internal"
  }
}

resource "yandex_vpc_security_group_rule" "internal_from_web" {
  security_group_binding = yandex_vpc_security_group.internal.id
  direction              = "ingress"
  description            = "Трафик от машин группы web"

  protocol = "TCP"
  port     = 8080

  # Источник — идентификатор другой группы безопасности.
  security_group_id = yandex_vpc_security_group.web.id
}

resource "yandex_vpc_security_group_rule" "internal_egress" {
  security_group_binding = yandex_vpc_security_group.internal.id
  direction              = "egress"
  description            = "Исходящий трафик"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["0.0.0.0/0"]
}

# Группа безопасности прикладного балансировщика.
#
# Балансировщику нужна своя группа: он принимает клиентский трафик
# из интернета и сам обращается к машинам за проверкой здоровья.
resource "yandex_vpc_security_group" "alb" {
  count = var.create_alb ? 1 : 0

  name        = "${var.project_name}-alb-sg"
  description = "Группа безопасности прикладного балансировщика"
  network_id  = yandex_vpc_network.this.id

  labels = {
    course = "terraform"
    lesson = "5"
    role   = "alb"
  }
}

resource "yandex_vpc_security_group_rule" "alb_public" {
  for_each = var.create_alb ? toset(["80"]) : toset([])

  security_group_binding = yandex_vpc_security_group.alb[0].id
  direction              = "ingress"
  description            = "HTTP от клиентов"

  protocol       = "TCP"
  port           = tonumber(each.value)
  v4_cidr_blocks = ["0.0.0.0/0"]
}

resource "yandex_vpc_security_group_rule" "alb_egress" {
  count = var.create_alb ? 1 : 0

  security_group_binding = yandex_vpc_security_group.alb[0].id
  direction              = "egress"
  description            = "Обращения к машинам и служебный трафик"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["0.0.0.0/0"]
}
