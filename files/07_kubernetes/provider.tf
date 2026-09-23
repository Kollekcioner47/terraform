provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  service_account_key_file = var.sa_key_file

  # Ключи для Object Storage: в этой практике в бакет загружается
  # архив с кодом функции (см. serverless.tf).
  storage_access_key = var.storage_access_key
  storage_secret_key = var.storage_secret_key
}
