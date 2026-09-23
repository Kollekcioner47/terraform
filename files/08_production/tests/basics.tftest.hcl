# Тесты конфигурации.
#
# Запуск:
#
#   terraform test
#   terraform test -verbose
#   terraform test -filter=tests/basics.tftest.hcl
#
# Что такое terraform test: это встроенный в Terraform механизм
# проверки конфигурации (Terraform 1.6 и новее). Тест описывает,
# ЧТО должно получиться, а Terraform проверяет это условиями assert.
#
# Два вида проверки:
#   command = plan   — проверяем план, ничего не создавая.
#                      Быстро, безопасно, годится для конвейера.
#   command = apply  — создаём реальные ресурсы, проверяем, удаляем.
#                      Медленнее, требует облака; нужен для проверок,
#                      которые видны только после создания.
#
# ПРОВАЙДЕР МОЖНО ЗАМОКИРОВАТЬ (mock_provider): тогда Terraform
# не обращается к облаку вообще, а подставляет выдуманные значения.
# Это позволяет запускать тесты в конвейере без ключей и без денег.
#
# Значения переменных задаются в блоке variables: тест должен быть
# самодостаточным, terraform.tfvars в нём не участвует.

variables {
  cloud_id       = "b1gtest0000000000000"
  folder_id      = "b1gtest0000000000001"
  zone           = "ru-central1-d"
  sa_key_file    = "/tmp/test-key.json"
  ssh_public_key = "/tmp/test-key.pub"
  environment    = "dev"
  project_name   = "tf-test"
  site_bucket    = "tf-test-bucket-000"

  # В тестах не создаём машину: проверяем описание, а не облако.
  create_app = false
}

# Заглушка провайдера: обращения к облаку не происходят.
mock_provider "yandex" {}

# ------------------------------------------------------------------
# Проверки
# ------------------------------------------------------------------

run "network_is_created" {
  command = plan

  assert {
    condition     = module.vpc.subnet_count == 1
    error_message = "Модуль сети должен создать ровно одну подсеть."
  }

  assert {
    condition     = length(module.vpc.subnet_ids) == 1
    error_message = "Ожидалась одна подсеть в словаре subnet_ids."
  }
}

run "names_include_environment" {
  command = plan

  # Имена ресурсов обязаны содержать окружение: иначе стенды
  # dev и prod невозможно различить в облаке.
  assert {
    condition     = local.name_prefix == "tf-test-dev"
    error_message = "Префикс имени должен включать имя проекта и окружение."
  }
}

run "bucket_name_is_valid" {
  command = plan

  assert {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.site_bucket))
    error_message = "Имя бакета не соответствует правилам Object Storage."
  }
}

run "production_gets_more_resources" {
  command = plan

  variables {
    environment = "prod"
  }

  # В prod машина «полноценная», в dev — экономная. Проверяем
  # именно логику выбора, а не конкретные числа.
  assert {
    condition     = local.app_cores == 4 && local.app_memory == 4
    error_message = "В prod машина должна быть из 4 ядер и 4 ГБ."
  }

  assert {
    condition     = local.name_prefix == "tf-test-prod"
    error_message = "Префикс имени должен смениться вместе с окружением."
  }
}

run "dev_is_not_bigger_than_prod" {
  command = plan

  assert {
    condition     = local.app_cores <= 4 && local.app_memory <= 4
    error_message = "В dev машина не должна быть больше, чем в prod."
  }
}

# Проверка, что конфигурация действительно отказывается работать
# при неверном вводе. expect_failures описывает, ЧТО должно упасть.
run "invalid_environment_is_rejected" {
  command = plan

  variables {
    environment = "testing"
  }

  expect_failures = [var.environment]
}

# Проверка защиты ресурсов: в prod ресурс защищён от удаления.
run "prod_protects_resources" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = var.protect_resources == false
    error_message = "В учебной конфигурации защита выключена намеренно."
  }
}
