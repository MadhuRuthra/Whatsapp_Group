const db = require("../db_connect/connect");
const md5 = require("md5")
const main = require('../logger')
require("dotenv").config();
const dynamic_db = require("../db_connect/dynamic_connect");

//Start function to signup
async function Signup(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data)
    logger_all.info(log_data)

    let user_password = md5(req.body.user_password);
    let parent_id = 1;

    const signup_query = `CALL SignUpProcedure('${req.body.user_type}', '${req.body.user_email}', '${user_password}','${req.body.user_mobile}','${parent_id}','${req.body.user_name}')`;
    logger_all.info("[Select query request] : " + signup_query);
  const sql_stat = await db.query(signup_query);

       const [results] = sql_stat; // Destructure the single result set
       logger_all.info("results" +JSON.stringify(results))

       // Check if the result set contains any rows
       if (results && results.length > 0) {
           const successMessage = results[0].response_msg;
           logger_all.info("[signup] Success" +successMessage);

           return {
               response_code: 1,
               response_status: 200,
               num_of_rows: 1,
               response_msg: successMessage,
           };
       } else {
           logger_all.info(": [signup] Failed - Unknown error occurred.");

           return {
               response_code: 0,
               response_status: 201,
               response_msg: "Error occurred.",
           };
       }
      } catch (err) {
          // Handle other errors
          logger_all.info(": [signup] Failed - " + err.message);
          return {
              response_code: 0,
              response_status: 201,
              response_msg: err.message,
          };
      }
  }
  // End function to signup

module.exports = {
  Signup,
};

