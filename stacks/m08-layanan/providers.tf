provider "aws" {
  region = var.region

  default_tags {
    tags = {
      kursus        = "komputasi-awan"
      nim           = var.nim
      kelompok      = var.kelompok
      modul         = "m08"
      stack         = "m08-layanan"
      "managed-by"  = "opentofu"
      owner         = var.nim
      lingkungan    = "prod"
      "cost-center" = var.cost_center
      "data-class"  = var.data_class
    }
  }
}
