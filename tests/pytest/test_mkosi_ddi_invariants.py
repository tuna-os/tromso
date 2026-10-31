"""Structural contracts for Tromso's isolated Mkosi DDI experiment."""

from configparser import ConfigParser

from pathlib import Path
import re

REPO = Path(__file__).resolve().parents[2]
CONFIG = (REPO / "mkosi/ddi/mkosi.conf").read_text()
TARGET = (REPO / "elements/mkosi/tromso-ddi.bst").read_text()
RECIPE = (REPO / "just/mkosi-ddi.just").read_text()
DOC = (REPO / "docs/mkosi-ddi.md").read_text()


def test_ddi_uses_exactly_one_buildstream_compose_target():
    assert re.search(r"(?m)^Distribution=buildstream$", CONFIG)
    package_lines = re.findall(r"(?m)^Packages=(.+)$", CONFIG)
    assert package_lines == ["mkosi/tromso-ddi.bst"]
    assert re.search(r"(?m)^kind: compose$", TARGET)
    assert "oci/layers/tromso-runtime.bst" in TARGET
    assert "oci/kde-linux/filesystem.bst" not in TARGET
    assert "oci/tromso.bst" not in TARGET


def test_mkosi_configuration_uses_valid_sections():
    config = ConfigParser(interpolation=None)
    config.read_string(CONFIG)
    assert config["Config"]["MinimumVersion"] == "28~devel"
    assert config["Distribution"]["Architecture"] == "x86-64"
    assert config["Build"]["ToolsTree"] == "yes"
    assert config["Output"]["RepartDirectories"] == "mkosi.repart"


def test_ddi_keeps_tromso_identity_and_distinct_output():
    stack = (REPO / "elements/oci/layers/tromso-stack.bst").read_text()
    identity = (REPO / "elements/oci/os-release.bst").read_text()
    assert "tromso/deps.bst" in stack
    assert "oci/os-release.bst" in stack
    assert 'ID: "tromso"' in identity
    assert 'IMAGE_PRETTY_NAME: "Tromso"' in identity
    assert re.search(r"(?m)^Format=disk$", CONFIG)
    assert re.search(r"(?m)^Output=tromso-mkosi-ddi$", CONFIG)
    assert re.search(r"(?m)^OutputDirectory=../../output/mkosi-ddi$", CONFIG)
    assert "bootable.raw" not in CONFIG + RECIPE


def test_ddi_has_explicit_gpt_root_and_efi_partitions():
    esp = (REPO / "mkosi/ddi/mkosi.repart/10-esp.conf").read_text()
    root = (REPO / "mkosi/ddi/mkosi.repart/20-root.conf").read_text()
    assert "Type=esp" in esp and "Format=vfat" in esp
    assert "SizeMinBytes=512M" in esp
    assert "Type=root-x86-64" in root and "Format=ext4" in root
    assert "Label=tromso-ROOT" in root
    assert "Label=tromso-EFI" in esp


def test_ddi_does_not_claim_bootability_without_direct_root_initrd():
    initrd = (REPO / "elements/oci/initramfs.bst").read_text()
    assert "INITRD_MODE: oci" in initrd
    assert "Bootable=yes" not in CONFIG
    assert "Bootloader=" not in CONFIG
    assert "KernelCommandLine=" not in CONFIG
    assert "not a bootable image" in DOC
    assert "direct-root boot contract" in DOC
    assert "does not create an OSTree deployment" in DOC


def test_ddi_has_no_release_or_security_workflow():
    assert "build-mkosi-ddi" in RECIPE
    assert "mkosi --directory mkosi/ddi build" in RECIPE
    assert not re.search(r"(?i)\b(push|cosign|signing|permissions|workflow)\b", CONFIG + RECIPE)
    workflows = [path.read_text() for path in (REPO / ".github/workflows").glob("*.y*ml")]
    assert any("mkosi/tromso-ddi.bst" in workflow for workflow in workflows)
    assert not any(
        re.search(r"(?im)^\s*(?:sudo\s+)?mkosi\s+(?:build|clean|publish)\b", workflow)
        for workflow in workflows
    )
