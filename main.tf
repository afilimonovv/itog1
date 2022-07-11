terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  token     = "..........."
  cloud_id  = "..........."
  folder_id = "............"
  zone      = "ru-central1-b"
}

data "yandex_compute_image" "ubuntu_image" {
    family = "ubuntu-2004-lts"
}


resource "yandex_compute_instance" "vm-1" {
  name = "terraform1"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }


  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    "user-data": "#cloud-config\nusers:\n  - name: test1\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n  - ssh-rsa .............
  }

  connection {
    type     = "ssh"
    user     = "test1"
    private_key = "${file("/Users/user1/.ssh/id_rsa")}"
    host     = self.network_interface.0.nat_ip_address
  }

}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
