# Локальные значения практики 4.

locals {
  # Публичный адрес балансировщика.
  #
  # Почему так сложно: блоки listener и external_address_spec в схеме
  # провайдера объявлены как МНОЖЕСТВА (set), а элементы множества
  # адресуются не по индексу. Запись вида listener[0] приводит к ошибке:
  #
  #   Error: Cannot index a set value
  #   Block type "listener" is represented by a set of objects, and set
  #   elements do not have addressable keys.
  #
  # Поэтому адрес достаётся выражением for, а функция one() берёт
  # единственный элемент: если элементов не один, она вернёт ошибку —
  # и это полезно, потому что молча взять «первый попавшийся» здесь
  # как раз опаснее всего.
  #
  # Запомните этот приём: он нужен и для других ресурсов провайдера,
  # где вложенные блоки объявлены множествами.
  load_balancer_address = var.create_load_balancer ? one([
    for listener in yandex_lb_network_load_balancer.web[0].listener :
    one(listener.external_address_spec).address
  ]) : null
}
