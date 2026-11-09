.PHONY: image smoke package verify clean

IMAGE ?= dshd-linux-test
SRC_VOL ?= dshd-linux-src

image:
	docker build -f Dockerfile -t $(IMAGE) .

# Builds the current architecture and runs the Xvfb smoke test inside the container.
smoke: image
	docker volume create $(SRC_VOL)
	docker run --rm -it -v "$$PWD:/work" -v $(SRC_VOL):/src $(IMAGE) /work/scripts/build-and-smoke.sh

package: image
	docker volume create $(SRC_VOL)
	docker run --rm -it -v "$$PWD:/work" -v $(SRC_VOL):/src $(IMAGE) /work/scripts/package-formats.sh

verify:
	scripts/verify-artifacts.sh

clean:
	rm -rf dist/*
