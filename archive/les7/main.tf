resource "yandex_vpc_network" "foo" {}

resource "yandex_vpc_subnet" "foo" {
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.foo.id}"
  v4_cidr_blocks = ["10.5.0.0/24"]
}
resource "yandex_vpc_security_group" "my_webserver" {
  name        = "My webserver group"
  description = "description for my security group"
  network_id  = "${yandex_vpc_network.foo.id}"

  labels = {
    my-label = "my-label-value"
  }
dynamic "ingress" {
    for_each = ["80","443","1541","9092"]
    content {
        protocol       = "TCP"
        v4_cidr_blocks = ["0.0.0.0/0"]
        from_port      = ingress.value
        to_port        = ingress.value
    }
}

  egress {
    protocol       = "ANY"
    description    = "rule2 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 80
    to_port        = 80
  }
}
