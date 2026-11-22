# Catatan Bukti Modul 07 — Governance, Integrasi, dan Pipeline

| Hal | Isi |
|---|---|
| Nama | Feby Angelina |
| NIM | 123450039 |
| Kelompok | k01 |
| Kasus | Klinik Sehat Lampung (KSL) |
| Repo GitHub (pemilik/nama) | `FebyAngelins/koma-infra` (subjek OIDC imutabel: `FebyAngelins@325612421/koma-infra@1435254115`) |

Verifier dosen menolak (403 Forbidden) di setiap `koma cek m07`, sehingga potret dilewati sesuai arahan dosen dan bukti ditunjukkan lewat keluaran perintah dan run di bawah. ID akun ditulis `<akun>`.

## Catatan Persiapan

| Hal | Isi |
|---|---|
| Versi alat | koma 3.7.0 (≥ 3.5.0), OpenTofu v1.13.5, aws-cli 2.39.3; laptop pribadi |
| Starter | dipasang otomatis oleh DSWorkbench ke repo; commit `3f40682 m07: starter` di branch `modul-07` |
| Push workflow | ditolak karena token GitHub tanpa scope `workflow`; diperbaiki dengan `gh auth login -s workflow` (scope `gist, read:org, repo, workflow`) |
| P.2 izin verifier | plan `2 to add`: `koma-baca-observability` (izin M06 yang belum pernah di-apply) dan `koma-baca-integrasi` (M07); hanya aksi List/Get/Describe/Lookup, `iam:GetRole` terbatas `role/koma-123450039-*` |
| Bucket state dan key | `koma-123450039-tfstate-<akun>`; `m07/dev.tfstate` dan `m07/prod.tfstate` (`env/dev.backend.hcl`, `env/prod.backend.hcl`, beda hanya baris `key`) |
| Variabel repo | `KOMA_NIM = 123450039`, `KOMA_KELOMPOK = k01`, `AWS_ROLE_ARN` (E.2); Actions diizinkan |
| G1 pusat biaya | CC-110 Layanan Klinis (RME), CC-120 Laboratorium, CC-210 Keuangan dan Klaim, CC-310 Analytics dan Mutu, CC-900 Platform TI bersama |
| G2 lingkungan | dev, staging (uji integrasi laboratorium mitra dengan data sintetis), prod; dev dan staging tidak boleh berisi data pasien asli |
| G3 anggaran | Rp 210 juta/bulan infrastruktur TI, porsi cloud publik maks. Rp 35 juta; tagihan uji coba naik 55% (Rp 22 juta → Rp 34,1 juta) tanpa pemilik jelas |
| G4 label | `owner`, `env`, `cost-center`, `data-class` wajib; `data-class` rahasia hanya di prod dan hanya di private cloud; ukuran prod minimal sedang |
| A1 kelas data | publik, internal, rahasia; data ter-pseudonim tetap rahasia, hanya agregat tanpa identitas yang boleh internal |
| H3 pesan | event "hasil lab siap" dan "order lab dibuat" ke satu topik; konsumen notifikasi pasien dan analytics |
| H4 arsip | ringkasan harian ter-pseudonim ke cloud publik, retensi bisnis 10 tahun; bucket lab menghapus objek setelah 7 hari |
| H6 kegagalan | bila cloud publik tak terjangkau 1 hari RME tetap jalan, laporan dinas boleh terlambat ≤ 3 hari; lifecycle bucket arsip uji pernah diubah dari konsol sehingga 9 hari arsip terhapus |
| Keputusan nilai lingkungan | Sesi kelas memakai nilai starter (dev CC-101/internal, prod CC-201/rahasia). Nilai KSL diubah lewat PR di Tugas: dev CC-900/internal (G2: data sintetis, biaya platform), prod CC-120/rahasia (H3: event hasil lab, A1: ter-pseudonim tetap rahasia) |

## Catatan Bagian A — Modul dan Lingkungan Dev

| Hal | Isi |
|---|---|
| Plan dev (sebelum budget) | `Plan: 13 to add, 0 to change, 0 to destroy.`; output `bucket_arsip = "koma-123450039-m07-dev-arsip-<akun>"`, `fungsi = "koma-123450039-m07-dev-pengarsip"`, `lingkungan = "dev"`, `dlq_url` null; tanpa antrean `-gagal` |
| Apply dev | `Apply complete! Resources: 13 added, 0 changed, 0 destroyed.` (22-11 ±19.21 WIB) |
| `koma kirim dev` | `Terkirim ke koma-123450039-m07-dev-pesanan: 5 pesanan sah, 0 pesan rusak.` (P-20261122122320-001 … -005) |
| Objek arsip | 5 objek `arsip/2026-11-22/P-20261122122320-00{1..5}.json` (148 byte), 19.23.25–19.23.28 WIB |
| Log fungsi | 5 baris `{"arsip": "arsip/2026-11-22/P-…json"}`, `Memory Size: 128 MB`, cold start ±250–330 ms |
| Potret 1 | 403 (dilewati) |

