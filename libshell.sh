#!/bin/bash

# ==========================================
# LIBSHELL - Sistem Manajemen Perpustakaan
# Project UAS Linux Bash Shell
# ==========================================

# === WARNA ===
HIJAU='\033[1;32m'
MERAH='\033[1;31m'
KUNING='\033[1;33m'
BIRU='\033[1;34m'
CYAN='\033[1;36m'
PUTIH='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

# === SETUP FILE ===
mkdir -p data_buku
mkdir -p backup

touch data_buku/buku.txt
touch data_buku/peminjaman.txt
touch activity.log

# ==========================================
# FUNGSI CENTER
# ==========================================

LEBAR_KONTEN=50

get_padding() {
    local cols=$(tput cols 2>/dev/null || echo 80)
    local pad=$(( (cols - LEBAR_KONTEN) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf '%*s' "$pad" ''
}

cetak_tengah() {
    local pad
    pad=$(get_padding)
    echo -e "${pad}$1"
}

cetak_tengah_printf() {
    local pad
    pad=$(get_padding)
    printf "${pad}$@"
}

# ==========================================
# HEADER
# ==========================================
header() {
    clear
    local pad
    pad=$(get_padding)
    echo ""
    echo -e "${pad}${BIRU}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${pad}${BIRU}║    ${NC}     ${CYAN}📚  LIBSHELL LIBRARY SYSTEM  📚${NC}          ${BIRU}║${NC}"
    echo -e "${pad}${BIRU}║    ${NC}        ${DIM}Sistem Manajemen Perpustakaan${NC}         ${BIRU}║${NC}"
    echo -e "${pad}${BIRU}╚══════════════════════════════════════════════════╝${NC}"
    echo -e "${pad}      ${DIM}👤 $USER   🕐 $(date '+%H:%M')   📅 $(date '+%d/%m/%Y')${NC}"
    echo ""
}

# ==========================================
# PESAN
# ==========================================
pesan_sukses() {
    echo ""
    cetak_tengah "  ${HIJAU}✔ $1${NC}"
    echo ""
}

pesan_error() {
    echo ""
    cetak_tengah "  ${MERAH}✖ $1${NC}"
    echo ""
}

pesan_info() {
    echo ""
    cetak_tengah "  ${KUNING}ℹ $1${NC}"
    echo ""
}

tekan_enter() {
    echo ""
    cetak_tengah "  ${DIM}Tekan ENTER untuk kembali...${NC}"
    read
}

input_tengah() {
    local pad
    pad=$(get_padding)
    echo -ne "${pad}  $1"
    read HASIL_INPUT
}

# ==========================================
# TAMBAH BUKU
# ==========================================
tambah_buku() {
    header
    cetak_tengah "  ${CYAN}[ TAMBAH BUKU ]${NC}"
    echo ""

    input_tengah "📚 Judul Buku : "
    local judul="$HASIL_INPUT"

    input_tengah "✍  Penulis    : "
    local penulis="$HASIL_INPUT"

    input_tengah "📦 Stok Buku  : "
    local stok="$HASIL_INPUT"

    if ! [[ "$stok" =~ ^[0-9]+$ ]]; then
        pesan_error "Stok harus angka!"
        sleep 2
        return
    fi

    echo "$judul;$penulis;$stok" >> data_buku/buku.txt
    echo "[$(date '+%d/%m/%Y %H:%M')] Tambah buku: $judul" >> activity.log
    pesan_sukses "Buku berhasil ditambahkan!"
    sleep 2
}

# ==========================================
# LIHAT BUKU
# ==========================================
lihat_buku() {
    header
    cetak_tengah "  ${CYAN}[ DAFTAR BUKU ]${NC}"
    echo ""

    if [ ! -s data_buku/buku.txt ]; then
        pesan_info "Belum ada data buku!"
        tekan_enter
        return
    fi

    local pad
    pad=$(get_padding)

    printf "${pad}  ${PUTIH}%-4s %-25s %-15s %-5s${NC}\n" "No" "Judul" "Penulis" "Stok"
    printf "${pad}  %s\n" "--------------------------------------------------"

    nomor=1
    while IFS=';' read -r judul penulis stok; do
        [ -z "$judul" ] && continue
        if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi

        if [ "$stok" -le 0 ]; then
            warna="$MERAH"
        elif [ "$stok" -le 2 ]; then
            warna="$KUNING"
        else
            warna="$HIJAU"
        fi

        printf "${pad}  %-4s %-25s %-15s ${warna}%-5s${NC}\n" \
            "$nomor" "${judul:0:24}" "${penulis:0:14}" "$stok"
        nomor=$((nomor + 1))
    done < data_buku/buku.txt

    tekan_enter
}

# ==========================================
# CARI BUKU
# ==========================================
cari_buku() {
    header
    cetak_tengah "  ${CYAN}[ CARI BUKU ]${NC}"
    echo ""

    input_tengah "🔍 Masukkan judul buku: "
    local keyword="$HASIL_INPUT"

    local hasil
    hasil=$(grep -i "$keyword" data_buku/buku.txt)
    echo "[$(date '+%d/%m/%Y %H:%M')] Cari buku: $keyword" >> activity.log

    if [ -z "$hasil" ]; then
        pesan_error "Buku tidak ditemukan!"
    else
        echo ""
        cetak_tengah "  ${HIJAU}✔ Hasil Pencarian:${NC}"
        echo ""

        local pad
        pad=$(get_padding)

        printf "${pad}  ${PUTIH}%-4s %-25s %-15s %-5s${NC}\n" "No" "Judul" "Penulis" "Stok"
        printf "${pad}  %s\n" "--------------------------------------------------"

        nomor=1
        echo "$hasil" | while IFS=';' read -r judul penulis stok; do
            [ -z "$judul" ] && continue
            if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi

            if [ "$stok" -le 0 ]; then
                warna="$MERAH"
            elif [ "$stok" -le 2 ]; then
                warna="$KUNING"
            else
                warna="$HIJAU"
            fi

            printf "${pad}  %-4s %-25s %-15s ${warna}%-5s${NC}\n" \
                "$nomor" "${judul:0:24}" "${penulis:0:14}" "$stok"
            nomor=$((nomor + 1))
        done
    fi

    tekan_enter
}

# ==========================================
# PINJAM BUKU
# ==========================================
pinjam_buku() {
    header
    cetak_tengah "  ${CYAN}[ PINJAM BUKU ]${NC}"
    echo ""

    input_tengah "👤 Nama Peminjam : "
    local nama="$HASIL_INPUT"

    input_tengah "📚 Judul Buku    : "
    local buku="$HASIL_INPUT"

    local data
    data=$(grep -i "^$buku;" data_buku/buku.txt)

    if [ -z "$data" ]; then
        pesan_error "Judul tidak tersedia!"
        cetak_tengah "  ${DIM}Buku '$buku' tidak ada dalam sistem.${NC}"
        cetak_tengah "  ${DIM}Silakan cek menu Lihat Buku.${NC}"
    else
        local stok
        stok=$(echo "$data" | awk -F';' '{print $3}')

        if [ "$stok" -le 0 ]; then
            pesan_error "Stok buku habis!"
        else
            local stok_baru=$((stok - 1))
            grep -iv "^$buku;" data_buku/buku.txt > temp.txt
            echo "$buku;$(echo "$data" | awk -F';' '{print $2}');$stok_baru" >> temp.txt
            mv temp.txt data_buku/buku.txt

            # Simpan dengan format: nama;judul;tanggal_pinjam;AKTIF
            printf '%s\n' "$nama;$buku;$(date '+%d/%m/%Y');AKTIF" >> data_buku/peminjaman.txt

            echo "[$(date '+%d/%m/%Y %H:%M')] $nama meminjam: $buku" >> activity.log
            pesan_sukses "Buku berhasil dipinjam!"
            cetak_tengah "  📋 Tercatat atas nama: ${KUNING}$nama${NC}"
        fi
    fi

    sleep 2
}

# ==========================================
# KEMBALIKAN BUKU (UPDATED)
# ==========================================
kembalikan_buku() {
    header
    cetak_tengah "  ${CYAN}[ KEMBALIKAN BUKU ]${NC}"
    echo ""

    input_tengah "👤 Nama Peminjam : "
    local nama="$HASIL_INPUT"

    # Bersihkan file peminjaman dari karakter non-printable/binary dulu
    if [ -s data_buku/peminjaman.txt ]; then
        tr -cd '\11\12\15\40-\176' < data_buku/peminjaman.txt > temp_clean.txt
        mv temp_clean.txt data_buku/peminjaman.txt
    fi

    # Cek apakah nama ada di daftar peminjam aktif
    local cek_nama
    cek_nama=$(grep --text -i "^$nama;" data_buku/peminjaman.txt | grep --text ";AKTIF$")

    if [ -z "$cek_nama" ]; then
        pesan_error "Kamu tidak meminjam buku!"
        cetak_tengah "  ${DIM}Nama '$nama' tidak terdaftar sebagai peminjam aktif.${NC}"
        sleep 3
        return
    fi

    input_tengah "📚 Judul Buku    : "
    local buku="$HASIL_INPUT"

    # Cek apakah nama + buku cocok di peminjaman aktif
    local cek_pinjam
    cek_pinjam=$(grep --text -i "^$nama;$buku;" data_buku/peminjaman.txt | grep --text ";AKTIF$")

    if [ -z "$cek_pinjam" ]; then
        # Nama ada, tapi buku beda
        local buku_dipinjam
        buku_dipinjam=$(grep --text -i "^$nama;" data_buku/peminjaman.txt | grep --text ";AKTIF$" | awk -F';' '{print $2}')
        pesan_error "Kamu salah mengembalikan buku!"
        local pad
        pad=$(get_padding)
        echo ""
        printf "${pad}  ${KUNING}Buku yang kamu pinjam:${NC}\n"
        echo "$buku_dipinjam" | while read -r b; do
            printf "${pad}  ${HIJAU}>> ${NC}$b\n"
        done
        echo ""
        sleep 3
        return
    fi

    # Kembalikan: update stok buku
    local data_buku_record
    data_buku_record=$(grep -i "^$buku;" data_buku/buku.txt)

    if [ -z "$data_buku_record" ]; then
        pesan_error "Data buku tidak ditemukan di sistem!"
        sleep 2
        return
    fi

    local stok
    stok=$(echo "$data_buku_record" | awk -F';' '{print $3}')
    local stok_baru=$((stok + 1))

    grep -iv "^$buku;" data_buku/buku.txt > temp.txt
    echo "$buku;$(echo "$data_buku_record" | awk -F';' '{print $2}');$stok_baru" >> temp.txt
    mv temp.txt data_buku/buku.txt

    # Update status peminjaman: AKTIF → KEMBALI
    # Ganti baris yang cocok (nama+buku+AKTIF) menjadi KEMBALI, hanya 1 baris pertama
    local sudah_ganti=0
    while IFS= read -r baris; do
        [ -z "$baris" ] && continue
        if [ "$sudah_ganti" -eq 0 ]; then
            local n b s
            n=$(echo "$baris" | cut -d';' -f1)
            b=$(echo "$baris" | cut -d';' -f2)
            s=$(echo "$baris" | cut -d';' -f4)
            if [[ "${n,,}" == "${nama,,}" && "${b,,}" == "${buku,,}" && "$s" == "AKTIF" ]]; then
                echo "$baris" | sed 's/;AKTIF$/;KEMBALI/' >> temp_pinjam.txt
                sudah_ganti=1
                continue
            fi
        fi
        echo "$baris" >> temp_pinjam.txt
    done < data_buku/peminjaman.txt
    mv temp_pinjam.txt data_buku/peminjaman.txt

    echo "[$(date '+%d/%m/%Y %H:%M')] $nama mengembalikan: $buku" >> activity.log
    pesan_sukses "Buku berhasil dikembalikan!"
    cetak_tengah "  ✅ Terima kasih, ${KUNING}$nama${NC}!"

    sleep 2
}

# ==========================================
# DAFTAR PEMINJAM - Hanya Yang Masih Aktif
# ==========================================
daftar_peminjam() {
    header
    cetak_tengah "  ${CYAN}[ DAFTAR PEMINJAM AKTIF ]${NC}"
    cetak_tengah "  ${DIM}(Buku yang belum dikembalikan)${NC}"
    echo ""

    local pad
    pad=$(get_padding)

    # Bersihkan file dari karakter binary jika ada
    if [ -s data_buku/peminjaman.txt ]; then
        tr -cd '\11\12\15\40-\176' < data_buku/peminjaman.txt > temp_clean.txt
        mv temp_clean.txt data_buku/peminjaman.txt
    fi

    if [ ! -s data_buku/peminjaman.txt ]; then
        pesan_info "Belum ada data peminjaman!"
        tekan_enter
        return
    fi

    # Cek apakah ada peminjam aktif
    local ada_aktif
    ada_aktif=$(grep --text ";AKTIF$" data_buku/peminjaman.txt)

    if [ -z "$ada_aktif" ]; then
        pesan_sukses "Tidak ada peminjam aktif saat ini!"
        tekan_enter
        return
    fi

    printf "${pad}  ${PUTIH}%-4s %-20s %-22s %-10s${NC}\n" "No" "Nama Peminjam" "Judul Buku" "Tgl Pinjam"
    printf "${pad}  %s\n" "------------------------------------------------------------"

    nomor=1
    while IFS=';' read -r nama buku tanggal status; do
        [ -z "$nama" ] && continue
        [[ "$status" != "AKTIF" ]] && continue

        printf "${pad}  ${KUNING}%-4s${NC} %-20s %-22s %-10s\n" \
            "$nomor" "${nama:0:19}" "${buku:0:21}" "$tanggal"
        nomor=$((nomor + 1))
    done < data_buku/peminjaman.txt

    echo ""
    cetak_tengah "  ${DIM}Total peminjam aktif: $((nomor - 1)) orang${NC}"

    tekan_enter
}

# ==========================================
# STOK HABIS
# ==========================================
stok_habis() {
    header
    cetak_tengah "  ${CYAN}[ STOK HABIS ]${NC}"
    echo ""

    local pad
    pad=$(get_padding)

    local ada=0
    while IFS=';' read -r judul penulis stok; do
        [ -z "$judul" ] && continue
        if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi
        if [ "$stok" -le 0 ]; then
            ada=1
            break
        fi
    done < data_buku/buku.txt

    if [ "$ada" -eq 0 ]; then
        pesan_sukses "Semua stok buku masih tersedia!"
    else
        printf "${pad}  ${PUTIH}%-4s %-25s %-15s${NC}\n" "No" "Judul" "Penulis"
        printf "${pad}  %s\n" "----------------------------------------------"

        nomor=1
        while IFS=';' read -r judul penulis stok; do
            [ -z "$judul" ] && continue
            if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi
            if [ "$stok" -le 0 ]; then
                printf "${pad}  %-4s %-25s %-15s\n" \
                    "$nomor" "${judul:0:24}" "${penulis:0:14}"
                nomor=$((nomor + 1))
            fi
        done < data_buku/buku.txt
    fi

    tekan_enter
}

# ==========================================
# STOK DI BAWAH 10
# ==========================================
stok_minimal_10() {
    header
    cetak_tengah "  ${CYAN}[ STOK DI BAWAH 10 ]${NC}"
    echo ""

    local pad
    pad=$(get_padding)

    local ada=0
    while IFS=';' read -r judul penulis stok; do
        [ -z "$judul" ] && continue
        if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi
        if [ "$stok" -lt 10 ]; then
            ada=1
            break
        fi
    done < data_buku/buku.txt

    if [ "$ada" -eq 0 ]; then
        pesan_sukses "Tidak ada stok buku di bawah 10!"
    else
        printf "${pad}  ${PUTIH}%-4s %-25s %-15s %-5s${NC}\n" "No" "Judul" "Penulis" "Stok"
        printf "${pad}  %s\n" "--------------------------------------------------"

        nomor=1
        while IFS=';' read -r judul penulis stok; do
            [ -z "$judul" ] && continue
            if ! [[ "$stok" =~ ^[0-9]+$ ]]; then continue; fi
            if [ "$stok" -lt 10 ]; then
                if [ "$stok" -le 0 ]; then
                    warna="$MERAH"
                else
                    warna="$KUNING"
                fi
                printf "${pad}  %-4s %-25s %-15s ${warna}%-5s${NC}\n" \
                    "$nomor" "${judul:0:24}" "${penulis:0:14}" "$stok"
                nomor=$((nomor + 1))
            fi
        done < data_buku/buku.txt
    fi

    tekan_enter
}

# ==========================================
# HAPUS BUKU
# ==========================================
hapus_buku() {
    header
    cetak_tengah "  ${CYAN}[ HAPUS BUKU ]${NC}"
    echo ""

    input_tengah "🔍 Masukkan judul buku: "
    local buku="$HASIL_INPUT"

    local data
    data=$(grep -i "^$buku;" data_buku/buku.txt)

    if [ -z "$data" ]; then
        pesan_error "Buku tidak ditemukan!"
    else
        local pad
        pad=$(get_padding)

        echo ""
        cetak_tengah "  ${KUNING}Data Buku:${NC}"
        echo ""

        local judul penulis stok
        IFS=';' read -r judul penulis stok <<< "$data"

        printf "${pad}  📚 %-10s : %s\n" "Judul"   "$judul"
        printf "${pad}  ✍  %-10s : %s\n" "Penulis" "$penulis"
        printf "${pad}  📦 %-10s : %s\n" "Stok"    "$stok"

        echo ""
        input_tengah "⚠  Yakin ingin menghapus buku ini? (y/n): "
        local konfirmasi="$HASIL_INPUT"

        if [[ "$konfirmasi" == "y" || "$konfirmasi" == "Y" ]]; then
            grep -iv "^$buku;" data_buku/buku.txt > temp.txt
            mv temp.txt data_buku/buku.txt
            echo "[$(date '+%d/%m/%Y %H:%M')] Hapus buku: $buku" >> activity.log
            pesan_sukses "Buku berhasil dihapus!"
        else
            pesan_info "Penghapusan dibatalkan."
        fi
    fi

    sleep 2
}

# ==========================================
# BACKUP DATA
# ==========================================
backup_data() {
    header
    cetak_tengah "  ${CYAN}[ BACKUP DATA ]${NC}"
    echo ""

    local tanggal
    tanggal=$(date +%Y-%m-%d_%H-%M-%S)
    cp data_buku/buku.txt backup/buku_$tanggal.txt
    cp data_buku/peminjaman.txt backup/peminjaman_$tanggal.txt
    echo "[$(date '+%d/%m/%Y %H:%M')] Backup data" >> activity.log

    pesan_sukses "Backup berhasil!"
    cetak_tengah "  💾 Buku    : backup/buku_$tanggal.txt"
    cetak_tengah "  💾 Pinjaman: backup/peminjaman_$tanggal.txt"
    sleep 2
}

# ==========================================
# MONITOR SISTEM
# ==========================================
monitor_sistem() {
    header
    cetak_tengah "  ${CYAN}[ MONITOR SISTEM ]${NC}"
    echo ""

    cetak_tengah "  ${KUNING}💽 DISK:${NC}"
    df -h | grep '^/dev/' | while read -r baris; do
        cetak_tengah "  $baris"
    done

    echo ""
    cetak_tengah "  ${KUNING}🧠 RAM:${NC}"
    free -h | while read -r baris; do
        cetak_tengah "  $baris"
    done

    echo ""
    cetak_tengah "  ${KUNING}⚙  CPU (Top Proses):${NC}"
    ps aux --sort=-%cpu | head -6 | while read -r baris; do
        cetak_tengah "  $baris"
    done

    tekan_enter
}

# ==========================================
# KUNCI FILE
# ==========================================
kunci_file() {
    header
    cetak_tengah "  ${CYAN}[ KUNCI FILE ]${NC}"
    echo ""

    chmod 600 data_buku/buku.txt
    chmod 600 data_buku/peminjaman.txt
    echo "[$(date '+%d/%m/%Y %H:%M')] File dikunci" >> activity.log
    pesan_sukses "File berhasil dikunci! 🔒"

    ls -l data_buku/buku.txt | while read -r baris; do
        cetak_tengah "  $baris"
    done
    ls -l data_buku/peminjaman.txt | while read -r baris; do
        cetak_tengah "  $baris"
    done

    sleep 2
}

# ==========================================
# ACTIVITY LOG
# ==========================================
lihat_log() {
    header
    cetak_tengah "  ${CYAN}[ ACTIVITY LOG ]${NC}"
    echo ""

    if [ ! -s activity.log ]; then
        pesan_info "Belum ada log!"
    else
        tail -15 activity.log | while read -r baris; do
            cetak_tengah "  📋 $baris"
        done
    fi

    tekan_enter
}

# ==========================================
# MENU UTAMA
# ==========================================
while true; do

    header

    cetak_tengah "  ${KUNING}══════════  MANAJEMEN BUKU  ══════════${NC}"
    cetak_tengah "  ${HIJAU}1.${NC}  📚 Tambah Buku"
    cetak_tengah "  ${HIJAU}2.${NC}  📋 Lihat Buku"
    cetak_tengah "  ${HIJAU}3.${NC}  🔍 Cari Buku"
    cetak_tengah "  ${HIJAU}4.${NC}  📤 Pinjam Buku"
    cetak_tengah "  ${HIJAU}5.${NC}  📥 Kembalikan Buku"
    cetak_tengah "  ${HIJAU}6.${NC}  👥 Daftar Peminjam"
    cetak_tengah "  ${HIJAU}7.${NC}  ❌ Cek Stok Habis"
    cetak_tengah "  ${HIJAU}8.${NC}  ⚠  Stok Di Bawah 10"
    cetak_tengah "  ${HIJAU}9.${NC}  🗑  Hapus Buku"

    echo ""
    cetak_tengah "  ${KUNING}══════════════  SISTEM  ══════════════${NC}"
    cetak_tengah "  ${BIRU}10.${NC} 💾 Backup Data"
    cetak_tengah "  ${BIRU}11.${NC} 🖥  Monitor Sistem"
    cetak_tengah "  ${BIRU}12.${NC} 🔒 Kunci File"
    cetak_tengah "  ${BIRU}13.${NC} 📋 Activity Log"

    echo ""
    cetak_tengah "  ${MERAH}14.${NC} 🚪 Keluar"
    echo ""

    input_tengah "Pilih menu [1-14]: "
    pilih="$HASIL_INPUT"

    case $pilih in
        1) tambah_buku ;;
        2) lihat_buku ;;
        3) cari_buku ;;
        4) pinjam_buku ;;
        5) kembalikan_buku ;;
        6) daftar_peminjam ;;
        7) stok_habis ;;
        8) stok_minimal_10 ;;
        9) hapus_buku ;;
        10) backup_data ;;
        11) monitor_sistem ;;
        12) kunci_file ;;
        13) lihat_log ;;
        14)
            header
            cetak_tengah "  ${HIJAU}Terima kasih telah menggunakan LIBSHELL! 👋${NC}"
            cetak_tengah "  ${DIM}Sampai jumpa!${NC}"
            echo "[$(date '+%d/%m/%Y %H:%M')] Program ditutup" >> activity.log
            sleep 1
            clear
            exit 0
            ;;
        *)
            pesan_error "Pilihan tidak valid!"
            sleep 1
            ;;
    esac

done