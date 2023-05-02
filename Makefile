SHELL := /bin/bash

clean:
	rm -rf build

build: clean
	. ./gitops-scripts/utils.sh && build_manifests

validate: build
	. ./gitops-scripts/utils.sh && validate_manifests

FROM=origin/main
TO=HEAD
diff:
	. ./gitops-scripts/utils.sh && diff_manifests $(FROM) $(TO)
