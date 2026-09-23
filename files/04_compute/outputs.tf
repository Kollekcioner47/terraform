output "web_vm_external_ip" {
  description = "Публичный адрес веб-сервера"
  value       = yandex_compute_instance.web.network_interface[0].nat_ip_address
}

output "web_vm_fqdn" {
  description = "Внутреннее доменное имя веб-сервера"
  value       = yandex_compute_instance.web.fqdn
}

output "web_page_command" {
  description = "Команда для проверки страницы, отданной cloud-init"
  value       = "curl -s http://${yandex_compute_instance.web.network_interface[0].nat_ip_address}/"
}

output "data_disk_id" {
  description = "Идентификатор дополнительного диска"
  value       = yandex_compute_disk.data.id
}

output "snapshot_id" {
  description = "Идентификатор снимка диска"
  value       = var.create_snapshot ? yandex_compute_snapshot.data[0].id : null
}

output "instance_group_size" {
  description = "Сколько машин сейчас в группе"
  value       = length(yandex_compute_instance_group.web.instances)
}

output "instance_group_ips" {
  description = "Внутренние адреса машин группы"
  value = [
    for vm in yandex_compute_instance_group.web.instances :
    vm.network_interface[0].ip_address
  ]
}

output "load_balancer_ip" {
  description = "Публичный адрес балансировщика"
  value       = local.load_balancer_address
}

output "load_balancer_check_command" {
  description = "Команда проверки балансировщика: четыре запроса подряд"
  value = local.load_balancer_address == null ? null : (
    "for i in 1 2 3 4; do curl -s http://${local.load_balancer_address}/ | grep -o 'Имя машины: [^<]*'; done"
  )
}
