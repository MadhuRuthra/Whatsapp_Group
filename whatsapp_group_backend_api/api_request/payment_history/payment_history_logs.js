const db = require("../../db_connect/connect");
const md5 = require("md5")
const main = require('../../logger')
require("dotenv").config();

async function Payment_History(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data)
    logger_all.info(log_data)
// Get the current date
const currentDate = new Date();
// Add one month to the current date
currentDate.setMonth(currentDate.getMonth() + 1);
// Format the result as a string (e.g., "yyyy-mm-dd")
const oneMonthLater = currentDate.toISOString().split('T')[0];
// Get the time part (hh:mm:ss) separately
const timePart = currentDate.toTimeString().split(' ')[0];
// Combine the date and time parts
const formattedDateTime = `${oneMonthLater} ${timePart}`;
console.log(formattedDateTime);

    let request_id = req.body.request_id;
    let slt_user_id = req.body.slt_user_id;
    let plan_amount = req.body.plan_amount;
    let plan_master_id = req.body.plan_master_id;
    let plan_comments = req.body.plan_comments;

    const insert_log = `INSERT INTO api_log VALUES(NULL,0,'${req.originalUrl}','${ip_address}','${request_id}','N','-','0000-00-00 00:00:00','Y',CURRENT_TIMESTAMP)`;
    logger_all.info("[insert query request] : " + insert_log);
    const insert_log_result = await db.query(insert_log);
    logger_all.info("[insert query response] : " + JSON.stringify(insert_log_result))

    const check_req_id = `SELECT * FROM api_log WHERE request_id = '${request_id}' AND response_status != 'N' AND log_status='Y'`;
    logger_all.info("[select query request] : " + check_req_id);
    const check_req_id_result = await db.query(check_req_id);
    logger_all.info("[select query response] : " + JSON.stringify(check_req_id_result));

    if (check_req_id_result.length != 0) {
      return {response_code: 0, response_status: 201, response_msg: 'Request already processed' };
    }
    
    const insert_payment = `INSERT INTO payment_history_log VALUES(NULL,${slt_user_id},'${plan_master_id}','${plan_amount}','Y','${plan_comments}','Y',CURRENT_TIMESTAMP)`;
    logger_all.info("[insert query request] : " + insert_payment);
    const insert_payment_result = await db.query(insert_payment);
    logger_all.info("[insert query response] : " + JSON.stringify(insert_payment_result))

    if(!insert_payment_result.insertId){
      return {
        response_code: 0,
        response_status: 201,
        response_msg: "Payment Failure."
      };
    }
    return {
      response_code: 1,
      response_status: 200,
      response_msg: "Success."
    };
  } catch (err) {
    // any error occurres send error response to client
    logger_all.info("[Payment History error] : " + err);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: "Error occurred"
    };
  }
}

module.exports = {
Payment_History
};

