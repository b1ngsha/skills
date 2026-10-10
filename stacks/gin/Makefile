.PHONY: fmt lint test run

APP := $(notdir $(abspath .))

fmt:
	gofmt -w .

lint:
	golangci-lint run

test:
	go test ./...

run:
	go run ./cmd/$(APP)
