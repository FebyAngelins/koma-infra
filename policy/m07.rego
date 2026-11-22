# Kebijakan Modul 07: gerbang tata kelola atas plan stack m07-integrasi (G4, H6).
# Dijalankan pipeline sebelum apply, dan secara lokal:
#   tofu show -json dev.tfplan > dev.plan.json
#   conftest test dev.plan.json --policy ../../policy --namespace m07
# Paket m07 terpisah dari paket main (m05.rego) agar kebijakan Modul 05 tidak ikut menilai
# plan Modul 07 dan sebaliknya.
package m07

import rego.v1

label_wajib := {"owner", "lingkungan", "cost-center", "data-class"}

kelas_data := {"publik", "internal", "rahasia"}

lingkungan_sah := {"dev", "prod"}

# Resource yang ada sesudah plan (bukan yang dihapus).
diubah contains rc if {
	some rc in input.resource_changes
	rc.change.after != null
}

bertag contains rc if {
	some rc in diubah
	is_object(rc.change.after.tags_all)
}

tag(rc, k) := rc.change.after.tags_all[k]

# ---------------------------------------------------------------- aturan 1 (starter)
# Setiap resource bertag membawa label G4 yang lengkap dan sah.

deny contains msg if {
	some rc in bertag
	some k in label_wajib
	not rc.change.after.tags_all[k]
	msg := sprintf("%s: label %s tidak ada", [rc.address, k])
}

deny contains msg if {
	some rc in bertag
	not regex.match(`^CC-[0-9]{3}$`, tag(rc, "cost-center"))
	msg := sprintf("%s: cost-center %q tidak berbentuk CC-123", [rc.address, tag(rc, "cost-center")])
}

deny contains msg if {
	some rc in bertag
	not tag(rc, "data-class") in kelas_data
	msg := sprintf("%s: data-class %q tidak dikenal", [rc.address, tag(rc, "data-class")])
}

deny contains msg if {
	some rc in bertag
	not tag(rc, "lingkungan") in lingkungan_sah
	msg := sprintf("%s: lingkungan %q tidak dikenal", [rc.address, tag(rc, "lingkungan")])
}

deny contains msg if {
	some rc in bertag
	tag(rc, "owner") != tag(rc, "nim")
	msg := sprintf("%s: owner %q bukan NIM pemilik %q", [rc.address, tag(rc, "owner"), tag(rc, "nim")])
}

# ---------------------------------------------------------------- aturan 2 (starter)
# Data rahasia hanya boleh berada di prod.

deny contains msg if {
	some rc in bertag
	tag(rc, "data-class") == "rahasia"
	tag(rc, "lingkungan") != "prod"
	msg := sprintf("%s: data rahasia di lingkungan %s", [rc.address, tag(rc, "lingkungan")])
}

# ---------------------------------------------------------------- aturan 3
# Antrean pesanan prod wajib disertai dead-letter queue (-gagal) di plan yang sama.
# redrive_policy tidak dapat dipakai: atribut itu optional+computed, sehingga tanpa DLQ pun
# plan mencatatnya "known after apply" (after_unknown), sama seperti bila DLQ ada.
antrean(rc, akhiran) if {
	rc.type == "aws_sqs_queue"
	endswith(rc.change.after.name, akhiran)
}

ada_dlq_prod if {
	some rc in bertag
	antrean(rc, "-gagal")
	tag(rc, "lingkungan") == "prod"
}

deny contains msg if {
	some rc in bertag
	antrean(rc, "-antrean")
	tag(rc, "lingkungan") == "prod"
	not ada_dlq_prod
	msg := sprintf("%s: antrean prod tanpa dead-letter queue (-gagal)", [rc.address])
}

# ---------------------------------------------------------------- aturan 4
# Batas ukuran fungsi: prod tidak boleh ukuran kecil (G4); tidak ada fungsi yang boros.

deny contains msg if {
	some rc in bertag
	rc.type == "aws_lambda_function"
	tag(rc, "lingkungan") == "prod"
	rc.change.after.memory_size < 256
	msg := sprintf("%s: fungsi prod %d MB, minimal 256 MB", [rc.address, rc.change.after.memory_size])
}

deny contains msg if {
	some rc in diubah
	rc.type == "aws_lambda_function"
	rc.change.after.memory_size > 512
	msg := sprintf("%s: memori %d MB melebihi 512 MB", [rc.address, rc.change.after.memory_size])
}

deny contains msg if {
	some rc in diubah
	rc.type == "aws_lambda_function"
	rc.change.after.timeout > 30
	msg := sprintf("%s: timeout %d detik melebihi 30 detik", [rc.address, rc.change.after.timeout])
}

# ---------------------------------------------------------------- aturan 5
# Kebijakan IAM inline tanpa aksi wildcard ("*" atau "layanan:*"), seperti Modul 05.

aksi(s) := [s.Action] if is_string(s.Action)

aksi(s) := s.Action if is_array(s.Action)

wildcard(a) if a == "*"

wildcard(a) if endswith(a, ":*")

deny contains msg if {
	some rc in diubah
	rc.type in {"aws_iam_role_policy", "aws_iam_policy"}
	is_string(rc.change.after.policy)
	some s in json.unmarshal(rc.change.after.policy).Statement
	s.Effect == "Allow"
	some a in aksi(s)
	wildcard(a)
	msg := sprintf("%s: kebijakan IAM memberi aksi wildcard (%s)", [rc.address, a])
}
