const db = require("../../db_connect/connect");
require("dotenv").config();
const main = require('../../logger');
// AvailableCreditsList- start
async function Rppayment_user__id(req) {
        var logger_all = main.logger_all
        var logger = main.logger
        try {

                // get all the req data
                var user_id = req.body.user_id;

                // query parameters
                logger_all.info("[Rppayment_usrsmscrd_id query parameters] : " + JSON.stringify(req.body));
                // get_available_message to execute this query
                var get_userplan = `SELECT user_plans_id,plan_amount FROM user_plans where user_id = '${user_id}' order by user_plans_id desc limit 1`;

                logger_all.info("[select query request] : " + get_userplan);
                const Rppayment_usrsmscrd_id = await db.query(get_userplan);
                logger_all.info("[select query response] : " + JSON.stringify(Rppayment_usrsmscrd_id));

                // if the get_available_message length is not available to send the no available data.otherwise it will be return the get_available_message details.
                if (Rppayment_usrsmscrd_id.length == 0) {
                        return { response_code: 1, response_status: 204, response_msg: 'No data available' };
                }
                else {
                        return { response_code: 1, response_status: 200, num_of_rows: Rppayment_usrsmscrd_id.length, response_msg: 'Success', report: Rppayment_usrsmscrd_id };
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
        Rppayment_user__id,
}