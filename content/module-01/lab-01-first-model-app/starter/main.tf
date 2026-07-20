terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

provider "juju" {}

# TODO: Add a juju_model resource named "development"

# TODO: Add a juju_application resource that deploys the ubuntu charm
