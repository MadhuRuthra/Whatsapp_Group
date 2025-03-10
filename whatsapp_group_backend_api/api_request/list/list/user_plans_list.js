const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger')

async function User_Plan_List(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {

    var get_plans = `CALL PricingPlanList('${req.body.user_id}')`;
    logger_all.info("[Select query request] : " + get_plans);
    var get_plans_result = await db.query(get_plans);
    logger_all.info("[Select query response] : " + JSON.stringify(get_plans_result))

    if (get_plans_result[0].length == 0) {
      return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
    }
    else {
      return {
        response_code: 1, response_status: 200, response_msg: 'Success', user_plan_list: get_plans_result[0]
      };
    }
  }

  catch (err) {
    // Failed - call_index_signin Sign in function
    logger_all.info("[User List report] Failed - " + err);
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred.' };
  }
}
module.exports = {
  User_Plan_List
};

