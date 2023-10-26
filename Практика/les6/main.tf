resource "yandex_mdb_mongodb_cluster" "mymg" {
  name                = "mymg"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.mynet.id
  security_group_ids  = [ yandex_vpc_security_group.mymg-sg.id ]
  deletion_protection = true

  cluster_config {
    version = "6.0"
  }

  database {
    name = "db1"
  }

  user {
    name     = "user1"
    password = "user1user1"
    permission {
      database_name = "db1"
    }
  }

  resources_mongod {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone_id   = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.mysubnet.id
  }
}

resource "yandex_vpc_network" "mynet" {
  name = "mynet"
}

resource "yandex_vpc_security_group" "mymg-sg" {
  name       = "mymg-sg"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    description    = "MongoDB"
    port           = 27018
    protocol       = "TCP"
    v4_cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "yandex_vpc_subnet" "mysubnet" {
  name           = "mysubnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}