locals {
  bucket_name = "website-tf-bucket"
  index = "index.html"
}

// Create SA
resource "yandex_iam_service_account" "sa" {
  folder_id = local.folder_id
  name      = "tf-test-sa"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = local.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Use keys to create bucket
resource "yandex_storage_bucket" "test" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = local.bucket_name
  acl = "public-read"
  website {
    index_document = local.index
  }
}

resource "yandex_storage_object" "index" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  acl = "public-read"
  bucket = yandex_storage_bucket.test.id
  key    = local.index
#  source = "site/${local.index}"
  content_base64 = base64encode(file("site/${local.index}"))
  tags = {
    test = "cats" 
  }
}

resource "yandex_storage_object" "img" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  acl = "public-read"
  bucket = yandex_storage_bucket.test.id
  key    = each.key
  source = "site/${each.key}"
  for_each = fileset("site","img/*")
  tags = {
    test = "cats"
  }
}

output "site_name" {
  value = yandex_storage_bucket.test.website_endpoint
  
}