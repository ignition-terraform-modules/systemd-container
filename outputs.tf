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
  value = data.template_file.systemd_service.rendered
}

output "systemd_oneshot_files" {
  value = [for s in data.template_file.systemd_oneshots : s.rendered]
}