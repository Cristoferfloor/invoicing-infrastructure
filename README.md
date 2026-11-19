# invoicing-infrastructure

Infraestructura compartida de la facturación electrónica V2: la red de Docker y
las bases que usan todos los servicios.

- **MongoDB** — el proceso de los comprobantes (replica set de un nodo, porque
  sin replica set no hay transacciones).
- **Postgres** — configuración y certificados del firmador, en dos bases con
  dueño distinto.
- **Garage** — almacén de objetos S3-compatible, para archivar los XML firmados
  viejos y no dejarlos creciendo en Mongo.
- **Filestash** — explorador web para revisar lo que hay dentro de Garage.

## Arranque desde cero

Esto se levanta **primero**: crea la red `pac-invoicing-v2` que el resto espera.

```bash
./scripts/generar-secretos.sh   # crea .env y garage/garage.toml con claves nuevas
docker compose up -d
./scripts/preparar-garage.sh    # layout, bucket y llave S3 del RIDE
```

El último paso imprime las credenciales S3 que hay que copiar al `.env` de
[invoicing-ride-generator](https://github.com/Cristoferfloor/invoicing-ride-generator)
(`ARCHIVE_S3_KEY_ID` y `ARCHIVE_S3_SECRET`). **El secreto no se puede volver a
consultar**, así que hay que guardarlo en ese momento.

Los puertos quedan en `127.0.0.1`: nada se expone fuera del equipo.

## Secretos

Dos archivos llevan credenciales y **ninguno se versiona**:

| Archivo | Qué lleva | Plantilla |
|---|---|---|
| `.env` | contraseñas de Mongo y Postgres | `.env.example` |
| `garage/garage.toml` | `rpc_secret` y `admin_token` de Garage | `garage/garage.toml.ejemplo` |

`scripts/generar-secretos.sh` los crea desde sus plantillas con valores
aleatorios. No pisa nada: si el archivo ya existe lo deja y avisa; con
`--forzar` lo rehace, dejando antes una copia de respaldo.

Las contraseñas de Mongo y Postgres solo se aplican **la primera vez**, cuando
el volumen está vacío: los scripts de `mongo/` y `postgres/` corren una sola
vez. Cambiarlas después exige entrar a la base, o borrar el volumen y empezar
de nuevo.

## Scripts

- **`scripts/generar-secretos.sh`** — genera `.env` y `garage/garage.toml`.
- **`scripts/preparar-garage.sh [bucket] [llave]`** — aplica el layout del nodo,
  crea el bucket (`comprobantes-archivados` por defecto) y una llave S3
  (`ride-generator`) con permiso de lectura y escritura sobre él. Es idempotente:
  se puede volver a correr sin romper nada.
