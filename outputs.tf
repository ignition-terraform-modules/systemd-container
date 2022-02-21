output "ignition" {
  description = "The contents of the ignition file."
  value = data.template_file.ignition.rendered
  sensitive = true
}

output "systemd_service_name" {
  description = "The name of the container systemd service file."
  value = "${var.name}.service"
}

output "systemd_service_file" {
  value = data.template_file.universal_service.rendered
}