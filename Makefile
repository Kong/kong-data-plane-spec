
.PHONY: all
all: proto-lint

.PHONY: proto-lint
proto-lint:
	buf format -d --exit-code --config buf.yaml
	buf lint --config buf.yaml ./spec/proto

.PHONY: buf-format
buf-format:
	buf format -w --config buf.yaml

