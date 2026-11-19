#!/usr/bin/env bash
# Levanta todo el entorno: bases y los 9 servicios, en orden.
#
#   ./scripts/levantar.sh            arranca todo
#   ./scripts/levantar.sh estado     muestra en que anda cada contenedor
#   ./scripts/levantar.sh bajar      apaga todo (los datos se conservan)
#   ./scripts/levantar.sh logs core  sigue el log de un servicio
#
# Los dos -f no son opcionales: docker-compose.yml define la red y las bases,
# docker-compose.servicios.yml los servicios, y depends_on cruza los dos.
set -euo pipefail

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$raiz"

dc() { docker compose -f docker-compose.yml -f docker-compose.servicios.yml "$@"; }

case "${1:-arrancar}" in
  arrancar)
    [ -f .env ] || { echo "Falta .env. Corre primero: ./scripts/generar-secretos.sh"; exit 1; }
    for s in Core Signer Config SriClient SriQuery RideGenerator ErpConnector; do
      [ -f "../$s/.env" ] || { echo "Falta ../$s/.env"; exit 1; }
    done
    dc up -d --build
    echo
    echo "Listo. Si es la primera vez, falta preparar Garage:"
    echo "  ./scripts/preparar-garage.sh"
    ;;
  estado)
    dc ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
    ;;
  bajar)
    dc down
    ;;
  logs)
    shift
    dc logs -f "$@"
    ;;
  *)
    echo "Uso: $0 [arrancar|estado|bajar|logs <servicio>]"
    exit 1
    ;;
esac
