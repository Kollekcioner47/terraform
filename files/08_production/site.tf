# Бакет для статического сайта: то, что в курсе называлось
# «статический сайт в Object Storage».
#
# В этой практике нас интересует не сам сайт, а то, как такие ресурсы
# переживают смену окружения: имя бакета включает окружение, иначе
# стенды dev и prod подерутся за одно и то же имя (имена бакетов
# уникальны во всём Object Storage).

resource "yandex_storage_bucket" "site" {
  bucket = var.site_bucket

  anonymous_access_flags {
    read = true
    list = true
  }

  versioning {
    enabled = true
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  force_destroy = true

  tags = local.common_labels
}

resource "yandex_storage_object" "index" {
  bucket = yandex_storage_bucket.site.id
  key    = "index.html"

  content_base64 = base64encode(templatefile(
    "${path.module}/site/index.html",
    { environment = var.environment }
  ))
  content_type = "text/html; charset=utf-8"
}
