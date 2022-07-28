terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


#provider "yandex" {
#  token     = "..........."
#  cloud_id  = "..........."
#  folder_id = "............"
#  zone      = "ru-central1-b"
#}

data "yandex_compute_image" "ubuntu_image" {
    family = "ubuntu-2004-lts"
}


resource "yandex_compute_instance" "vm-1" {
  name = "vm-1"
  hostname = "vm1"
  allow_stopping_for_update = true
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
  }


  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size = "10"
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    serial-port-enable = 1
    "user-data": "#cloud-config\nusers:\n  - name: test1\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC3nukNpc6iLzbaRsvMt+qp+rYpcc99yrd7/LrORKlXm0mWqqYKvL2n8fIZ3oR2mUg9CKlGH9ry/SrccU2mYTEMMiV1fBsNFuEAL2RmyupcLPmm3gX9ZRVSC0K1L9cdZ6IfYxaNR9Pfk73fdjGFz1oPdI8J1VwlA2V2NRx9HWroKTjkw7ul/xZhSkQG3N2wZdz7GogslC3U6vWwOmFuvxQZCFza+G6Vf7jFqFvbXhKHdD9yZFxJUsHB8U+9Ca8vcGfXB9HzNiY+wBS8pn+hMBTdbfhW+YVmDwOt6uKuFNiUyQNyhDoUf5OD8PjIstNWKas/ECoElzJtidQvUJDFamZ user1@PCwork"

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
}
output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}