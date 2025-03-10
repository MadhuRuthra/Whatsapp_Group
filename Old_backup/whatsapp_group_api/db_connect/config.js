const env = process.env;

const config = {
  db: { 
   host: env.DB_HOST || 'localhost',
    user: env.DB_USER || 'admin',
    password: env.DB_PASSWORD || 'Password@123',
    database: env.DB_NAME || 'whatsapp_group',
  },
  listPerPage: env.LIST_PER_PAGE || 10,
};
  
module.exports = config;
