data "template_file" "unicast_config" {
  template = "${file("unicast_hosts.txt.tpl")}"

  vars {
    master_ip = "${azurerm_network_interface.cluster_node_nic.0.private_ip_address}"
  }
}

resource "local_file" "unicast_config" {
  content  = "${data.template_file.unicast_config.rendered}"
  filename = "unicast_hosts.txt"
}

resource "null_resource" "copy_cluster_config" {
  count = "${var.node_count}"

  provisioner "local-exec" {
    command = "scp -i student.key -o StrictHostKeyChecking=no unicast_hosts.txt ubuntu@${azurerm_public_ip.cluster_node_pip.*.ip_address[count.index]}:/tmp"
  }

  provisioner "local-exec" {
    command = "ssh -i student.key -o StrictHostKeyChecking=no ubuntu@${azurerm_public_ip.cluster_node_pip.*.ip_address[count.index]} sudo cp /tmp/unicast_hosts.txt /etc/elasticsearch"
  }

  provisioner "local-exec" {
    command = "ssh -i student.key -o StrictHostKeyChecking=no ubuntu@${azurerm_public_ip.cluster_node_pip.*.ip_address[count.index]} sudo service elasticsearch restart"
  }

  depends_on = ["azurerm_virtual_machine.cluster_node"]
}
