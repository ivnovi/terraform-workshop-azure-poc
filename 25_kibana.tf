data "template_file" "kibana_config" {
  template = "${file("kibana.yml.tpl")}"

  vars {
    lb_host = "${azurerm_lb.cluster_lb.private_ip_address}"
  }
}

resource "azurerm_public_ip" "kibana_pip" {
  name                         = "kibana_pip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.workshop_rg.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "kibana_nic" {
  name                = "kibana_nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"

  ip_configuration {
    name                          = "iponfiguration"
    subnet_id                     = "${azurerm_subnet.workshop_subnet_primary.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.kibana_pip.id}"
  }
}

resource "azurerm_storage_account" "kibana_storage" {
  name                = "kibanasa"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "kibana_container" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.workshop_rg.name}"
  storage_account_name  = "${azurerm_storage_account.kibana_storage.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "kibana_vm" {
  name                  = "${var.project_name}-kibanavm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.workshop_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.kibana_nic.id}"]
  vm_size               = "Standard_A1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04.5-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.kibana_storage.primary_blob_endpoint}${azurerm_storage_container.kibana_container.name}/kibana_osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  # Optional data disks
  #   storage_data_disk {
  #     name          = "datadisk0"
  #     vhd_uri       = "${azurerm_storage_account.kibana_storage.primary_blob_endpoint}${azurerm_storage_container.kibana_container.name}/kibana1_datadisk0.vhd"
  #     disk_size_gb  = "1023"
  #     create_option = "Empty"
  #     lun           = 0
  #   }
  os_profile {
    computer_name  = "kibana"
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
    host        = "${azurerm_public_ip.kibana_pip.ip_address}"
    user        = "ubuntu"
    private_key = "${file("student.key")}"
  }

  provisioner "file" {
    content     = "${data.template_file.kibana_config.rendered}"
    destination = "/tmp/kibana.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get install apt-transport-https",
      "echo 'deb https://artifacts.elastic.co/packages/5.x/apt stable main' | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list",
      "sudo apt-get update && sudo apt-get install kibana",
      "sudo cp /tmp/kibana.yml /etc/kibana/kibana.yml",
      "sudo service kibana start",
    ]
  }
}
