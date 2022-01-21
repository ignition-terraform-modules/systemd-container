output "ignition" {
  description = "The contents of the ignition file."
  value = data.template_file.ignition.rendered
  sensitive = true
}