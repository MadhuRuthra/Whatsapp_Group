const { Pool } = require('pg');

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
module.exports.pool = new Pool({
    user: 'postgres',
    host: 'myradon.cn8ujxqgl6pv.ap-south-1.rds.amazonaws.com',
    database: 'postgres',
    password: '$l&Myradon#2023',
    port: 5432, // Change as needed
    ssl: true, // Disable SSL
});
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
