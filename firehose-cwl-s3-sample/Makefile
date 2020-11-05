#
# usage:
#   make lambda apply
#
#   make clean \
#     && make invoke && sleep 100 \
#     && make sync \
#     && find log/ -type f \
#     | parallel gzcat; echo
#
.PHONY: lambda apply invoke tail ls sync clean

lambda: ./bin/hello ./bin/processor

./bin/hello: ./hello/main.go
	GOOS=linux GOARCH=amd64 go build -o bin/hello ./hello

./bin/processor: ./processor/main.go
	GOOS=linux GOARCH=amd64 go build -o bin/processor ./processor

apply: ./bin/hello ./bin/processor
	terraform apply --auto-approve

prefix := `terraform output prefix`
s3_url := s3://$(prefix)-firehose-dest/
dest_dir := ./log

invoke:
	aws lambda invoke \
		--cli-binary-format raw-in-base64-out \
		--function-name $(prefix)-hello \
		output.json --payload '{"name":"'$(USER)'","body":"{\"a\":1,\"t\":\"err\"}"}'\
		&& cat output.json

tail:
	aws logs tail --follow --since 5m /aws/lambda/$(prefix)-hello

ls:
	aws s3 ls --recursive $(s3_url)

sync:
	aws s3 sync $(s3_url) $(dest_dir)

clean:
	rm -rf bin $(dest_dir)
	aws s3 rm --recursive $(s3_url)


