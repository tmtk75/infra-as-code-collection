package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/base64"
	"encoding/json"
	"io/ioutil"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
)

type S3object struct {
	RecordId string `json:"recordId"`
	Result   string `json:"result"`
	Data     string `json:"data"`
}

type MyEvent struct {
	Records []struct {
		RecordId                    string `json:"recordId"`
		Data                        string `json:"data"`
		ApproximateArrivalTimestamp int64  `json:"approximateArrivalTimestamp`
	} `json:"records"`
}

type Payload struct {
	MessageType         string
	Owner               string
	LogGroup            string
	LogStream           string
	SubscriptionFilters []string
	LogEvents           []struct {
		Id        string
		Timestamp int64
		Message   string
	}
}

func HandleRequest(ctx context.Context, event MyEvent) (interface{}, error) {
	out := make([]S3object, len(event.Records))
	for i, r := range event.Records {
		log.Printf("recordId: %v", r.RecordId)

		bin, err := base64.StdEncoding.DecodeString(r.Data)
		if err != nil {
			log.Fatalf("%v", err)
		}
		rd, err := gzip.NewReader(bytes.NewBuffer(bin))
		if err != nil {
			log.Fatalf("%v", err)
		}
		aa, err := ioutil.ReadAll(rd)
		if err != nil {
			log.Fatalf("%v", err)
		}

		var p Payload
		if err := json.Unmarshal(aa, &p); err != nil {
			log.Fatalf("%v", err)
		}

		s := ""
		for _, e := range p.LogEvents {
			s += e.Message
		}

		a := S3object{RecordId: r.RecordId}
		a.Result = "Ok"
		a.Data = base64.StdEncoding.EncodeToString([]byte("---> processed\n" + s + "\n<--- processed\n"))
		out[i] = a
	}
	return struct {
		Records []S3object `json:"records"`
	}{Records: out}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
