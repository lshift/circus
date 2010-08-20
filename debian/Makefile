SIGNING_USER_EMAIL=debian@deployacircus.com
UNOFFICIAL_RELEASE=1

ifeq "$(UNOFFICIAL_RELEASE)" ""
HOME_ARG=HOME=$(GNUPG_PATH)
endif

all: apt_repository
clean:
	rm -rf /tmp/debian

apt_repository: clean
	mkdir -p /tmp/debian/conf
	cp -a distributions /tmp/debian/conf
ifeq "$(UNOFFICIAL_RELEASE)" ""
	echo SignWith: $(SIGNING_USER_EMAIL) >> /tmp/debian/conf/distributions
endif
	for FILE in ../packages/debs/*.changes ; do \
		$(HOME_ARG) reprepro --ignore=wrongdistribution \
			-Vb /tmp/debian include highwire $${FILE} ; \
	done
	#reprepro -Vb /tmp/debian createsymlinks
	rm -rf ../packages/debian
	cp -r /tmp/debian ../packages/debian
