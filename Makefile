SHELL := /bin/bash
TF := terraform
AWS := aws

.PHONY: init plan apply outputs destroy empty-buckets

init:
	$(TF) init

plan:
	$(TF) plan

apply:
	$(TF) apply -auto-approve

outputs:
	$(TF) output

# Empties all S3 buckets created by this stack (site/logs in eu-west-2, WAF logs in us-east-1)
empty-buckets:
	@set -e; \
	SITE=$$($(TF) output -raw bucket_name 2>/dev/null || true); \
	LOGS=$$($(TF) output -raw logging_bucket_name 2>/dev/null || true); \
	if [[ -n "$$SITE" ]]; then \
		echo "Emptying $$SITE (eu-west-2)"; \
		$(AWS) s3 rm "s3://$$SITE" --recursive --region eu-west-2 || true; \
	fi; \
	if [[ -n "$$LOGS" ]]; then \
		echo "Emptying $$LOGS (eu-west-2)"; \
		$(AWS) s3 rm "s3://$$LOGS" --recursive --region eu-west-2 || true; \
	fi; \
	echo "Emptying waf-logs-412717960006-use1 (us-east-1)"; \
	$(AWS) s3 rm "s3://waf-logs-412717960006-use1" --recursive --region us-east-1 || true

destroy: empty-buckets
	$(TF) destroy -auto-approve