
FROM golang:1.13-alpine AS build_base

RUN apk add --no-cache git

# Set the Current Working Directory inside the container
WORKDIR /tmp/flds

# We want to populate the module cache based on the go.{mod,sum} files.
COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

# Unit tests
RUN CGO_ENABLED=0 go test -v

# Build the Go app
RUN go build -o ./out/flds .

# Start fresh from a smaller image
FROM alpine:3.9 
RUN apk add ca-certificates


COPY --from=build_base /tmp/flds/out/flds /app/flds

# This container exposes port 7070 to the outside world
EXPOSE 7070

# Run the binary program produced by `go install`
CMD ["/app/flds"]