#############################################################
#
# openssh
#
#############################################################

OPENSSH_SITE:=ftp://ftp.tux.org/bsd/openbsd/OpenSSH/portable/
OPENSSH_DIR:=$(BUILD_DIR)/openssh-3.8p1
OPENSSH_SOURCE:=openssh-3.8p1.tar.gz
OPENSSH_PATCH:=$(SOURCE_DIR)/openssh.patch

OPENSSH_IPK_DIR:=$(BUILD_DIR)/openssh-3.8p1-ipk
OPENSSH_SERVER_IPK:=$(BUILD_DIR)/openssh-server_3.8p1-1_mipsel.ipk
OPENSSH_CLIENT_IPK:=$(BUILD_DIR)/openssh-client_3.8p1-1_mipsel.ipk
OPENSSH_SFTP_SERVER_IPK:=$(BUILD_DIR)/openssh-sftp-server_3.8p1-1_mipsel.ipk
OPENSSH_SFTP_CLIENT_IPK:=$(BUILD_DIR)/openssh-sftp-client_3.8p1-1_mipsel.ipk
OPENSSH_CLIENT_EX_IPK:=$(BUILD_DIR)/openssh-client-extras_3.8p1-1_mipsel.ipk

$(DL_DIR)/$(OPENSSH_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENSSH_SITE)/$(OPENSSH_SOURCE)

