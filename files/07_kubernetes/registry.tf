# Реестр образов Container Registry.
#
# Реестр — это место, откуда кластер Kubernetes забирает образы
# приложений. Реестр живёт в каталоге, внутри него — репозитории
# (по одному на приложение или на команду).
#
# Что стоит денег: хранение образов (за гигабайт в сутки).
# Поэтому реестру настраивают политику очистки: старые образы
# удаляются автоматически, иначе реестр растёт бесконечно.

resource "yandex_container_registry" "this" {
  name      = "${var.project_name}-registry"
  folder_id = var.folder_id

  labels = {
    course = "terraform"
    lesson = "7"
  }
}

# Репозиторий внутри реестра. Имя указывается в формате
# "<идентификатор реестра>/<имя репозитория>".
resource "yandex_container_repository" "app" {
  name = "${yandex_container_registry.this.id}/app"
}

# Политика очистки: держим только свежие образы.
#
# Правила читаются как «оставить N последних» и «удалять старше
# такого-то срока». Без политики каждый push добавляет слои,
# и через год хранения реестр становится заметной статьёй расходов.
#
# Поля правила (это важно — их часто придумывают):
#   retained_top   — сколько последних образов оставить;
#   expire_period  — через сколько удалять (например, "604800s" — неделя);
#   tag_regexp     — какие теги подпадают под правило;
#   untagged       — удалять ли образы без тегов (их обычно большинство).
resource "yandex_container_repository_lifecycle_policy" "app" {
  name          = "${var.project_name}-keep-last"
  repository_id = yandex_container_repository.app.id
  status        = "active"

  rule {
    description  = "Оставлять 5 последних образов с тегами"
    tag_regexp   = ".*"
    retained_top = 5
  }

  rule {
    description   = "Удалять образы без тегов старше недели"
    untagged      = true
    expire_period = "604800s"
  }
}
