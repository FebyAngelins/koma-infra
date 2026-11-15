provider "aws" {
  region = var.region

  default_tags {
    tags = {
      kursus       = "komputasi-awan"
      nim          = var.nim
      kelompok     = var.kelompok
      modul        = "m04"
      stack        = "m04-data"
      "managed-by" = "opentofu"
    }
  }
}
