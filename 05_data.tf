data "template_file" "es_config" {
  template = "${file("elasticsearch.yml.tpl")}"

  vars {
    cluster_name = "${var.project_name}"
  }
}

data "template_file" "jvm_opts" {
  template = "${file("jvm.options.tpl")}"
}
