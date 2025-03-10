const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function message_template(req) {
  var logger_all = main.logger_all
  var logger = main.logger

  try {

    var get_template = `SELECT * FROM template_master tmp LEFT JOIN user_management usr ON usr.user_id = tmp.user_id ORDER BY tmp.template_entry_date DESC`;

    logger_all.info("[Select query request] : " + get_template);
    var message_template = await db.query(get_template);
    logger_all.info("[Select query response] : " + JSON.stringify(message_template))

    if(message_template.length == 0){
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else{
      return { response_code: 1, response_status: 200, response_msg: 'Success',num_of_rows:message_template.length,templates:message_template };
    }
   
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[message_template report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
    message_template
};
