resource "azurerm_lb" "cluster_lb" {
  name                = "cluster_lb"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"

  frontend_ip_configuration {
    name      = "cluster_lb_ip"
    subnet_id = "${azurerm_subnet.workshop_subnet_primary.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "cluster_lb_backend" {
  name                = "cluster_lb_backend"
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
}

resource "azurerm_lb_probe" "cluster_probe" {
  resource_group_name = "${azurerm_resource_group.workshop_rg.name}"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
  name                = "cluster_probe"
  port                = 9200
  protocol            = "HTTP"
  request_path        = "/"
}

resource "azurerm_lb_rule" "cluster_rule" {
  resource_group_name            = "${azurerm_resource_group.workshop_rg.name}"
  loadbalancer_id                = "${azurerm_lb.cluster_lb.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 9200
  backend_port                   = 9200
  frontend_ip_configuration_name = "cluster_lb_ip"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.cluster_lb_backend.id}"
  probe_id                       = "${azurerm_lb_probe.cluster_probe.id}"
  depends_on                     = ["azurerm_lb_probe.cluster_probe"]
}
