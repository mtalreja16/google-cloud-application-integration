FROM golang:latest

COPY . /integration-lib

WORKDIR /integration-lib

RUN go build -o main .

CMD ["/integration-lib/main"]