## Catatan Bagian B — Prod dari Kode yang Sama

| Hal | Isi |
|---|---|
| Sebelum plan prod | `tofu init -reconfigure -backend-config=env/prod.backend.hcl`; `tofu output lingkungan` → `Warning: No outputs found` (state prod kosong) |
| Plan dan apply prod | 14 resource (tambahan `module.jalur.aws_sqs_queue.gagal[0]`), memori 256 MB |
| Dua key state | `aws s3 ls s3://koma-123450039-tfstate-<akun>/m07/`: `dev.tfstate` 25682 byte (19.21.45), `prod.tfstate` 27655 byte (19.30.07) |
| `koma kirim prod` | 5 pesanan sah (P-20261122123130-001 … -005), 19.31 WIB |

| Hal | dev | prod |
|---|---|---|
| Resource (tahap A/B) | 13 | 14 |
| Memori fungsi | 128 MB | 256 MB |
| DLQ | tidak | `koma-123450039-m07-prod-gagal` |
| Retensi arsip | 1 hari | 7 hari (H4: retensi bisnis 10 tahun; selisih karena bucket lab) |
| cost-center | CC-101 | CC-201 |
| data-class | internal | rahasia |
| Anggaran | USD 2 | USD 5 |

Potret 2: 403 (dilewati).

## Catatan Bagian C — Tata Kelola Tiga Lapis

| Hal | Isi |
|---|---|
| Lapis 1 validasi (`-var=data_class=rahasia` di dev) | `Error: Invalid value for variable` … `var.data_class is "rahasia"`, `var.lingkungan is "dev"`, `Data rahasia hanya boleh di lingkungan prod (G4).` (`variables.tf:49`); plan berhenti sebelum resource dihitung |
| Budget (C.2) | dev `1 to add` (`koma-123450039-m07-dev`, 2.0 USD, `user:cost-center$CC-101`); prod `1 to add` (`koma-123450039-m07-prod`, 5.0 USD, `user:cost-center$CC-201`) |
| Lapis 2 check (prod, `-var=dengan_dlq=false`) | `Warning: Check block assertion failed` … `Prod semestinya memakai DLQ dan ukuran sedang (G4, O1).`; plan tetap jadi (DLQ akan dihapus, `dlq_url` → null) |
| `tofu test` | 6 run: `dev_kecil_tanpa_dlq`, `prod_dari_kode_yang_sama`, `rahasia_di_dev_ditolak`, `pusat_biaya_tak_sah`, `ukuran_di_luar_preset`, `prod_tanpa_dlq_diperingatkan`; `Success! 6 passed, 0 failed.` |
| Lapis 3 Conftest, plan prod salah, `--namespace m07` | `FAIL - salah.plan.json - m07 - module.jalur.aws_sqs_queue.antrean: antrean prod tanpa dead-letter queue (-gagal)`; `11 tests, 10 passed, 0 warnings, 1 failure, 0 exceptions` |
| Plan prod salah tanpa namespace | `6 tests, 6 passed` (hanya paket `main` M05, tidak tahu DLQ) |
| Plan prod benar | `11 tests, 11 passed` (dibuktikan juga oleh langkah Gerbang setiap run pipeline) |
| `koma showback` | dev CC-101/internal: 1 event-source-mapping, 1 function, 1 log-group, 1 s3, 1 sns, 1 sqs; prod CC-201/rahasia: sama dengan 2 sqs; tak bertuan 0 |
| `koma showback semua` | tak bertuan 3: dua kunci KMS m05 (masa tunggu penghapusan) dan bucket state m00 |

## Catatan Bagian D — Integrasi dan Kegagalan

| Hal | Isi |
|---|---|
| D.1 prod `--jumlah 2 --rusak 1` | dikirim 19.41.05 WIB; P-20261122124105-001 dan -002 diarsip 19.41.06–07 (256 MB); pesan rusak `eac1e250-…` gagal 19.41.08, 19.41.38, 19.42.08 WIB (`field hilang: id_pesanan`), jarak 30 detik |
| DLQ prod | `ApproximateNumberOfMessages = 1` pada `koma-123450039-m07-prod-gagal` |
| D.2 dev `--jumlah 0 --rusak 1` | pesan rusak `d85a3e4b-…` terus gagal setiap 30 detik, masih berputar pukul 20.29.35, 20.30.05, 20.30.35 WIB; antrean dev `ApproximateNumberOfMessagesNotVisible = 1`; tidak di-purge |
| Potret 3 | 403 (dilewati) |

## Catatan Bagian E — Identitas Pipeline

