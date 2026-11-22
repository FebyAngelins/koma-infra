# Lingkungan prod (G1, G2, G4, H4 kasus kelompok). Di-commit: pipeline memakai berkas yang sama.
# KSL: jalur ini membawa event hasil lab (H3), ditanggung Laboratorium (G1 CC-120); isinya data
# pasien ter-pseudonim yang tetap berlabel rahasia (A1).
lingkungan   = "prod"
cost_center  = "CC-120"
data_class   = "rahasia"
ukuran       = "sedang"
retensi_hari = 7
dengan_dlq   = true
anggaran_usd = 5
