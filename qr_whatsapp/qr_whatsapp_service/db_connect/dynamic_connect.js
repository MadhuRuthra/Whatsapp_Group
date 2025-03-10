const mysql = require('mysql2/promise');
const env = process.env;

async function query(sql, params, db_name) {
  var db =  { 
    host: env.DB_HOST || 'localhost',
     user: env.DB_USER || 'root',
     password: env.DB_PASSWORD || 'Root@123',
  }
  db['database'] = db_name;

  const pool = mysql.createPool(db);

  const [rows, fields] = await pool.execute(sql, params);
  pool.end()
  return rows;
}

module.exports = {
  query
}
