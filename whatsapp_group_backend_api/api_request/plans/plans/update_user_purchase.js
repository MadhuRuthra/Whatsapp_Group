// Import the required packages and libraries
const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
const moment = require('moment');

let currentDate = new Date();
// AvailableCreditsList- start
async function UpdateCreditRaisestatus(req) {
        var logger_all = main.logger_all
        var logger = main.logger
        try {

                var get_payment = `CALL UpdateUserPurchase('${req.body.user_id}','${req.body.user_plans_id}','${req.body.payment_status}','${req.body.plan_comments}','${req.body.user_plan_status}','${req.body.plan_master_id}')`;
                logger_all.info("[Select query request] : " + get_payment);
                var get_payment_result = await db.query(get_payment);
                logger_all.info("[Select query response] : " + JSON.stringify(get_payment_result))

                if (get_payment_result.length == 0) {
                        return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
                }
                else {
                        return {
                                response_code: 1, response_status: 200, response_msg: 'Success'
                        };
                }
        }
        catch (e) {// any error occurres send error response to client
                logger_all.info("[Rppayment_usrsmscrd_id failed response] : " + e)
                return { response_code: 0, response_status: 201, response_msg: 'Error occured' };
        }
}
// AvailableCreditsList - end

// using for module exporting
module.exports = {
        UpdateCreditRaisestatus,
}