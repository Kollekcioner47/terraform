# Сеть и подсеть.
#
# Облачная сеть — глобальный ресурс: она не привязана к зоне доступности.
# Подсеть — зональный: у неё есть зона и диапазон адресов.
#
# Для учебного стенда достаточно одной подсети. В практике 5 мы сделаем
# три подсети в трёх зонах, чтобы разбирать отказоустойчивость.

resource "yandex_vpc_network" "course" {
  name = "${var.project_name}-net"

  description = "Учебная сеть курса Terraform"

  labels = {
    course = "terraform"
  }
}

resource "yandex_vpc_subnet" "course" {
  name = "${var.project_name}-subnet-${var.zone}"

  zone       = var.zone
  network_id = yandex_vpc_network.course.id

  # Диапазон адресов подсети. Первые два адреса диапазона и последний
  # зарезервированы облаком, поэтому 254 адреса — это 251 машина.
  v4_cidr_blocks = ["10.10.10.0/24"]

  labels = {
    course = "terraform"
  }
}