$(OPENSSH_DIR)/.unpacked: $(DL_DIR)/$(OPENSSH_SOURCE) $(OPENSSH_PATCH)
	zcat $(DL_DIR)/$(OPENSSH_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	cat $(OPENSSH_PATCH) | patch -p1 -d $(OPENSSH_DIR)
	touch  $(OPENSSH_DIR)/.unpacked

$(OPENSSH_DIR)/.configured: $(OPENSSH_DIR)/.unpacked
	(cd $(OPENSSH_DIR); rm -rf config.cache; autoconf; \
		$(TARGET_CONFIGURE_OPTS) \
		LD=$(TARGET_CROSS)gcc \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libexecdir=/usr/sbin \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/man \
		--infodir=/usr/info \
		--includedir=$(STAGING_DIR)/include \
		--disable-lastlog --disable-utmp \
		--disable-utmpx --disable-wtmp --disable-wtmpx \
		--without-x \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	);
	touch  $(OPENSSH_DIR)/.configured

$(OPENSSH_DIR)/ssh: $(OPENSSH_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(OPENSSH_DIR)
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/scp
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sftp
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sftp-server
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-add
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-agent
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keygen
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keyscan
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keysign
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-rand-helper
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sshd

$(TARGET_DIR)/usr/bin/ssh: $(OPENSSH_DIR)/ssh
	$(MAKE) CC=$(TARGET_CC) DESTDIR=$(TARGET_DIR) -C $(OPENSSH_DIR) install
	mkdir -p $(TARGET_DIR)/etc/init.d/
	cp $(OPENSSH_DIR)/S50sshd $(TARGET_DIR)/etc/init.d/
	chmod a+x $(TARGET_DIR)/etc/init.d/S50sshd
	rm -rf $(TARGET_DIR)/usr/info $(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc
	# since this is the embedded build, keep things to minimum
	rm $(TARGET_DIR)/etc/moduli
	rm $(TARGET_DIR)/usr/bin/sftp
	rm $(TARGET_DIR)/usr/bin/ssh-add
	rm $(TARGET_DIR)/usr/bin/ssh-agent
	rm $(TARGET_DIR)/usr/bin/ssh-keyscan
	rm $(TARGET_DIR)/usr/sbin/sftp-server
	rm $(TARGET_DIR)/usr/sbin/ssh-keysign

openssh: $(TARGET_DIR)/usr/bin/ssh

$(OPENSSH_IPK_DIR)/usr/bin/ssh: $(OPENSSH_DIR)/ssh
	$(MAKE) CC=$(TARGET_CC) DESTDIR=$(OPENSSH_IPK_DIR) -C $(OPENSSH_DIR) install
	mkdir -p $(OPENSSH_IPK_DIR)/etc/init.d/
	cp $(OPENSSH_DIR)/S50sshd $(OPENSSH_IPK_DIR)/etc/init.d/
	chmod a+x $(OPENSSH_IPK_DIR)/etc/init.d/S50sshd
	rm -rf $(OPENSSH_IPK_DIR)/usr/info $(OPENSSH_IPK_DIR)/usr/man $(OPENSSH_IPK_DIR)/usr/share/doc

$(OPENSSH_SERVER_IPK): $(OPENSSH_IPK_DIR)/usr/bin/ssh
	rm -rf $(OPENSSH_IPK_DIR)/build
	mkdir -p $(OPENSSH_IPK_DIR)/build/CONTROL
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.control $(OPENSSH_IPK_DIR)/build/CONTROL/control
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.conffiles $(OPENSSH_IPK_DIR)/build/CONTROL/conffiles
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.preinst $(OPENSSH_IPK_DIR)/build/CONTROL/preinst
	chmod a+x $(OPENSSH_IPK_DIR)/build/CONTROL/preinst
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.postinst $(OPENSSH_IPK_DIR)/build/CONTROL/postinst
	chmod a+x $(OPENSSH_IPK_DIR)/build/CONTROL/postinst
	mkdir -p $(OPENSSH_IPK_DIR)/build/etc/init.d
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.sshd_config $(OPENSSH_IPK_DIR)/build/etc/sshd_config
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.server.S50sshd-ipk $(OPENSSH_IPK_DIR)/build/etc/init.d/S50sshd
	chmod a+x $(OPENSSH_IPK_DIR)/build/etc/init.d/S50sshd
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/sbin
	cp $(OPENSSH_IPK_DIR)/usr/sbin/sshd $(OPENSSH_IPK_DIR)/build/usr/sbin
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/ssh-keygen $(OPENSSH_IPK_DIR)/build/usr/bin
	cd $(BUILD_DIR); $(STAGING_DIR)/bin/ipkg-build -c -o root -g root $(OPENSSH_IPK_DIR)/build
	rm -rf $(OPENSSH_IPK_DIR)/build

$(OPENSSH_CLIENT_IPK): $(OPENSSH_IPK_DIR)/usr/bin/ssh
	rm -rf $(OPENSSH_IPK_DIR)/build
	mkdir -p $(OPENSSH_IPK_DIR)/build/CONTROL
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.client.control $(OPENSSH_IPK_DIR)/build/CONTROL/control
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.client.conffiles $(OPENSSH_IPK_DIR)/build/CONTROL/conffiles
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.client.preinst $(OPENSSH_IPK_DIR)/build/CONTROL/preinst
	chmod a+x $(OPENSSH_IPK_DIR)/build/CONTROL/preinst
	mkdir -p $(OPENSSH_IPK_DIR)/build/etc
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.client.ssh_config $(OPENSSH_IPK_DIR)/build/etc/ssh_config
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/ssh $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/scp $(OPENSSH_IPK_DIR)/build/usr/bin
	cd $(BUILD_DIR); $(STAGING_DIR)/bin/ipkg-build -c -o root -g root $(OPENSSH_IPK_DIR)/build
	rm -rf $(OPENSSH_IPK_DIR)/build

$(OPENSSH_SFTP_SERVER_IPK): $(OPENSSH_IPK_DIR)/usr/bin/ssh
	rm -rf $(OPENSSH_IPK_DIR)/build
	mkdir -p $(OPENSSH_IPK_DIR)/build/CONTROL
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.sftp-server.control $(OPENSSH_IPK_DIR)/build/CONTROL/control
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/sbin
	cp $(OPENSSH_IPK_DIR)/usr/sbin/sftp-server $(OPENSSH_IPK_DIR)/build/usr/sbin
	cd $(BUILD_DIR); $(STAGING_DIR)/bin/ipkg-build -c -o root -g root $(OPENSSH_IPK_DIR)/build
	rm -rf $(OPENSSH_IPK_DIR)/build

$(OPENSSH_SFTP_CLIENT_IPK): $(OPENSSH_IPK_DIR)/usr/bin/ssh
	rm -rf $(OPENSSH_IPK_DIR)/build
	mkdir -p $(OPENSSH_IPK_DIR)/build/CONTROL
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.sftp-client.control $(OPENSSH_IPK_DIR)/build/CONTROL/control
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/sftp $(OPENSSH_IPK_DIR)/build/usr/bin
	cd $(BUILD_DIR); $(STAGING_DIR)/bin/ipkg-build -c -o root -g root $(OPENSSH_IPK_DIR)/build
	rm -rf $(OPENSSH_IPK_DIR)/build

$(OPENSSH_CLIENT_EX_IPK): $(OPENSSH_IPK_DIR)/usr/bin/ssh
	rm -rf $(OPENSSH_IPK_DIR)/build
	mkdir -p $(OPENSSH_IPK_DIR)/build/CONTROL
	cp $(SOURCE_DIR)/openwrt/ipkg/openssh/openssh.client.ex.control $(OPENSSH_IPK_DIR)/build/CONTROL/control
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/ssh-add $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/ssh-agent $(OPENSSH_IPK_DIR)/build/usr/bin
	cp $(OPENSSH_IPK_DIR)/usr/bin/ssh-keyscan $(OPENSSH_IPK_DIR)/build/usr/bin
	mkdir -p $(OPENSSH_IPK_DIR)/build/usr/sbin
	cp $(OPENSSH_IPK_DIR)/usr/sbin/ssh-keysign $(OPENSSH_IPK_DIR)/build/usr/sbin
	cd $(BUILD_DIR); $(STAGING_DIR)/bin/ipkg-build -c -o root -g root $(OPENSSH_IPK_DIR)/build
	rm -rf $(OPENSSH_IPK_DIR)/build

openssh-ipk: $(OPENSSH_SERVER_IPK) $(OPENSSH_CLIENT_IPK) \
             $(OPENSSH_SFTP_SERVER_IPK) $(OPENSSH_SFTP_CLIENT_IPK) \
	     $(OPENSSH_CLIENT_EX_IPK)

openssh-source: $(DL_DIR)/$(OPENSSH_SOURCE)

openssh-clean: 
	$(MAKE) -C $(OPENSSH_DIR) clean

openssh-dirclean: 
	rm -rf $(OPENSSH_DIR)

