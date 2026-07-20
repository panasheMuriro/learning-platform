terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

provider "juju" {}

resource "juju_model" "lifecycle" {
  name = "lab-03"
}

resource "juju_application" "ubuntu" {
  name       = "ubuntu"
  model_uuid = juju_model.lifecycle.uuid
  charm {
    name    = "ubuntu"
    channel = "latest/stable"
  }
  units = 1
}
