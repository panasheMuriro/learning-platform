terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

provider "juju" {}

# TODO: Create a juju_model resource using var.model_name

# TODO: Create a juju_application resource using the variables
