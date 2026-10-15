AA_PROXY_BAP_VERSION = local
AA_PROXY_BAP_SITE = /aa-proxy/aa-proxy-bap
AA_PROXY_BAP_SITE_METHOD = local

# obtain git hashes for aa-proxy-bap and buildroot
BUILDROOT_DIR = $(realpath $(TOPDIR)/..)
BUILDROOT_COMMIT = $(shell git config --global --add safe.directory $(BUILDROOT_DIR) && git -C $(BUILDROOT_DIR) rev-parse HEAD)
AA_PROXY_BAP_COMMIT = $(shell git config --global --add safe.directory $(AA_PROXY_BAP_SITE) && git -C $(AA_PROXY_BAP_SITE) rev-parse HEAD)

define AA_PROXY_BAP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/aa-proxy-bap $(TARGET_DIR)/usr/bin
	$(INSTALL) -D -m 0644 $(@D)/contrib/aa-proxy-bap.toml $(TARGET_DIR)/etc/aa-proxy-bap.toml
	$(INSTALL) -D -m 0755 $(@D)/contrib/S95aa-proxy-bap $(TARGET_DIR)/etc/init.d/S95aa-proxy-bap
	$(INSTALL) -D -m 0644 $(@D)/contrib/bap_bridge.wasm $(TARGET_DIR)/usr/share/aa-proxy-bap/bap_bridge.wasm
endef

AA_PROXY_BAP_CARGO_BUILD_OPTS = --package aa-proxy-bap

# pass git hashes as env variables
AA_PROXY_BAP_CARGO_ENV = \
	AA_PROXY_BAP_COMMIT="$(AA_PROXY_BAP_COMMIT)" \
	BUILDROOT_COMMIT="$(BUILDROOT_COMMIT)"

# use own toolchain only for RISC-V builds (milkv-duos)
ifeq ($(findstring milkv-duos,$(CONFIG_DIR)),milkv-duos)
# Add our own toolchain to path
AA_PROXY_BAP_CARGO_ENV += PATH=/app/buildroot/output/milkv-duos/build/riscv/bin:$(BR_PATH)
endif

define AA_PROXY_BAP_VENDOR_CONFIG
	mkdir -p $(BR_CARGO_HOME) && \
	cd $(@D) && \
	CARGO_HOME=$(BR_CARGO_HOME) $(HOST_DIR)/bin/cargo vendor \
		--manifest-path Cargo.toml --locked VENDOR >/dev/null && \
	mkdir -p .cargo && \
	printf '[source.crates-io]\nreplace-with = "vendored-sources"\n\n[source.vendored-sources]\ndirectory = "VENDOR"\n' > .cargo/config.toml
endef
AA_PROXY_BAP_PRE_BUILD_HOOKS += AA_PROXY_BAP_VENDOR_CONFIG

$(eval $(cargo-package))

# Caching für lokale Entwicklung deaktivieren: Bei jedem 'make' neu syncen und bauen.
# Alle drei Stamps müssen explizit invalidiert werden, da Buildroot zwischen
# rsync und configure eine order-only dependency (|) verwendet, die keine
# Timestamp-Propagation auslöst.
.PHONY: aa-proxy-bap-force-build
$(AA_PROXY_BAP_DIR)/.stamp_rsynced: aa-proxy-bap-force-build
$(AA_PROXY_BAP_DIR)/.stamp_built: aa-proxy-bap-force-build
$(AA_PROXY_BAP_DIR)/.stamp_target_installed: aa-proxy-bap-force-build
