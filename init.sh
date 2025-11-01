#!/bin/bash

set -euo pipefail

# Verify that the files are available
for file in env-example mariadb-env-example traefik-env-example wordpress-env-example; do
		if [[ ! -f "$file" ]]; then
				echo "File '$file' doesn't exists! \n Please download from Git again."
				exit 1;
		fi
done

# Verify that htpasswd command is installed
if ! command -v htpasswd &>/dev/null; then
		echo 'htpaswd command is not installed, you have to install apache2-utils package, please'
		exit 1
fi

# Rename example env files
mv env-example .env
mv mariadb-env-example .mariadb.env
mv traefik-env-example .traefik.env
mv wordpress-env-example .wordpress.env

# Asking user for variables
prompt_var() {
		local var_name="$1"
		local default_value="${2:-}"
		local secret="${3:-false}"

		if [ "$secret" = "true" ]; then
				read -s -p "Set your password for $var_name: " value
				echo
		else
				read -p "Set the value for $var_name: " value
		fi

		echo "${var_name}=${value}"
}

# MariaDB env
echo 'Setting MariaDB...'
{
  prompt_var "MARIADB_DATABASE"
  prompt_var "MARIADB_USER"
  prompt_var "MARIADB_PASSWORD" '' true
  prompt_var "MARIADB_ROOT_PASSWORD" '' true
  echo "ALLOW_EMPTY_PASSWORD=no"
} > .mariadb.env

# Traefik
echo 'Setting Traefik'
{
  prompt_var "TRAEFIK_ACME_EMAIL"
  prompt_var "TRAEFIK_HOSTNAME"
} > .traefik
echo "Setting the password for TRAEFIK_BASIC_AUTH (user: traefikadmin)" 
{
  read -s -p "Please, set a secure password for traefikadmin: " traefik_pass
  echo
  basic_auth=$(htpasswd -nb traefikadmin "$traefik_pass" | sed 's/\\$/\\\\$/g')
  echo "TRAEFIK_BASIC_AUTH='${basic_auth}'"
} >> .traefik.env

# Wordpress
echo 'Setting WordPress...'
{
  prompt_var "WORDPRESS_TABLE_PREFIX"
  prompt_var "WORDPRESS_DATABASE_USER"
  prompt_var "WORDPRESS_DATABASE_PASSWORD" '' true
  prompt_var "WORDPRESS_DATABASE_NAME"
  prompt_var "WORDPRESS_HOSTNAME"
} > .wordpress.env

# .env
echo 'Setting .env'
{
		prompt_var "PROJECT_DOMAIN"
} > .env

# Generate the final .env file
cat .wordpress.env >> .env
cat .traefik.env >> .env
cat .mariadb.env >> .env

echo 'Environment ready! Please, check the values in:'
echo "  - .env"
echo "  - .traefik.env"
echo "  - .mariadb.env"
echo "  - .wordpress.env"
