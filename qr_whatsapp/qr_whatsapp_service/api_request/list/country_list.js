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
async function constituency_list
(req) {
  var logger_all = main.logger_all
  var parl_id = req.body.parl_id
  try {

    logger_all.info("[Select query request] : " + `SELECT * from master_constituency WHERE parl_id = '${parl_id}' AND consti_status = 'Y'`);
    var consti_list = await db.query(`SELECT * from master_constituency WHERE parl_id = '${parl_id}' AND consti_status = 'Y'`);
    logger_all.info("[Select query response] : " + JSON.stringify(consti_list))

    if(consti_list.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',constituency_list:consti_list };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[constituency list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}


async function parliament_list(req) {
  var logger_all = main.logger_all
  var zone_id = req.body.zone_id;

  try {

    logger_all.info("[Select query request] : " + `SELECT * from master_parliament WHERE zone_id =${zone_id} AND parl_status = 'Y'`);
    var parliament_list = await db.query(`SELECT * from master_parliament WHERE zone_id =${zone_id} AND parl_status = 'Y'`);
    logger_all.info("[Select query response] : " + JSON.stringify(parliament_list))

    if(parliament_list.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',parliament_list:parliament_list };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[parliament_list report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}

module.exports = {
    country_list,
    parliament_list,
    constituency_list
};
