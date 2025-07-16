#!/usr/bin/env bash
set -euo pipefail

DOMAIN="neo.id"
ROLE="Member"
DRY_RUN=false
AUTO_YES=false

trap 'echo "💥 Terjadi error di baris $LINENO"; exit 1' ERR

fail() { echo "❌ ERROR: $1" >&2; exit 1; }
log() { echo "$*"; }

run_with_spinner_and_dots() {
    local msg="$1"
    shift
    echo -n "🔄 $msg "

    (
        "$@" >/dev/null 2>&1
    ) &

    local pid=$!
    local spin='|/-\'
    local count=0

    while kill -0 "$pid" 2>/dev/null; do
        local i=$(( count % 4 ))
        printf "\b%c" "${spin:$i:1}"
        sleep 0.2
        count=$(( count + 1 ))
        if (( count % 10 == 0 )); then
            printf "."
        fi
    done
    wait $pid
    printf "\b ✅\n"
}

get_project_id() {
    local email=$1
    echo "Memeriksa pengguna: $email" >&2
    local projects
    projects=$(openstack role assignment list --user "$email" --user-domain "$DOMAIN" --role "$ROLE" -f value -c Project)
    [ -z "$projects" ] && fail "Pengguna '$email' atau projek tidak ditemukan."
    [ "$(echo "$projects" | wc -l)" -ne 1 ] && fail "Pengguna '$email' memiliki lebih dari satu projek."
    echo "$projects"
}

confirm_action() {
    if [ "$AUTO_YES" = true ]; then
        log "✅ Konfirmasi otomatis diaktifkan (--yes)"
    else
        read -rp "$1 (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || fail "Proses dibatalkan."
    fi
}

get_user_id() {
    openstack user show "$1" --domain "$DOMAIN" -f value -c id
}

print_summary() {
    local label=$1
    local p1=$2
    local p2=$3

    echo -e "\n$label"
    echo "========================"
    printf "🔹 %-30s\n" "$EMAIL1"
    printf "   ID User   : %s\n" "$(get_user_id "$EMAIL1")"
    printf "   Project ID: %s\n" "$p1"

    printf "\n🔹 %-30s\n" "$EMAIL2"
    printf "   ID User   : %s\n" "$(get_user_id "$EMAIL2")"
    printf "   Project ID: %s\n" "$p2"
    echo "========================"
}

usage() {
    echo "🔄 Skrip Switch Projek OpenStack"
    echo "Usage: $0 [-u1 email1] [-u2 email2] [--dry-run] [--yes]"
    echo "  -u1    Email pengguna 1"
    echo "  -u2    Email pengguna 2"
    echo "  --dry-run   Simulasi tanpa eksekusi"
    echo "  --yes       Skip konfirmasi"
    echo "  --help      Tampilkan bantuan"
}

# Parse Argumen
EMAIL1=""
EMAIL2=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u1) EMAIL1="$2"; shift 2 ;;
        -u2) EMAIL2="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --yes) AUTO_YES=true; shift ;;
        --help) usage; exit 0 ;;
        *) fail "Argumen tidak dikenal: $1" ;;
    esac
done

command -v openstack >/dev/null 2>&1 || fail "OpenStack CLI tidak ditemukan."

echo -e "\n=== 🔄 NEO - Switch Projek ===\n"

# Interaktif jika email tidak diberikan via argumen
if [ -z "$EMAIL1" ]; then read -rp "Masukkan Email Pengguna 1: " EMAIL1; fi
if [ -z "$EMAIL2" ]; then read -rp "Masukkan Email Pengguna 2: " EMAIL2; fi
[ -z "$EMAIL1" ] || [ -z "$EMAIL2" ] && fail "Kedua email harus diisi."

log "🔎 Mengambil informasi proyek awal..."
project1=$(get_project_id "$EMAIL1")
project2=$(get_project_id "$EMAIL2")

echo -e "\n--- REVIEW SEBELUM PERUBAHAN ---"
echo "========================"
printf "🔹 %-30s\n" "$EMAIL1"
printf "   ID User   : %s\n" "$(get_user_id "$EMAIL1")"
printf "   Project ID: %s\n" "$project1"

printf "\n🔹 %-30s\n" "$EMAIL2"
printf "   ID User   : %s\n" "$(get_user_id "$EMAIL2")"
printf "   Project ID: %s\n" "$project2"
echo "========================"

confirm_action "Apakah Anda yakin ingin melanjutkan?"

log "🚀 Memulai proses penukaran..."

if [ "$DRY_RUN" = true ]; then
    log "(Dry-Run Mode) Tidak ada perubahan yang dilakukan."
else
    run_with_spinner_and_dots "Menambahkan role $EMAIL2 ke $project1" openstack role add --user "$EMAIL2" --user-domain "$DOMAIN" --project "$project1" "$ROLE"
    run_with_spinner_and_dots "Menambahkan role $EMAIL1 ke $project2" openstack role add --user "$EMAIL1" --user-domain "$DOMAIN" --project "$project2" "$ROLE"
    run_with_spinner_and_dots "Menghapus role $EMAIL1 dari $project1" openstack role remove --user "$EMAIL1" --user-domain "$DOMAIN" --project "$project1" "$ROLE"
    run_with_spinner_and_dots "Menghapus role $EMAIL2 dari $project2" openstack role remove --user "$EMAIL2" --user-domain "$DOMAIN" --project "$project2" "$ROLE"
    log "✅ Proses penukaran selesai."
fi

# Ringkasan Before & After
print_summary "📋 Before" "$project1" "$project2"
print_summary "✅ After" "$project2" "$project1"
