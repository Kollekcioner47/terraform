# Serverless: функция и шлюз API.
#
# Зачем это в курсе про инфраструктуру: серверные решения описываются
# тем же Terraform и живут рядом с остальными ресурсами. Функция,
# шлюз API и база данных могут быть в одной конфигурации — и тогда
# «инфраструктура» и «приложение» перестают быть разными мирами.
#
# Что стоит денег: за саму функцию платят только за вызовы и время
# работы (миллисекунды). Для занятий это копейки — в отличие
# от кластера Kubernetes.

# Код функции лежит в Object Storage: провайдер принимает только
# ссылку на объект-архив, а не локальный файл. Поэтому сначала бакет.
resource "yandex_storage_bucket" "function_code" {
  count = var.create_serverless ? 1 : 0

  bucket = "${var.project_name}-functions"

  # Версионирование: если новый архив окажется неудачным,
  # предыдущий можно вернуть.
  versioning {
    enabled = true
  }

  force_destroy = true

  tags = {
    course = "terraform"
    lesson = "7"
  }
}

# Архив с кодом.
#
# user_hash у функции и source_hash у объекта — это одно и то же
# по смыслу: хэш содержимого. Без него Terraform не заметит, что код
# изменился, и функция останется старой (та же ловушка, что со
# страницей сайта в практике 6).
resource "yandex_storage_object" "function_code" {
  count = var.create_serverless ? 1 : 0

  bucket = yandex_storage_bucket.function_code[0].id
  key    = "function.zip"

  source       = "${path.module}/function/function.zip"
  source_hash  = filemd5("${path.module}/function/function.zip")
  content_type = "application/zip"
}

# Сервисный аккаунт функции: ей нужны права на то, что она делает.
# Наша функция только отвечает на запросы, но если бы она писала
# в Object Storage или читала секреты, роли были бы здесь.
resource "yandex_iam_service_account" "function" {
  count = var.create_serverless ? 1 : 0

  name        = "${var.project_name}-function-sa"
  description = "Сервисный аккаунт функции"
}

# Сервисный аккаунт ШЛЮЗА API — отдельный.
#
# Это не формальность: шлюз должен иметь право вызывать функцию.
# Без выданной роли шлюз отвечает ошибкой, которую легко принять
# за ошибку в коде функции:
#
#   {"message":"request to function '<id>' failed,
#    reason: Response code 403 (Forbidden)"}
#
# Мы получили её на живом стенде именно потому, что роли не было.
resource "yandex_iam_service_account" "gateway" {
  count = var.create_serverless ? 1 : 0

  name        = "${var.project_name}-gateway-sa"
  description = "Сервисный аккаунт шлюза API"
}

resource "yandex_resourcemanager_folder_iam_member" "gateway_invoker" {
  count = var.create_serverless ? 1 : 0

  folder_id = var.folder_id

  # Имя роли — functions.functionInvoker. Написание functions.invoker
  # («как логично») облако не принимает:
  #
  #   Role 'functions.invoker' not found
  #
  # Точные идентификаторы ролей всегда смотрим в документации
  # сервиса: у них свой стиль именования, и догадаться не получится.
  role   = "functions.functionInvoker"
  member = "serviceAccount:${yandex_iam_service_account.gateway[0].id}"
}

resource "yandex_function" "api" {
  count = var.create_serverless ? 1 : 0

  name        = "${var.project_name}-function"
  description = "Учебная функция курса Terraform"
  user_hash   = filemd5("${path.module}/function/function.zip")

  runtime    = var.function_runtime
  entrypoint = "index.handler"
  memory     = var.function_memory

  execution_timeout = "10"

  # Переменные окружения функции: то же, что env в контейнере.
  environment = {
    COURSE = "terraform"
    LESSON = "7"
  }

  service_account_id = yandex_iam_service_account.function[0].id

  package {
    bucket_name = yandex_storage_bucket.function_code[0].bucket
    object_name = yandex_storage_object.function_code[0].key
  }

  labels = {
    course = "terraform"
    lesson = "7"
  }
}

# Шлюз API: публичный HTTPS-адрес перед функцией.
#
# Описание — это спецификация в формате OpenAPI. Минимум, который
# нужен: путь, метод и ссылка на функцию, которую надо вызвать.
# Здесь же описывают авторизацию, ограничения по IP и кэширование.
resource "yandex_api_gateway" "api" {
  count = var.create_serverless ? 1 : 0

  name        = "${var.project_name}-gateway"
  description = "Шлюз API перед функцией"

  # От чьего имени шлюз вызывает функцию.
  #
  # ВАЖНО: у ресурса yandex_api_gateway НЕТ аргумента
  # service_account_id — авторизация описывается ВНУТРИ спецификации,
  # в параметре service_account_id интеграции:
  #
  #   Error: Unsupported argument
  #   An argument named "service_account_id" is not expected here.
  #
  # Такую ошибку мы получили на живом стенде, пытаясь вынести
  # сервисный аккаунт на верхний уровень. Если этого параметра нет
  # вовсе, шлюз обращается к функции анонимно и получает 403:
  #
  #   {"message":"request to function '<id>' failed,
  #    reason: Response code 403 (Forbidden)"}
  spec = <<-EOT
    openapi: 3.0.0
    info:
      title: Учебный шлюз API
      version: 1.0.0
    paths:
      /:
        get:
          summary: Приветствие от функции
          x-yc-apigateway-integration:
            type: cloud_functions
            function_id: ${yandex_function.api[0].id}
            tag: $latest
            service_account_id: ${yandex_iam_service_account.gateway[0].id}
          responses:
            '200':
              description: Успешный ответ функции
  EOT

  labels = {
    course = "terraform"
    lesson = "7"
  }
}
