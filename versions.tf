terraform {
  # Optional attributes and the defaults function are
  # both experimental, so we must opt in to the experiment.
  # https://www.terraform.io/language/functions/defaults
  experiments = [module_variable_optional_attrs]

  # https://github.com/hashicorp/terraform/releases
  required_version = "~> 1.1.5"
}