# Сеть для кластера Kubernetes.
#
# Подсети нужны в тех зонах, где будут мастер и узлы:
#   * у зонального мастера — одна зона, подсети хватит одной;
#   * у регионального мастера — три зоны, и подсеть нужна в каждой,
#     иначе облако не сможет разместить три экземпляра мастера.
#
# Мы создаём три подсети всегда: так конфигурация одинаково работает
# с любым типом мастера, а переключение типа не требует пересборки сети.

module "vpc" {
  source = "../modules/vpc"

  network_name = "${var.project_name}-net"

  subnets = {
    k8s-a = {
      zone = "ru-central1-a"
      cidr = "10.90.10.0/24"
    }
    k8s-b = {
      zone = "ru-central1-b"
      cidr = "10.90.20.0/24"
    }
    k8s-d = {
      zone = "ru-central1-d"
      cidr = "10.90.30.0/24"
    }
  }

  # Узлам нужен доступ к реестру образов, к API Kubernetes и для
  # установки пакетов, поэтому исходящий трафик открыт (в модуле
  # правило egress разрешает всё). Входящий трафик наружу открывать
  # не нужно: к кластеру обращаются через API.
  allowed_ports = []

  # Узлы создаются БЕЗ публичных адресов (nat = false в шаблоне
  # группы узлов), поэтому им нужен NAT-шлюз — иначе они не смогут
  # скачать образы, и поды останутся в состоянии ImagePullBackOff.
  # Подробно эта ловушка разобрана в практике 4.
  create_nat_gateway = true

  labels = {
    course = "terraform"
    lesson = "7"
  }
}

# Отдельная группа безопасности для кластера и узлов.
#
# Kubernetes требует более широких правил, чем обычная машина:
# узлам нужно общаться друг с другом, с мастером и с балансировщиком
# внутри сети. Поэтому правило «всё внутри своей сети» здесь —
# не лень, а необходимость.
resource "yandex_vpc_security_group" "k8s" {
  name        = "${var.project_name}-k8s-sg"
  description = "Трафик внутри кластера и узлов"
  network_id  = module.vpc.network_id

  labels = {
    course = "terraform"
    lesson = "7"
  }
}

resource "yandex_vpc_security_group_rule" "k8s_internal" {
  security_group_binding = yandex_vpc_security_group.k8s.id
  direction              = "ingress"
  description            = "Трафик внутри кластера"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["10.90.0.0/16"]
}

# Доступ к API-серверу снаружи.
#
# Без этого правила kubectl с рабочей машины не подключается —
# и это выглядит как «кластер не работает»:
#
#   Unable to connect to the server: dial tcp 130.193.46.202:443:
#   connectex: A connection attempt failed because the connected party
#   did not properly respond after a period of time
#
# Мастер доступен по публичному адресу (public_ip = true), но группа
# безопасности пускала трафик только изнутри сети. Мы получили эту
# ошибку на живом стенде.
#
# В учебной конфигурации открыт весь интернет. В рабочей среде здесь
# должен быть адрес офиса или VPN:
#
#   v4_cidr_blocks = ["203.0.113.10/32"]
resource "yandex_vpc_security_group_rule" "k8s_api" {
  security_group_binding = yandex_vpc_security_group.k8s.id
  direction              = "ingress"
  description            = "Доступ к API Kubernetes (учебный стенд)"

  protocol       = "TCP"
  port           = 443
  v4_cidr_blocks = ["0.0.0.0/0"]
}

resource "yandex_vpc_security_group_rule" "k8s_egress" {
  security_group_binding = yandex_vpc_security_group.k8s.id
  direction              = "egress"
  description            = "Исходящий трафик"

  protocol       = "ANY"
  from_port      = 0
  to_port        = 65535
  v4_cidr_blocks = ["0.0.0.0/0"]
}
