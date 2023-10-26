 resource "yandex_compute_instance" "webserver" {
  name        = "test"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"


  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8pecdhv50nec1qf9im"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.foo.id}"
    # добавляем после шага 2
    security_group_ids = [yandex_vpc_security_group.my_webserver.id]
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("id_ed25519.pub")}"
    user_data = file("script.sh")
  }
}

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

  ingress {
    protocol       = "ANY"
    description    = "rule1 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 80
    to_port        = 80
  }
  ingress {
    protocol       = "ANY"
    description    = "rule1 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 443
    to_port        = 443
  }
  ingress {
    protocol       = "ANY"
    description    = "rule1 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 22
    to_port        = 22
  }

  egress {
    protocol       = "ANY"
    description    = "rule2 description"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 80
    to_port        = 80
  }
}

output "internal_ip_address_webserver" {
  value = yandex_compute_instance.webserver.network_interface.0.ip_address
}


output "external_ip_address_webserver" {
  value = yandex_compute_instance.webserver.network_interface.0.nat_ip_address
}