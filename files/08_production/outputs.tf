output "environment" {
  description = "Окружение, для которого собран стенд"
  value       = var.environment
}

output "app_external_ip" {
  description = "Публичный адрес приложения"
  value       = var.create_app ? yandex_compute_instance.app[0].network_interface[0].nat_ip_address : null
}

output "app_check_command" {
  description = "Команда проверки приложения"
  value = var.create_app ? (
    "curl -s http://${yandex_compute_instance.app[0].network_interface[0].nat_ip_address}/"
  ) : "машина приложения не создавалась"
}

output "site_endpoint" {
  description = "Адрес статического сайта"
  value       = yandex_storage_bucket.site.website_endpoint
}

output "network_id" {
  description = "Идентификатор сети"
  value       = module.vpc.network_id
}

output "security_group_id" {
  description = "Идентификатор группы безопасности"
  value       = module.vpc.security_group_id
}

output "summary" {
  description = "Сводка по стенду — удобно сравнивать окружения"
  value = {
    environment = var.environment
    name_prefix = local.name_prefix
    app_cores   = local.app_cores
    app_memory  = local.app_memory
    preemptible = var.preemptible
    create_app  = var.create_app
    site_bucket = var.site_bucket
    subnets     = keys(module.vpc.subnet_ids)
  }
}
