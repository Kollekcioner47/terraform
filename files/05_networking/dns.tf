# DNS в облаке: две зоны, и это не случайность.
#
#   ПУБЛИЧНАЯ зона (public = true) отвечает на запросы из интернета.
#   Чтобы она действительно работала, домен нужно делегировать
#   облаку: у регистратора прописать NS-серверы зоны. Пока делегации
#   нет, зона существует, но интернет про неё не знает.
#
#   ПРИВАТНАЯ зона (public = false) видна только машинам указанных
#   сетей. Так решают внутренние имена сервисов, не выходя в интернет.
#
# Важное следствие, на котором легко споткнуться: блок dns_record
# в сетевом интерфейсе машины работает ТОЛЬКО с приватной зоной.
# Попытка указать публичную заканчивается ошибкой:
#
#   Error: ... primary_v4_address_spec.dns_record_specs[0].dns_zone_id:
#   DNS Zone (dns88v0...) has no private_visibility
#
# Логика понятна: запись создаётся для внутреннего адреса машины,
# а внутренние адреса в публичном DNS не публикуют.

# Публичная зона: внешние имена сервисов.
resource "yandex_dns_zone" "public" {
  name        = "${var.project_name}-public-zone"
  description = "Публичная зона для внешних имён"
  zone        = var.dns_zone
  public      = true

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

# Приватная зона: внутренние имена машин.
resource "yandex_dns_zone" "internal" {
  name        = "${var.project_name}-internal-zone"
  description = "Внутренняя зона для имён машин"
  zone        = "${var.project_name}.internal."
  public      = false

  # Зона видна только машинам этой сети.
  private_networks = [yandex_vpc_network.this.id]

  labels = {
    course = "terraform"
    lesson = "5"
  }
}

# Публичная запись: имя сервиса указывает на закреплённый адрес.
#
# Запись создаётся ОТДЕЛЬНЫМ ресурсом, потому что адрес берётся
# не у машины, а у статического адреса. Такую запись можно направить
# на балансировщик, на несколько адресов сразу или на внешний сервис.
resource "yandex_dns_recordset" "service" {
  zone_id = yandex_dns_zone.public.id
  name    = "service.${var.dns_zone}"
  type    = "A"
  ttl     = 300

  data = [yandex_vpc_address.web.external_ipv4_address[0].address]
}

# Текстовая запись: удобна для проверки, что зона отвечает.
resource "yandex_dns_recordset" "health" {
  zone_id = yandex_dns_zone.public.id
  name    = "health.${var.dns_zone}"
  type    = "TXT"
  ttl     = 60

  data = ["ok:created-by-terraform"]
}
