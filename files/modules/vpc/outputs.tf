# Выходные значения модуля.
#
# Модуль обязан отдать наружу всё, что может понадобиться снаружи:
# идентификаторы созданных ресурсов. Если этого не сделать, вызывающей
# конфигурации придётся угадывать идентификаторы или обращаться
# к источникам данных.

output "network_id" {
  description = "Идентификатор созданной сети"
  value       = yandex_vpc_network.this.id
}

output "subnet_ids" {
  description = "Идентификаторы подсетей: ключ — имя подсети"
  value       = { for name, subnet in yandex_vpc_subnet.this : name => subnet.id }
}

output "subnet_zones" {
  description = "Зоны подсетей: ключ — имя подсети"
  value       = { for name, subnet in yandex_vpc_subnet.this : name => subnet.zone }
}

output "security_group_id" {
  description = "Идентификатор группы безопасности"
  value       = yandex_vpc_security_group.this.id
}

output "subnet_count" {
  description = "Сколько подсетей создано"
  value       = length(yandex_vpc_subnet.this)
}

output "nat_gateway_id" {
  description = "Идентификатор NAT-шлюза (null, если шлюз не создавался)"
  value       = var.create_nat_gateway ? yandex_vpc_gateway.nat[0].id : null
}

output "route_table_id" {
  description = "Идентификатор таблицы маршрутизации (null, если не создавалась)"
  value       = var.create_nat_gateway ? yandex_vpc_route_table.nat[0].id : null
}
