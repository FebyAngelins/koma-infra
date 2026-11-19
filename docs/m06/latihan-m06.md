# Latihan 6.1 — Satu alamat, dua versi, satu alarm

| Hal | Isi |
|---|---|
| Nama | |
| NIM | |
| Kelompok | `k0_` |
| Kasus | |

Berkas ini ditulis sendiri dan diunggah bersama `bukti/bukti-m06.json` (setelah Bagian G, potret terakhir kosong) ke **Latihan Mandiri di Lab — Modul 06**. Keluaran berasal dari akun dan terminal Anda sendiri; penjelasannya dengan kalimat Anda sendiri. Jangan menempelkan token verifier, isi state, atau 12 digit ID akun (tulis `<akun>`); nama DNS ALB dan ID resource boleh ditulis.

## 1. Impor tanpa mengganti (B.4)

Baris `Plan:` plan impor:

```text

```

Perubahan in-place yang diusulkan (resource dan tag):

| Resource | Tag yang ditambah | Tag yang dihapus |
|---|---|---|
| `aws_instance.legacy[0]` | | |
| `aws_security_group.legacy[0]` | | |
| `aws_vpc_security_group_ingress_rule.legacy_http[0]` | | |

Mengapa tidak ada `to add` maupun `to destroy`:

Satu atribut yang, bila ditulis berbeda di kode, mengubah impor menjadi penggantian, dan akibatnya bagi pengguna L2 kasus saya:

Risiko `ignore_changes = [ami, user_data, user_data_base64]` bagi kode sebagai sumber kebenaran:

## 2. Alih tanpa jeda yang terasa (C.8)

Baris `Plan:` plan alih dan resource yang berubah:

```text

```

Ringkasan `koma probe`:

| Sampel | Gagal | Jeda terpanjang (dtk) | Versi yang terlihat | Alih pada detik |
|---|---|---|---|---|
| | | | | |

Mengapa listener ALB menghasilkan jeda sekecil ini (dan apa batas resolusi probe):

Perbandingan dengan ambang L4 dan jadwal L3 kasus saya:

## 3. Alarm yang terbukti (D.5)

Ringkasan `koma beban`:

```text

```

Riwayat alarm (`describe-alarm-history`, `StateUpdate`):

```text

```

| Hal | Waktu (WIB) |
|---|---|
| Beban dimulai | |
| Alarm `OK → ALARM` | |
| Beban berhenti | |
| Alarm `ALARM → OK` | |
| **Waktu deteksi** (menit) | |

Perbandingan dengan O5 dan anggaran galat O1 kasus saya (anggaran per 30 hari, persentase yang habis selama waktu deteksi):

## 4. Bukti

- Potret 5 (D.6) pada (WIB), `Latihan lulus`:
- Potret bersih (G.2) pada (WIB), `bersih_akhir`:
- `latihan_lulus` dan `sumber` pada `bukti/bukti-m06.json` yang diunggah:
