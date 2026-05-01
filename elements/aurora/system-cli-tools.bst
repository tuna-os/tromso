kind: stack
description: Essential CLI tools for Aurora (filesystem, storage, system inspection)

depends:
  # Filesystem manipulation tools
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dosfstools.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/e2fsprogs.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/f2fs-tools.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/ntfs-3g.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/exfatprogs.bst

  # Modern image/storage tools
  - kde-build-meta.bst:gnomeos-deps/erofs-utils.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/lvm2.bst

  # UEFI and Secure Boot management
  - kde-build-meta.bst:freedesktop-sdk.bst:components/efibootmgr.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/mokutil.bst

  # Hardware inspection
  - kde-build-meta.bst:freedesktop-sdk.bst:components/dmidecode.bst
  - kde-build-meta.bst:freedesktop-sdk.bst:components/hwinfo.bst

  # SCSI device enumeration
  - kde-build-meta.bst:freedesktop-sdk.bst:components/lsscsi.bst
