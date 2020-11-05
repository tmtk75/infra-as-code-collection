# README
A sample for transferring CloudWatch Logs processed with Lambda toward S3 through Firehose created by terraform.
The data source is a Lambda function which is written in golang.
The processsor associated with the firehose is also written in golang.

You need:
- go
- terraform-0.13.x

## Getting Started
Copy `env.auto.tfvars.tmpl` as `env.auto.tfvars` and edit it as your env.

    $ make lambda apply
    ... takes a few munites

    $ make clean invoke && sleep 100  # Wait for firehose flushes its buffer.
    ...

    $ make sync && find log -type f | parallel gzcat
    
