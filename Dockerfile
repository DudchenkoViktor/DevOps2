# Stage 1: Clone and build
FROM alpine:latest AS builder

RUN apk add --no-cache git build-base autoconf automake
WORKDIR /src
RUN git clone https://github.com/DudchenkoViktor/DevOps2.git . && \
    git checkout branchHTTPserver && \
    autoreconf -fi && \
    ./configure && \
    make

# Stage 2: Runtime
FROM alpine:latest

RUN apk add --no-cache libstdc++
COPY --from=builder /src/program /app/
COPY --from=builder /src/opp/ /app/opp/
WORKDIR /app
EXPOSE 8080
CMD ["./program"]
