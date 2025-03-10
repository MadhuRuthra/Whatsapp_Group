const db = require("../db_connect/connect");
require("dotenv").config();
const main = require('../logger')

async function logout(req) {
  var logger_all = main.logger_all

  var day = new Date();
  var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();
 var results;

  try {
  
    const logout_sql = `CALL LogoutProcedure('${req.body.user_id}')`;
    logger_all.info("[Select query request] : " + logout_sql);
    const logout_sql_result = await db.query(logout_sql);
    logger_all.info("[Select query response] : " + JSON.stringify(logout_sql_result[0][0]))

    if(logout_sql_result[0][0]){
      return logout_sql_result[0][0];
    }

 }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[Logout Error] : " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  logout
};
