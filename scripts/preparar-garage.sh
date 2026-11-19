#!/usr/bin/env bash
# Deja Garage listo para usarse: aplica el layout del nodo, crea el bucket de
# los XML archivados y una llave S3 con permiso sobre el.
#
# Corre una sola vez, despues del primer "docker compose up -d". Es idempotente:
# si el layout ya esta aplicado o el bucket ya existe, no rompe.
#
# Al final imprime las credenciales S3 que hay que copiar al .env del
# RideGenerator (ARCHIVE_S3_KEY_ID y ARCHIVE_S3_SECRET).
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$raiz"

bucket="${1:-comprobantes-archivados}"
llave="${2:-ride-generator}"

g() { docker compose exec -T garage /garage "$@"; }

echo "==> Esperando a que Garage responda"
for i in $(seq 1 30); do
  if g status >/dev/null 2>&1; then break; fi
  [ "$i" -eq 30 ] && { echo "Garage no respondio. Esta levantado? docker compose ps"; exit 1; }
  sleep 2
done

echo "==> Layout del nodo"
# En un nodo recien creado el layout esta vacio y hay que asignarle zona y
# capacidad. Si ya tiene rol, no se toca.
#
# No se compara contra el ID del nodo: "garage node id" devuelve la clave larga
# de 64 hex y "layout show" solo imprime el prefijo corto, asi que nunca
# coinciden. Se mira el mensaje que Garage da cuando el layout esta vacio.
if g layout show 2>/dev/null | grep -q 'No nodes currently have a role'; then
  nodo="$(g node id -q 2>/dev/null | cut -d'@' -f1)"
  g layout assign -z local -c 10G "$nodo"
  # Garage versiona el layout: hay que aplicar la version actual + 1. El numero
  # actual sale de "Current cluster layout version: N".
  actual="$(g layout show 2>/dev/null | sed -nE 's/.*[Cc]urrent cluster layout version: ([0-9]+).*/\1/p' | head -1)"
  actual="${actual:-0}"
  g layout apply --version "$((actual + 1))"
  echo "    layout aplicado (version $((actual + 1)))"
else
  echo "    el nodo ya tiene rol asignado, no toco el layout"
fi

echo "==> Bucket '$bucket'"
if g bucket info "$bucket" >/dev/null 2>&1; then
  echo "    ya existe"
else
  g bucket create "$bucket"
  echo "    creado"
fi

echo "==> Llave S3 '$llave'"
if g key info "$llave" >/dev/null 2>&1; then
  echo "    ya existe; no puedo volver a mostrar su secreto."
  echo "    Si lo perdiste: garage key delete $llave  y vuelve a correr esto."
  salida=""
else
  salida="$(g key create "$llave")"
  echo "    creada"
fi

g bucket allow --read --write "$bucket" --key "$llave" >/dev/null
echo "    permisos de lectura y escritura sobre '$bucket'"

if [ -n "$salida" ]; then
  id="$(echo "$salida" | grep -oE 'GK[0-9a-f]+' | head -1)"
  secreto="$(echo "$salida" | grep -iA1 'secret key' | tail -1 | tr -d ' ')"
  cat <<FIN

================================================================
Copia esto al .env del RideGenerator:

ARCHIVE_S3_URL=http://garage:3900
ARCHIVE_S3_KEY_ID=$id
ARCHIVE_S3_SECRET=$secreto

El secreto no se puede volver a consultar. Guardalo ahora.
================================================================
FIN
fi
