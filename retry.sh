#!/bin/bash

# 승인된 Terraform plan을 제한된 횟수만큼 재시도합니다.
# 먼저 실행: terraform plan -out=llm.tfplan

set -u

PLAN_FILE="${1:-llm.tfplan}"
INTERVAL="${RETRY_INTERVAL_SECONDS:-60}"
MAX_ATTEMPTS="${RETRY_MAX_ATTEMPTS:-20}"
ATTEMPT=1

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "오류: plan 파일을 찾을 수 없습니다: $PLAN_FILE" >&2
  echo "먼저 terraform plan -out=$PLAN_FILE 을 실행하고 내용을 검토하세요." >&2
  exit 2
fi

if ! [[ "$INTERVAL" =~ ^[1-9][0-9]*$ && "$MAX_ATTEMPTS" =~ ^[1-9][0-9]*$ ]]; then
  echo "오류: RETRY_INTERVAL_SECONDS와 RETRY_MAX_ATTEMPTS는 양의 정수여야 합니다." >&2
  exit 2
fi

echo "terraform apply 재시도 시작 (plan=$PLAN_FILE, 최대 ${MAX_ATTEMPTS}회, 간격 ${INTERVAL}초)"

while [[ "$ATTEMPT" -le "$MAX_ATTEMPTS" ]]; do
  echo ""
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${ATTEMPT}번째 시도..."

  if terraform apply "$PLAN_FILE"; then
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] terraform apply 성공. 재시도를 종료합니다."
    exit 0
  fi

  if [[ "$ATTEMPT" -eq "$MAX_ATTEMPTS" ]]; then
    break
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] 실패. ${INTERVAL}초 후 재시도합니다."
  ATTEMPT=$((ATTEMPT + 1))
  sleep "$INTERVAL"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 최대 재시도 횟수를 초과했습니다." >&2
exit 1
