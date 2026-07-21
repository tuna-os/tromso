kind: stack
depends:
- kde-linux-system/make-layer.bst
- kde-linux-system/codecs-extra/layer.bst
- kde-linux-system/devel/layer.bst
- kde-linux-system/snapd/layer.bst
- kde-linux-system/usr/layer.bst
# Temporarily disabling because the artifact cache currently fails to push usr-image.
#- kde-linux-system/signed-boot.bst
#- kde-linux-system/usr/image.bst
