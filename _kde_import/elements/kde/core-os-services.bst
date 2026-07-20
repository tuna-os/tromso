kind: stack
description: Core OS services needed by KDE desktop

depends:
# Network management
- core-deps/NetworkManager.bst

# Power management
- core-deps/upower.bst

# User and session management
- core-deps/accountsservice.bst
