output "node_ips" {
  value = "${azurerm_public_ip.cluster_node_pip.*.ip_address}"
}

output "node_private_ip" {
  value = "${azurerm_network_interface.cluster_node_nic.*.private_ip_address}"
}

output "kibana_node_ip" {
  value = "${azurerm_public_ip.kibana_pip.ip_address}"
}

output "cluster_lb_ip" {
  value = "${azurerm_lb.cluster_lb.private_ip_address}"
}
