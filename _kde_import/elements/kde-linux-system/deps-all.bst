kind: stack

# this should contain all layers

depends:
- kde-linux-system/devel/deps.bst
- kde-linux-system/snapd/deps.bst

(?):
- arch in ["x86_64"]:
    depends:
      (>):
      - kde-linux-system/nvidia-runtime/deps.bst
