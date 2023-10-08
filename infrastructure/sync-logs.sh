STORAGE_ACCOUNT_NAME=$1
CONTAINER_NAME=$2

echo "PID of this script: $$" >> sync-logs.pid

while true; do
  azcopy login --identity
  azcopy sync /var/lib/docker/containers "https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$CONTAINER_NAME/container_logs/$HOSTNAME" --include-pattern="*.log" | tee -a "sync-logs.log"
  sleep 120
done
