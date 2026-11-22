# Stack m07-integrasi: satu kode untuk dev dan prod. Yang berbeda antar lingkungan hanya
# env/<lingkungan>.tfvars dan state-nya (env/<lingkungan>.backend.hcl). Ikuti naskah.

# A.5 Stack memanggil modul: nilai lingkungan datang dari env/<lingkungan>.tfvars
module "jalur" {
  source = "../../modules/antrean-arsip"

  awalan       = "koma-${var.nim}-m07-${var.lingkungan}"
  lingkungan   = var.lingkungan
  ukuran       = var.ukuran
  retensi_hari = var.retensi_hari
  dengan_dlq   = var.dengan_dlq
  versi        = var.versi
}

# C.2 Showback dan anggaran per pusat biaya (G1, G3). Saringan tag baru menghitung biaya setelah
# tag cost-center diaktifkan sebagai cost allocation tag di Billing; budget tetap dapat dibuat.
resource "aws_budgets_budget" "lingkungan" {
  name         = "koma-${var.nim}-m07-${var.lingkungan}"
  budget_type  = "COST"
  limit_amount = format("%.1f", var.anggaran_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:cost-center$%s", var.cost_center)]
  }
}

# C.3 Lapis 2 (kode, peringatan): plan tetap jalan, tetapi peringatannya tercetak di setiap plan.
check "prod_tangguh" {
  assert {
    condition     = var.lingkungan != "prod" || (var.dengan_dlq && var.ukuran == "sedang")
    error_message = "Prod semestinya memakai DLQ dan ukuran sedang (G4, O1)."
  }
}
