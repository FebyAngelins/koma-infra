# Kebijakan Modul 05: menolak plan yang membuka enam temuan stack rawan.
# Aturan 1 dan 3 dari starter; aturan 2, 4, 5, dan 6 ditulis di Bagian B.
# Dijalankan atas plan JSON:  conftest test rawan.plan.json --policy ../../policy
package main

import rego.v1

# Nama yang dianggap menyimpan rahasia (variabel, output).
pola_rahasia := `(?i)(password|passwd|secret|token|api_key|kunci_api)`

# Nilai rahasia tertulis langsung: NAMA=nilai, bukan NAMA=$VARIABEL.
pola_nilai_rahasia := `(?i)(password|passwd|secret|token)\s*[=:]\s*["']?[^\s"'$]`

port_admin := {22, 3389}

# ---------------------------------------------------------------- aturan 1 (starter)
# Bucket policy yang mengizinkan siapa pun (Principal "*").

publik("*")

publik(p) if p.AWS == "*"

publik(p) if "*" in p.AWS

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_s3_bucket_policy"
	s := json.unmarshal(rc.change.after.policy).Statement[_]
	s.Effect == "Allow"
	publik(s.Principal)
	msg := sprintf("%s: bucket policy mengizinkan akses publik (Principal *)", [rc.address])
}

# ---------------------------------------------------------------- aturan 2
# Port admin atau semua protokol terbuka untuk seluruh internet (IPv4 atau IPv6).

sumber_internet(a) if a.cidr_ipv4 == "0.0.0.0/0"

sumber_internet(a) if a.cidr_ipv6 == "::/0"

port_berbahaya(a) if a.ip_protocol == "-1"

# Rentang from_port..to_port yang melewati salah satu port admin.
port_berbahaya(a) if {
	some p in port_admin
	a.from_port <= p
	p <= a.to_port
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_vpc_security_group_ingress_rule"
	a := rc.change.after
	sumber_internet(a)
	port_berbahaya(a)
	msg := sprintf("%s: port admin atau semua protokol terbuka untuk internet", [rc.address])
}

# ---------------------------------------------------------------- aturan 3 (starter)
# Variabel bernama rahasia yang punya nilai bawaan: rahasianya tertulis di kode.

deny contains msg if {
	some nama, v in input.configuration.root_module.variables
	regex.match(pola_rahasia, nama)
	"default" in object.keys(v)
	msg := sprintf("var.%s: variabel rahasia punya nilai bawaan", [nama])
}

# ---------------------------------------------------------------- aturan 4
# Output bernama rahasia tanpa sensitive = true: nilainya tercetak di layar dan log.

deny contains msg if {
	some nama, o in input.configuration.root_module.outputs
	regex.match(pola_rahasia, nama)
	not o.sensitive
	msg := sprintf("output.%s: output rahasia tidak ditandai sensitive", [nama])
}

# ---------------------------------------------------------------- aturan 5
# Nilai rahasia tertulis langsung di user_data server (terbaca lewat ec2:Describe*).

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_instance"
	ud := rc.change.after.user_data
	is_string(ud)
	regex.match(pola_nilai_rahasia, ud)
	msg := sprintf("%s: user_data memuat nilai rahasia tertulis langsung", [rc.address])
}

# ---------------------------------------------------------------- aturan 6
# Kebijakan IAM yang mengizinkan aksi "*" atau "<layanan>:*" (bukan least privilege).

daftar(x) := [x] if is_string(x)

daftar(x) := x if is_array(x)

# Statement tunggal boleh ditulis sebagai objek, bukan daftar.
daftar(x) := [x] if is_object(x)

aksi_liar(a) if a == "*"

aksi_liar(a) if endswith(a, ":*")

jenis_kebijakan := {"aws_iam_role_policy", "aws_iam_policy"}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type in jenis_kebijakan
	is_string(rc.change.after.policy)
	s := daftar(json.unmarshal(rc.change.after.policy).Statement)[_]
	s.Effect == "Allow"
	some a in daftar(s.Action)
	aksi_liar(a)
	msg := sprintf("%s: kebijakan IAM mengizinkan aksi %s", [rc.address, a])
}
