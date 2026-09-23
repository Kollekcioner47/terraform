# Локальные значения практики 5.

locals {
  # Адрес прикладного балансировщика.
  #
  # Достать его непросто: listener — список, внутри endpoint — список,
  # внутри address — список, и только внутри него external_ipv4_address
  # с самим адресом. Вложенность объясняется тем, что слушателей,
  # точек входа и адресов может быть несколько.
  #
  # Вторая сложность: пока балансировщик ещё не создан, адреса нет
  # вовсе, и обращение по индексу [0] к пустому списку даёт ошибку:
  #
  #   Error: Invalid index
  #   The given key does not identify an element in this collection value:
  #   the collection has no elements.
  #
  # Поэтому выражение обёрнуто в try(): если вычислить не удалось,
  # вывод равен null, а не ошибке. Так план проходит и до создания
  # балансировщика, и после него.
  alb_address = var.create_alb ? try(
    one([
      for endpoint in yandex_alb_load_balancer.web[0].listener[0].endpoint :
      one(endpoint.address).external_ipv4_address[0].address
    ]),
    null
  ) : null

  # Что открыто наружу на веб-серверах — для вывода и для проверок.
  public_ports = sort(var.web_ports)

  # Карта «зона -> имя подсети»: помогает понять, какие зоны покрыты.
  zone_to_subnet = { for name, s in var.subnets : s.zone => name }
}
