output "web_static_ip" {
  description = "Закреплённый публичный адрес веб-сервера"
  value       = yandex_vpc_address.web.external_ipv4_address[0].address
}

output "web_private_ip" {
  description = "Внутренний адрес веб-сервера"
  value       = yandex_compute_instance.web.network_interface[0].ip_address
}

output "web_zone" {
  description = "Зона веб-сервера"
  value       = yandex_compute_instance.web.zone
}

output "subnet_ids" {
  description = "Идентификаторы подсетей: ключ — имя подсети"
  value       = { for name, s in yandex_vpc_subnet.this : name => s.id }
}

output "zones_covered" {
  description = "Какие зоны покрыты подсетями"
  value       = keys(local.zone_to_subnet)
}

output "security_groups" {
  description = "Группы безопасности: имя — идентификатор"
  value = {
    web      = yandex_vpc_security_group.web.id
    internal = yandex_vpc_security_group.internal.id
    alb      = var.create_alb ? yandex_vpc_security_group.alb[0].id : null
  }
}

output "dns_zones" {
  description = "DNS-зоны: публичная и приватная"
  value = {
    public   = { id = yandex_dns_zone.public.id, zone = yandex_dns_zone.public.zone }
    internal = { id = yandex_dns_zone.internal.id, zone = yandex_dns_zone.internal.zone }
  }
}

output "dns_records" {
  description = "Записи, созданные в публичной зоне"
  value = {
    service = yandex_dns_recordset.service.name
    health  = yandex_dns_recordset.health.name
  }
}

output "internal_dns_name" {
  description = "Внутреннее имя машины (создаётся в приватной зоне)"
  value       = yandex_compute_instance.web.network_interface[0].dns_record[0].fqdn
}

output "alb_ip" {
  description = "Публичный адрес прикладного балансировщика"
  value       = local.alb_address
}

output "check_commands" {
  description = "Готовые команды для проверки"
  value = {
    via_static_ip = "curl -s http://${yandex_vpc_address.web.external_ipv4_address[0].address}/"

    # Проверка на null обязательна: пока балансировщик не создан,
    # адреса нет, а подставлять null в строку Terraform не разрешает:
    #
    #   Error: Invalid template interpolation value
    #   The expression result is null.
    #   Cannot include a null value in a string template.
    via_alb = local.alb_address == null ? (
      "балансировщик не создавался (или адрес ещё неизвестен)"
    ) : "curl -s http://${local.alb_address}/"

    dns_query = "yc dns zone list-records --id ${yandex_dns_zone.public.id}"
    sg_rules  = "yc vpc security-group list-rules ${yandex_vpc_security_group.web.id}"
  }
}
