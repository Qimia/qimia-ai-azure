set -e
set -o allexport
source ".manual-secrets-config"
set +o allexport


put_secret () {
  FIELD_NAME=$1
  FIELD_VALUE=$2
  CONTENT_DEC=$3
  [ ! -z "$FIELD_VALUE" ] && echo "Putting $FIELD_NAME" || return
  az keyvault secret set --name $FIELD_NAME --vault-name "$KEY_VAULT_NAME" --value "$FIELD_VALUE" --content-type "$CONTENT_DEC"
}
echo "Using key vault $KEY_VAULT_NAME"

put_secret "email-password" "$EMAIL_PASSWORD" "The email address password to the address defined in the secret 'email-address'."
put_secret "email-address" "$EMAIL_ADDRESS" "The email address to communicate to the  users regarding activation and email resets etc."
put_secret "email-smtp" "$SMTP_SEND_ADDRESS" "The smtp email send address for the email address defined in the secret 'email-address'."
put_secret "admin-email-address" "$ADMIN_EMAIL_ADDRESS" "Initial Admin user's email address."
put_secret "admin-email-password" "$ADMIN_EMAIL_PASSWORD" "Initial Admin user's email password."

