# Выводы.
#
# Выводы — это то, ради чего вообще запускают apply: адреса, идентификаторы,
# имена, которые нужны дальше. Их видно в конце apply и в любой момент
# командой terraform output.

output "vm_external_ip" {
  description = "Публичный адрес виртуальной машины для подключения по SSH"
  value       = yandex_compute_instance.app.network_interface[0].nat_ip_address
}

output "vm_internal_ip" {
  description = "Внутренний адрес виртуальной машины в подсети"
  value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "vm_fqdn" {
  description = "Внутреннее доменное имя машины"
  value       = yandex_compute_instance.app.fqdn
}

output "network_id" {
  description = "Идентификатор созданной сети"
  value       = yandex_vpc_network.course.id
}

output "image_id" {
  description = "Идентификатор образа, который выбрал Terraform по семейству"
  value       = data.yandex_compute_image.os.id
}

output "ssh_command" {
  description = "Готовая команда для подключения к машине"
  value       = "ssh ubuntu@${yandex_compute_instance.app.network_interface[0].nat_ip_address}"
}
