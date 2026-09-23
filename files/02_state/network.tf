# Сеть и подсеть.
#
# Обратите внимание на имена ресурсов: yandex_vpc_subnet "app" вместо
# "course" из практики 1. Имя ресурса внутри конфигурации — это адрес
# в состоянии Terraform. Переименование без блока moved приведёт
# к удалению и созданию ресурса заново; как этого избежать — в практике.

resource "yandex_vpc_network" "course" {
  name = "${var.project_name}-net"

  labels = {
    course = "terraform"
    lesson = "2"
  }
}

resource "yandex_vpc_subnet" "app" {
  name = "${var.project_name}-subnet-${var.zone}"

  zone           = var.zone
  network_id     = yandex_vpc_network.course.id
  v4_cidr_blocks = ["10.20.20.0/24"]

  labels = {
    course = "terraform"
    lesson = "2"
  }
}
