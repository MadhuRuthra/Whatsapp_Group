const env = process.env;

const config = {
  db: { 
   host: env.DB_HOST || 'localhost',
    user: env.DB_USER || 'root',
    password: env.DB_PASSWORD || 'Root@123',
    database: env.DB_NAME || 'qr_whatsapp',
  },
  listPerPage: env.LIST_PER_PAGE || 10,
};
  
module.exports = config;
