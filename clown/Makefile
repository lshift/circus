# Overridable properties
VERSION=0.1
BUILD=1
BUNDLER_VERSION=1.0.0

# Fixed properties
GEM_CACHE_DIR=~/.bundle/ruby/1.8/cache

# Derived properties
PKG_VERSION=$(VERSION)-$(BUILD)
PKG_NAME=clown_$(PKG_VERSION)
PKG_BUILD_DIR=build/$(PKG_NAME)
BUNDLER_GEM_CACHE=$(GEM_CACHE_DIR)/bundler-$(BUNDLER_VERSION).gem

main:
	true

$(GEM_CACHE_DIR):
	mkdir -p $(GEM_CACHE_DIR)
$(BUNDLER_GEM_CACHE): | $(GEM_CACHE_DIR)
	wget -O $(BUNDLER_GEM_CACHE) http://rubygems.org/downloads/bundler-$(BUNDLER_VERSION).gem
	
install: | $(BUNDLER_GEM_CACHE)
	#ln -s /usr/lib/clown $(SERVICE_DIR)/clown
	cp -r Gemfile Gemfile.lock run run_with_supervise bin lib log vendor $(TARGET_DIR)
	mkdir -p $(ETC_DIR)
	cp config/* $(ETC_DIR)
	mkdir -p $(DBUS_SYSTEM_CONFIG_DIR)
	mkdir -p $(DBUS_SYSTEM_SERVICE_DIR)
	cp com.deployacircus.Clown.conf $(DBUS_SYSTEM_CONFIG_DIR)
	cp com.deployacircus.Clown.service $(DBUS_SYSTEM_SERVICE_DIR)

	# Cache a copy of the bundler
	mkdir unpack
	(cd unpack; tar --touch -xf $(BUNDLER_GEM_CACHE))
	mkdir -p $(TARGET_DIR)/bootstrap/bundler
	tar -C $(TARGET_DIR)/bootstrap/bundler --touch -xzf unpack/data.tar.gz
	
	# Transform the bundler script into something runnable
	echo "#!/usr/bin/env ruby" >/tmp/bundler.script
	echo '$$LOAD_PATH.unshift(File.join(File.dirname(File.expand_path(__FILE__)), "..", "lib"))' >>/tmp/bundler.script
	cat $(TARGET_DIR)/bootstrap/bundler/bin/bundle >>/tmp/bundler.script
	mv /tmp/bundler.script $(TARGET_DIR)/bootstrap/bundler/bin/bundle
	chmod ugo+x $(TARGET_DIR)/bootstrap/bundler/bin/*

	# Cache all of the gems
	# (cd $(TARGET_DIR); bootstrap/bundler/bin/bundle install

package-in-tmp:
	rm -rf /tmp/clown-build
	mkdir -p /tmp/clown-build
	cp -r . /tmp/clown-build/clown
	cp -r ../circus /tmp/clown-build/circus
	make -C /tmp/clown-build/clown package
	mkdir -p build
	cp /tmp/clown-build/clown/build/clown_*.deb /tmp/clown-build/clown/build/clown_*.changes /tmp/clown-build/clown/build/clown_*.tar.gz /tmp/clown-build/clown/build/clown_*.dsc build/
	(cd build; dpkg-scanpackages . /dev/null | gzip -c9 > Packages.gz)

package:
	bundle install
	rm -rf vendor
	ruby '../circus/lib/bundler/gem_cacher.rb'
	rm -rf Gemfile.lock
	bundle install --quiet

	rm -rf build/
	mkdir -p $(PKG_BUILD_DIR)
	cp -r debian $(PKG_BUILD_DIR)
	mv $(PKG_BUILD_DIR)/debian/run $(PKG_BUILD_DIR)/debian/run_with_supervise $(PKG_BUILD_DIR)/debian/log $(PKG_BUILD_DIR)
	mv $(PKG_BUILD_DIR)/debian/com.deployacircus.Clown.conf $(PKG_BUILD_DIR)
	mv $(PKG_BUILD_DIR)/debian/com.deployacircus.Clown.service $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)/usr/lib/clown/
	cp -r Makefile Gemfile Gemfile.lock bin config lib vendor $(PKG_BUILD_DIR)
	
	cd $(PKG_BUILD_DIR); dpkg-buildpackage -rfakeroot -us -uc
	rm -rf $(PKG_BUILD_DIR)
	(cd build; dpkg-scanpackages . /dev/null | gzip -c9 > Packages.gz)

clean:
	rm -rf build
