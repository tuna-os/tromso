#!/usr/bin/bash
# Pre-install flatpaks into the live squashfs.
#
# Uses --mount=type=cache,target=/var/cache/flatpak-dl to persist the flatpak
# ostree repo across builds.  On each run the script:
#   1. Seeds /var/lib/flatpak/repo from the build cache (warm start)
#   2. Reconciles to match /tmp/flatpaks-list (only deltas downloaded)
#   3. Saves the repo back to the cache for next build
#
# /tmp/flatpaks-list is COPYd by the Containerfile so it's always current.
# Requires network at build time; CAP_SYS_ADMIN for dbus.

set -exo pipefail

FLATPAK_CACHE="/var/cache/flatpak-dl"

mkdir -p "${FLATPAK_CACHE}/tmp"
export TMPDIR="${FLATPAK_CACHE}/tmp"
mkdir -p /run/dbus
dbus-daemon --system --fork --nopidfile
sleep 1

if [ -d "${FLATPAK_CACHE}/repo/refs" ]; then
    echo "Seeding flatpak repo from build cache..."
    rsync -a --ignore-existing "${FLATPAK_CACHE}/repo/" /var/lib/flatpak/repo/ || true
    echo "Cache seed complete"
fi

flatpak remote-add --system --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

RELEASE_TAG="continuous"
FLATPAK_FILENAME="org.bootcinstaller.Installer.flatpak"
if [[ "${INSTALLER_CHANNEL:-stable}" == "dev" ]]; then
    RELEASE_TAG="continuous-dev"
    FLATPAK_FILENAME="org.bootcinstaller.Installer.Devel.flatpak"
fi
curl --retry 3 --location \
    "https://github.com/tuna-os/tuna-installer/releases/download/${RELEASE_TAG}/${FLATPAK_FILENAME}" \
    -o /tmp/tuna-installer.flatpak
INSTALLER_APP_ID="org.bootcinstaller.Installer"
[[ "${INSTALLER_CHANNEL:-stable}" == "dev" ]] && INSTALLER_APP_ID="org.bootcinstaller.Installer.Devel"

flatpak install --system --noninteractive --bundle /tmp/tuna-installer.flatpak || \
    flatpak update --system --noninteractive "${INSTALLER_APP_ID}"
rm /tmp/tuna-installer.flatpak

flatpak override --system --filesystem=/etc:ro "${INSTALLER_APP_ID}"

readarray -t WANTED < <(grep -v '^[[:space:]]*#' /tmp/flatpaks-list | grep -v '^[[:space:]]*$')

flatpak install --system --noninteractive --no-related --or-update flathub "${WANTED[@]}"

readarray -t INSTALLED < <(flatpak list --app --system --columns=application 2>/dev/null || true)
for app in "${INSTALLED[@]}"; do
    [[ "$app" == "org.bootcinstaller.Installer" ]] && continue
    [[ "$app" == "org.bootcinstaller.Installer.Devel" ]] && continue
    if [[ ! " ${WANTED[*]} " =~ " ${app} " ]]; then
        echo "Removing dropped flatpak: $app"
        flatpak uninstall --system --noninteractive "$app" || true
    fi
done

flatpak uninstall --system --noninteractive --unused || true

echo "Saving flatpak repo to build cache..."
mkdir -p "${FLATPAK_CACHE}"
rsync -a --delete /var/lib/flatpak/repo/ "${FLATPAK_CACHE}/repo/"
echo "Cache updated"
