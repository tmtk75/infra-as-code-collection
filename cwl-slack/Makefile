now := `ruby -e "puts Time.now().to_i*1000"`
events := "timestamp=$(now),message=ERROR: this should be counted"

tail:
	aws logs tail --follow --since 1m $(log_group_name)

seqtoken := 0
log:
	aws logs put-log-events \
		--log-group-name $(LOG_GROUP_NAME) \
		--log-stream-name test1 \
		--log-events $(events) \
		--sequence-token $(seqtoken)
