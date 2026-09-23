# Выводы практики 7.

output "registry_id" {
  description = "Идентификатор реестра образов"
  value       = yandex_container_registry.this.id
}

output "registry_repository" {
  description = "Имя репозитория для docker push"
  value       = "${yandex_container_registry.this.id}/app"
}

output "push_commands" {
  description = "Как собрать и загрузить образ"
  value = {
    login = "yc container registry configure-docker"
    build = "docker build -t cr.yandex/${yandex_container_registry.this.id}/app:v1 ."
    push  = "docker push cr.yandex/${yandex_container_registry.this.id}/app:v1"
  }
}

output "cluster_id" {
  description = "Идентификатор кластера Kubernetes"
  value       = var.create_cluster ? yandex_kubernetes_cluster.this[0].id : null
}

output "cluster_external_endpoint" {
  description = "Адрес API-сервера кластера"
  value       = var.create_cluster ? yandex_kubernetes_cluster.this[0].master[0].external_v4_endpoint : null
}

output "cluster_commands" {
  description = "Как подключиться к кластеру и посмотреть узлы"
  value = var.create_cluster ? {
    kubeconfig = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.this[0].name} --external --force"
    nodes      = "kubectl get nodes -o wide"
    pods       = "kubectl get pods -A"
  } : null
}

output "node_group_size" {
  description = "Сколько узлов в группе"
  value       = var.create_cluster ? var.node_count : 0
}

output "function_id" {
  description = "Идентификатор функции"
  value       = var.create_serverless ? yandex_function.api[0].id : null
}

output "api_gateway_domain" {
  description = "Адрес шлюза API"
  value       = var.create_serverless ? "https://${yandex_api_gateway.api[0].domain}" : null
}

output "check_commands" {
  description = "Готовые команды для проверки"
  value = {
    invoke_function = var.create_serverless ? "yc serverless function invoke ${yandex_function.api[0].id}" : "функция не создавалась"
    call_gateway    = var.create_serverless ? "curl -s https://${yandex_api_gateway.api[0].domain}/" : "шлюз не создавался"
  }
}
