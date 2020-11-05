package main

import (
	"context"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	Name string `json:"name"`
	Body string `json:"body"`
}

func HandleRequest(ctx context.Context, event MyEvent) (string, error) {
	log.Printf("hello, %v", event.Name)
	log.Printf("%v", event.Body)
	return fmt.Sprintf("Hello %s!!!", event.Name), nil
}

func main() {
	lambda.Start(HandleRequest)
}
