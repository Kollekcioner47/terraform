# Кластер Managed Service for PostgreSQL.
#
# Managed-база — это не «PostgreSQL на арендованной машине»: облако
# само делает резервные копии, следит за отказоустойчивостью,
# обновляет минорные версии и умеет переключать мастер.
#
# ЧТО ЗДЕСЬ СТОИТ ДЕНЕГ: кластер платный даже в простое. Минимальный
# класс s2.micro с диском 10 ГБ — это несколько десятков рублей
# в сутки. Поэтому в учебном стенде кластер включают переменной
# create_database на время разбора и обязательно удаляют.

resource "yandex_mdb_postgresql_cluster" "db" {
  count = var.create_database ? 1 : 0

  name        = "${var.project_name}-pg"
  description = "Учебный кластер PostgreSQL курса Terraform"

  # environment — это не «название среды», а режим кластера:
  #   PRESTABLE — для тестов, PRODUCTION — для рабочей нагрузки.
  # Разница в частоте обновлений и в поддержке.
  environment = "PRESTABLE"

  network_id = module.vpc.network_id

  security_group_ids = [yandex_vpc_security_group.db.id]

  # Защита от удаления: пока флаг true, кластер не удалится
  # ни через Terraform, ни через консоль.
  deletion_protection = false

  labels = {
    course = "terraform"
    lesson = "6"
  }

  config {
    version = var.db_version

    # Класс ресурсов хоста и диск.
    resources {
      resource_preset_id = var.db_preset
      disk_type_id       = "network-ssd"
      disk_size          = var.db_disk_size
    }

    # Окно резервного копирования: время, когда облако снимает копию.
    # По умолчанию выбирается автоматически; здесь указано явно,
    # чтобы показать, что это настраивается.
    backup_window_start {
      hours   = 3
      minutes = 0
    }
  }

  # Хосты кластера. Один хост — учебный вариант: он не переживёт
  # отказа зоны. Для отказоустойчивости хосты размещают в разных
  # зонах: три хоста дают кворум и автоматическое переключение.
  host {
    zone      = var.zone
    subnet_id = module.vpc.subnet_ids["data"]
  }
}

# База данных создаётся ОТДЕЛЬНЫМ ресурсом.
#
# ИСПРАВЛЕНО. В прежней версии курса база и пользователь описывались
# вложенными блоками внутри кластера (database {...}, user {...}).
# Такие блоки объявлены устаревшими: они мешают обновлять кластер
# и не позволяют менять базу, не трогая сам кластер. Современный
# подход — отдельные ресурсы.
resource "yandex_mdb_postgresql_database" "app" {
  count = var.create_database ? 1 : 0

  cluster_id = yandex_mdb_postgresql_cluster.db[0].id

  name  = var.db_name
  owner = var.db_user

  # Владелец должен существовать раньше базы.
  depends_on = [yandex_mdb_postgresql_user.app]
}

resource "yandex_mdb_postgresql_user" "app" {
  count = var.create_database ? 1 : 0

  cluster_id = yandex_mdb_postgresql_cluster.db[0].id

  name     = var.db_user
  password = var.db_password
}
