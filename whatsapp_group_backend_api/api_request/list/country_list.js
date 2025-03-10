const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function country_list(req) {
  var logger_all = main.logger_all
  var logger = main.logger

  try {

    logger_all.info("[Select query request] : " + `SELECT * from master_countries`);
    var country_list = await db.query(`SELECT * from master_countries`);
    logger_all.info("[Select query response] : " + JSON.stringify(country_list))

    if(country_list.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',country_list:country_list };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[country list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    country_list
};
