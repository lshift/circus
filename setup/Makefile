squashfs-osx: squashfs4.0/squashfs-tools/mksquashfs

squashfs4.0.tar.gz:
	curl -L http://sourceforge.net/projects/squashfs/files/squashfs/squashfs4.0/squashfs4.0.tar.gz/download > squashfs4.0.tar.gz
squashfs4.0: |squashfs4.0.tar.gz
	tar xzvf squashfs4.0.tar.gz
patching-complete: |squashfs4.0
	patch squashfs4.0/squashfs-tools/mksquashfs.c <mksquashfs.patch
	patch squashfs4.0/squashfs-tools/unsquashfs.c <unsquashfs.patch
	touch patching-complete
squashfs4.0/squashfs-tools/mksquashfs: |patching-complete
	make -C squashfs4.0/squashfs-tools
install: squashfs4.0/squashfs-tools/mksquashfs
	sudo cp squashfs4.0/squashfs-tools/{mksquashfs,unsquashfs} /usr/local/bin

clean:
	rm -rf squashfs4.0
	rm patching-complete
