# Сеть для базы данных.
#
# База данных живёт в подсети и доступна по внутренним адресам.
# Публичный доступ к managed-базе включают редко: это отдельный флаг
# у хоста, и он открывает кластер всему интернету.

module "vpc" {
  source = "../modules/vpc"

  network_name = "${var.project_name}-net"

  subnets = {
    data = {
      zone = var.zone
      cidr = "10.80.10.0/24"
    }
  }

  # Наружу ничего не открываем: в этой практике машин нет, а к базе
  # обращаются изнутри сети.
  allowed_ports = []

  labels = {
    course = "terraform"
    lesson = "6"
  }
}

# Группа безопасности для кластера базы данных.
#
# Правило «пускать только из подсети» показывает типовой подход:
# источник задаётся диапазоном адресов приложений, а не 0.0.0.0/0.
# В рабочей среде здесь был бы не диапазон, а ссылка на группу
# безопасности приложений (приём из практики 5).
resource "yandex_vpc_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Доступ к базе данных только изнутри сети"
  network_id  = module.vpc.network_id

  labels = {
    course = "terraform"
    lesson = "6"
    role   = "database"
  }
}

resource "yandex_vpc_security_group_rule" "db_from_subnet" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "ingress"
  description            = "PostgreSQL из внутренней сети"

  protocol       = "TCP"
  port           = 6432
  v4_cidr_blocks = ["10.0.0.0/8"]
}

resource "yandex_vpc_security_group_rule" "db_egress" {
  security_group_binding = yandex_vpc_security_group.db.id
  direction              = "egress"
  description            = "Исходящий трафик"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["0.0.0.0/0"]
}