| Hal | Isi |
|---|---|
| Plan m00-pipeline | `3 to add` (provider OIDC, role, kebijakan `koma-pipeline-m07`) |
| `role_arn` | `arn:aws:iam::<akun>:role/koma-123450039-pipeline`; `oidc_provider_arn` `arn:aws:iam::<akun>:oidc-provider/token.actions.githubusercontent.com` |
| Variabel repo | `AWS_ROLE_ARN`, `KOMA_NIM`, `KOMA_KELOMPOK` (dibuat dengan `gh variable set`) |
| PR pertama | https://github.com/FebyAngelins/koma-infra/pull/7 |
| Run PR gagal (OIDC) | https://github.com/FebyAngelins/koma-infra/actions/runs/45024392050 percobaan 1: `Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity`. Penyebab: repo memakai `use_immutable_subject: true`, sehingga `sub` token berbentuk `repo:FebyAngelins@325612421/koma-infra@1435254115:pull_request`, tidak cocok dengan pola `repo:FebyAngelins/koma-infra:…`. Perbaikan: variabel `github_repo_imutabel` dan trust menerima kedua bentuk untuk repo yang sama (`0 to add, 1 to change`) |
| Run PR lulus | https://github.com/FebyAngelins/koma-infra/actions/runs/45024392050 (rerun): `Plan: 0 to add, 8 to change, 0 to destroy.`, Gerbang `11 tests, 11 passed`, Terapkan dilewati; juga https://github.com/FebyAngelins/koma-infra/actions/runs/45025297911 |

## Catatan Bagian F — Hanya Lewat Pipeline

| Hal | Isi |
|---|---|
| F.1 merge PR #7, terapkan dev | https://github.com/FebyAngelins/koma-infra/actions/runs/45025746837: `Plan: 0 to add, 8 to change`, `11 tests, 11 passed`, `Apply complete! Resources: 0 added, 8 changed, 0 destroyed.` (13.07 UTC); tag topik dev `penerap = github-actions`, `run` = nomor run |
| F.2 PR ditahan gerbang | PR https://github.com/FebyAngelins/koma-infra/pull/8 (`TulisArsip` diubah ke `s3:*`), run https://github.com/FebyAngelins/koma-infra/actions/runs/45026876534: lulus uji, `Plan: 0 to add, 9 to change, 0 to destroy.`, lalu `FAIL - rencana.plan.json - m07 - module.jalur.aws_iam_role_policy.pengarsip: kebijakan IAM memberi aksi wildcard (s3:*)`, `11 tests, 10 passed, 0 warnings, 1 failure, 0 exceptions`. Tombol merge tetap dapat diklik; PR ditutup tanpa merge dan branch dihapus |
| F.3 terapkan prod (manual) | https://github.com/FebyAngelins/koma-infra/actions/runs/45027648829: `Plan: 0 to add, 9 to change, 0 to destroy.`, `11 tests, 11 passed`, `Apply complete! Resources: 0 added, 9 changed, 0 destroyed.` (13.29 UTC) |
| Potret 4 | 403 (dilewati) |

## Catatan Bagian G — Bongkar

(diisi setelah bongkar)

## Langkah dan bukti

| Waktu (WIB) | Perintah atau run | Hasil singkat |
|---|---|---|
| 22-11 ±19.10 | `tofu apply` m00-verifier | 2 kebijakan baca ditambahkan |
| 22-11 ±19.21 | `tofu apply dev.tfplan` | 13 added |
| 22-11 19.23 | `koma kirim dev`, `koma cek m07` | 5 objek arsip; verifier 403 |
| 22-11 19.30 | `tofu apply prod.tfplan` | 14 added |
| 22-11 19.31 | `koma kirim prod`, `koma cek m07` | 5 pesanan; verifier 403 |
| 22-11 ±19.35 | budget dev dan prod, uji tiga lapis | 1 added masing-masing; validasi, check, test, Conftest sesuai |
| 22-11 19.41 | `koma kirim prod --jumlah 2 --rusak 1` | 3 kali gagal, DLQ = 1 |
| 22-11 ±19.45 | `koma kirim dev --jumlah 0 --rusak 1`, `koma cek m07` | berputar tiap 30 detik; verifier 403 |
| 22-11 ±19.55 | `tofu apply` m00-pipeline | 3 added |
| 22-11 ±20.00 | run 45024392050 (PR #7) | gagal OIDC, lalu lulus setelah trust subjek imutabel |
| 22-11 20.07 | run 45025746837 (merge ke main) | dev 8 changed lewat pipeline |
| 22-11 20.20 | run 45026876534 (PR #8) | ditahan gerbang (`s3:*`) |
| 22-11 20.29 | run 45027648829 (manual prod) | prod 9 changed lewat pipeline; `koma cek m07` 403 |
