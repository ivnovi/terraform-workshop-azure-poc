variable "node_count" {
  default = "2"
}

resource "azurerm_availability_set" "cluster_availability_set" {
  name                = "cluster_availability_set"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
}

resource "azurerm_public_ip" "cluster_node_pip" {
  count                        = "${var.node_count}"
  name                         = "cluster_node_pip_${count.index + 1}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.workshop_rg.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "cluster_node_nic" {
  count               = "${var.node_count}"
  name                = "cluster_node_nic_${format("%02d", count.index + 1)}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"

  ip_configuration {
    name                                    = "ipconfig"
    subnet_id                               = "${azurerm_subnet.workshop_subnet_primary.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.cluster_node_pip.*.id[count.index]}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.cluster_lb_backend.id}"]
  }
}

resource "azurerm_storage_account" "cluster_node_storage" {
  count               = "${var.node_count}"
  name                = "elastic1sa${format("%02d", count.index + 1)}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "storage_container" {
  count                 = "${var.node_count}"
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.workshop_rg.name}"
  storage_account_name  = "${azurerm_storage_account.cluster_node_storage.*.name[count.index]}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "cluster_node" {
  count                 = "${var.node_count}"
  name                  = "elastic1vm-${format("%02d", count.index + 1)}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.workshop_rg.name}"
  availability_set_id   = "${azurerm_availability_set.cluster_availability_set.id}"
  network_interface_ids = ["${element(azurerm_network_interface.cluster_node_nic.*.id, count.index)}"]
  vm_size               = "Standard_A1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.cluster_node_storage.*.primary_blob_endpoint[count.index]}${azurerm_storage_container.storage_container.*.name[count.index]}/elastic1_osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }
  # Optional data disks
  storage_data_disk {
    name          = "datadisk0"
    vhd_uri       = "${azurerm_storage_account.cluster_node_storage.*.primary_blob_endpoint[count.index]}${azurerm_storage_container.storage_container.*.name[count.index]}/elastic1_datadisk0.vhd"
    disk_size_gb  = "1023"
    create_option = "Empty"
    lun           = 0
  }
  os_profile {
    computer_name  = "elastic1"
    admin_username = "ubuntu"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys = [{
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${file("student.key.pub")}"
    }]
  }
  connection {
    type        = "ssh"
    host        = "${azurerm_public_ip.cluster_node_pip.*.ip_address[count.index]}"
    user        = "ubuntu"
    private_key = "${file("student.key")}"
  }
  provisioner "file" {
    content     = "${data.template_file.es_config.rendered}"
    destination = "/tmp/elasticsearch.yml"
  }
  provisioner "file" {
    content     = "${data.template_file.jvm_opts.rendered}"
    destination = "/tmp/jvm.options"
  }
  provisioner "remote-exec" {
    inline = [
      "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
      "sudo apt-get install -y python-software-properties debconf-utils",
      "sudo add-apt-repository -y ppa:webupd8team/java",
      "sudo apt-get update",
      "sudo apt-get -y install apt-transport-https",
      "sudo echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections",
      "sudo apt-get -y install oracle-java8-installer",
      "echo 'deb https://artifacts.elastic.co/packages/5.x/apt stable main' | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list",
      "sudo apt-get update && sudo apt-get install elasticsearch",
      "sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-file",
      "sudo cp /tmp/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml",
      "sudo cp /tmp/jvm.options /etc/elasticsearch/jvm.options",
      "sudo service elasticsearch start",
    ]
  }
}


