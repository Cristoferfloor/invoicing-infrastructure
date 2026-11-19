// Corre una sola vez, cuando el volumen de Mongo esta vacio.
// El Nucleo es el unico servicio que escribe en la base "facturacion".

db.getSiblingDB('admin').createUser({
  user: 'core',
  pwd: process.env.MONGO_CORE_PASSWORD,
  roles: [{ role: 'readWrite', db: 'invoicing' }],
});

// El Generador RIDE solo lee: arma el PDF a partir del XML autorizado.
db.getSiblingDB('admin').createUser({
  user: 'ride',
  pwd: process.env.MONGO_RIDE_PASSWORD,
  roles: [{ role: 'read', db: 'invoicing' }],
});
