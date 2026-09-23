# Выводы.

output "vm_external_ip" {
  description = "Публичный адрес машины"
  value       = yandex_compute_instance.app.network_interface[0].nat_ip_address
}

output "vm_internal_ip" {
  description = "Внутренний адрес машины"
  value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "network_id" {
  description = "Идентификатор сети"
  value       = yandex_vpc_network.course.id
}

output "subnet_id" {
  description = "Идентификатор подсети"
  value       = yandex_vpc_subnet.app.id
}

# Вывод состояния в открытом виде. Полезно, чтобы увидеть своими глазами,
# что именно попадает в файл состояния. В рабочей среде такой вывод
# делать не нужно: в нём оказываются секреты.
output "state_file_hint" {
  description = "Подсказка: где посмотреть содержимое состояния"
  value       = "terraform state pull | head -50"
}
