#!/usr/bin/env bash
# Genera los secretos locales del entorno: .env y garage/garage.toml.
#
# Ninguno de los dos se versiona. Este script los crea desde sus plantillas
# (.env.example y garage/garage.toml.ejemplo) con valores aleatorios.
#
# No pisa nada: si un archivo ya existe, lo deja y avisa. Para rehacerlo,
# borralo primero o corre con --forzar.
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
forzar=0
[ "${1:-}" = "--forzar" ] && forzar=1

clave() { openssl rand -base64 32 | tr -d '\n=' | tr '+/' 'Ab'; }

# ---------------------------------------------------------------- .env
destino_env="$raiz/.env"
if [ -e "$destino_env" ] && [ $forzar -eq 0 ]; then
  echo "  .env ya existe, lo dejo intacto (usa --forzar para rehacerlo)"
else
  [ -e "$destino_env" ] && cp "$destino_env" "$destino_env.respaldo.$(date +%s)"
  # Cada variable vacia de la plantilla se rellena con una clave distinta.
  while IFS= read -r linea; do
    if [[ "$linea" =~ ^([A-Z_]+)=$ ]]; then
      echo "${BASH_REMATCH[1]}=$(clave)"
    else
      echo "$linea"
    fi
  done < "$raiz/.env.example" > "$destino_env"
  chmod 600 "$destino_env"
  echo "  .env generado"
fi

# -------------------------------------------------------- garage.toml
destino_garage="$raiz/garage/garage.toml"
if [ -e "$destino_garage" ] && [ $forzar -eq 0 ]; then
  echo "  garage/garage.toml ya existe, lo dejo intacto (usa --forzar para rehacerlo)"
else
  [ -e "$destino_garage" ] && cp "$destino_garage" "$destino_garage.respaldo.$(date +%s)"
  # rpc_secret tiene que ser hex de 32 bytes exactos; admin_token es libre.
  rpc_secret="$(openssl rand -hex 32)"
  admin_token="$(openssl rand -base64 32)"
  sed -e "s|REEMPLAZAR_RPC_SECRET|$rpc_secret|" \
      -e "s|REEMPLAZAR_ADMIN_TOKEN|$admin_token|" \
      "$raiz/garage/garage.toml.ejemplo" > "$destino_garage"
  chmod 600 "$destino_garage"
  echo "  garage/garage.toml generado"
fi

echo
echo "Listo. Ninguno de los dos archivos se sube a git."
echo "Siguiente: docker compose up -d && ./scripts/preparar-garage.sh"
