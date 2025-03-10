const mysql = require('mysql2/promise');
const config = require('./config');
const pool = mysql.createPool(config.db);

async function query(sql, params) {

  const [rows, fields] = await pool.execute(sql, params);
  return rows;
}

module.exports = {
  query
}



// const { Pool } = require('pg');
// process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// // PostgreSQL connection options
// const dbConfig = {
//   user: 'postgres',
//   host: 'myradon.cn8ujxqgl6pv.ap-south-1.rds.amazonaws.com',
//   database: 'postgres',
//   password: '$l&Myradon#2023',
//   port: 5432,
//   ssl: true,
// };

// // Create a new pool instance with the connection options
// const pool = new Pool(dbConfig);

// // Define the query function
// async function query(sql, params) {
//   let client;
//   try {
//     // Acquire a client from the pool
//     client = await pool.connect();
//     // Execute the query using the acquired client
//     const result = await client.query(sql, params);
//     // Return the query result
//     return result.rows;
//   } catch (err) {
//     // Handle errors
//     console.error("Error executing query:", err);
//     throw err;
//   } finally {
//     // Release the client back to the pool
//     if (client) {
//       client.release();
//     }
//   }
// }

// module.exports = {
//   query
// };