# Выходные значения.
#
# Приёмы, которые стоит запомнить:
#   * вывод коллекции целиком (словарь адресов всех машин);
#   * вывод с sensitive = true — значение скрывается в терминале;
#   * вывод в JSON — удобно забирать скриптами и конвейером.

output "instances" {
  description = "Машины ролей: ключ — роль, значение — адреса"
  value = {
    for role, vm in yandex_compute_instance.app :
    role => {
      name        = vm.name
      zone        = vm.zone
      external_ip = vm.network_interface[0].nat_ip_address
      internal_ip = vm.network_interface[0].ip_address
    }
  }
}

output "workers" {
  description = "Машины-исполнители, созданные через count"
  value = [
    for vm in yandex_compute_instance.worker : {
      name        = vm.name
      external_ip = vm.network_interface[0].nat_ip_address
    }
  ]
}

output "subnet_ids" {
  description = "Идентификаторы подсетей из модуля vpc"
  value       = module.vpc.subnet_ids
}

output "subnet_count" {
  description = "Сколько подсетей создал модуль"
  value       = module.vpc.subnet_count
}

output "summary" {
  description = "Сводка по стенду из locals"
  value       = local.summary
}

output "monitoring_cidr" {
  description = "Диапазон, вычисленный функцией cidrsubnet"
  value       = local.monitoring_cidr
}

# Чувствительный вывод. В терминале вместо значения будет
# (sensitive value), в файле состояния значение лежит открытым текстом.
output "db_password" {
  description = "Пароль базы данных (скрыт в выводе команд)"
  value       = var.db_password
  sensitive   = true
}

# Вывод в формате JSON: одна строка, которую удобно разобрать
# скриптом или передать в другой инструмент.
output "inventory_json" {
  description = "Инвентарь стенда в формате JSON"
  value = jsonencode({
    environment = var.environment
    instances = {
      for role, vm in yandex_compute_instance.app :
      role => vm.network_interface[0].ip_address
    }
    workers = [for vm in yandex_compute_instance.worker : vm.network_interface[0].ip_address]
  })
}
