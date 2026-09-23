# Выводы практики 6.
#
# Обратите внимание: адрес сайта — это обычный публичный адрес бакета,
# по которому отдаётся статика. Работает он по HTTP: чтобы отдавать
# сайт по HTTPS, перед бакетом ставят CDN или прикладной балансировщик.

output "website_endpoint" {
  description = "Адрес статического сайта"
  value       = yandex_storage_bucket.site.website_endpoint
}

output "bucket_name" {
  description = "Имя бакета"
  value       = yandex_storage_bucket.site.bucket
}

output "bucket_domain" {
  description = "Доменное имя бакета"
  value       = yandex_storage_bucket.site.bucket_domain_name
}

output "kms_key_id" {
  description = "Идентификатор ключа шифрования данных"
  value       = yandex_kms_symmetric_key.data.id
}

output "secret_id" {
  description = "Идентификатор секрета в Lockbox"
  value       = var.create_secret ? yandex_lockbox_secret.db[0].id : null
}

# Вывод с содержимым секрета помечен как чувствительный: в терминале
# вместо значения будет <sensitive>. В состоянии значение лежит
# открытым текстом — об этом в тексте практики.
output "db_password_sensitive" {
  description = "Пароль базы данных (скрыт в выводе команд)"
  value       = var.db_password
  sensitive   = true
}

output "db_connection_hint" {
  description = "Как выглядит строка подключения (пароль подставьте сами)"
  value = var.create_database ? format(
    "postgresql://%s:<пароль>@%s:6432/%s?sslmode=require",
    var.db_user,
    yandex_mdb_postgresql_cluster.db[0].host[0].fqdn,
    var.db_name,
  ) : "база не создавалась"
}

output "db_host" {
  description = "Имя хоста базы данных"
  value       = var.create_database ? yandex_mdb_postgresql_cluster.db[0].host[0].fqdn : null
}

output "check_commands" {
  description = "Готовые команды для проверки"
  value = {
    open_site          = "curl -s ${yandex_storage_bucket.site.website_endpoint}/"
    list_objects       = "yc storage s3api list-objects --bucket ${yandex_storage_bucket.site.bucket}"
    secret_versions    = var.create_secret ? "yc lockbox secret list-versions --id ${yandex_lockbox_secret.db[0].id}" : "секрет не создавался"
    state_secret_check = "terraform state pull | grep -i db_password"
  }
}
