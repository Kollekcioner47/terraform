# Веб-сервер со статическим адресом и записью в DNS.
#
# Машина одна, но описана так, как описывают машины за балансировщиком:
# группа безопасности своя, адрес закреплён, имя в DNS есть.

data "yandex_compute_image" "os" {
  family = var.image_family
}

resource "yandex_compute_instance" "web" {
  name        = "${var.project_name}-web"
  description = "Веб-сервер со статическим адресом"

  # Зона машины должна совпадать с зоной подсети — иначе облако
  # откажет в создании (эту ошибку мы разбирали в практике 3).
  zone        = var.zone
  platform_id = "standard-v3"

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    # Подсеть той же зоны, что и машина.
    subnet_id = yandex_vpc_subnet.this["web-d"].id

    nat = true

    # Вот он, статический адрес: вместо автоматически выданного
    # используем закреплённый за нами.
    nat_ip_address = yandex_vpc_address.web.external_ipv4_address[0].address

    security_group_ids = [yandex_vpc_security_group.web.id]

    # Внутренняя запись DNS создаётся прямо здесь: облако заведёт
    # A-запись с внутренним адресом машины в ПРИВАТНОЙ зоне.
    #
    # С публичной зоной этот блок не работает — облако отвечает
    # «DNS Zone has no private_visibility»: внутренние адреса машины
    # в публичном DNS не публикуют. Публичные имена мы заводим
    # отдельными ресурсами yandex_dns_recordset (см. dns.tf).
    dns_record {
      fqdn        = "${var.project_name}-web.${yandex_dns_zone.internal.zone}"
      dns_zone_id = yandex_dns_zone.internal.id
      ttl         = 300

      # ptr = false обязателен для приватной зоны. Обратная запись
      # (PTR) для приватных зон в Яндекс Облаке не поддерживается:
      #
      #   Auto PTR records are currently not supported for private
      #   DNS Zones, but got a private-only DNS Zone
      ptr = false
    }
  }

  metadata = {
    ssh-keys  = "ubuntu:${file(var.ssh_public_key)}"
    user-data = file("${path.module}/cloud-init/web.yaml")
  }

  labels = {
    course = "terraform"
    lesson = "5"
    role   = "web"
  }
}
