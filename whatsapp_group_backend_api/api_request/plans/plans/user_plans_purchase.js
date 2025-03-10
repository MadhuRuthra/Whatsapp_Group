const db = require("../../db_connect/connect");
const main = require('../../logger')
require("dotenv").config();

async function user_plans(req) {
  var logger_all = main.logger_all
  var logger = main.logger
  try {
    var header_json = req.headers;
    let ip_address = header_json['x-forwarded-for'];

    var log_data = "[API REQUEST] " + req.originalUrl + " - " + JSON.stringify(req.body) + " - " + JSON.stringify(req.headers) + " - " + ip_address
    logger.info(log_data)
    logger_all.info(log_data)

    let slt_user_id = req.body.slt_user_id;
    let plan_amount = req.body.plan_amount;
    let plan_master_id = req.body.plan_master_id;
    let plan_comments = req.body.plan_comments;
    let plan_reference_id = req.body.plan_reference_id;
    var plan_expiry_date;
    var user_plans_id;
    var array_plan_matserid = [];
    const currentDateTime = new Date();
    const formattedDate = currentDateTime.toLocaleString('en-US', { timeZone: 'Asia/Kolkata' });
    // Use the ISO format directly
    const isoDate = new Date(formattedDate).toISOString();

    const get_plans = `Select * from plan_master plans WHERE plans.plan_master_id ='${plan_master_id}' and plans.plan_status = 'Y' ORDER BY plans.plan_entry_date`;

    logger_all.info("[insert query request] : " + get_plans);
    const get_plans_result = await db.query(get_plans);
    logger_all.info("[insert query response] : " + JSON.stringify(get_plans_result))

    if (get_plans_result.length > 0) {
      plan_title = get_plans_result[0].plan_title;
      whatsapp_no_max_count = get_plans_result[0].whatsapp_no_max_count;
      group_no_max_count = get_plans_result[0].group_no_max_count;
      message_limit = get_plans_result[0].message_limit;
      annual_monthly = get_plans_result[0].annual_monthly;

      const checkuserplans = `select * from user_plans where user_id = '${slt_user_id}'`;
      logger_all.info("[insert query request] : " + checkuserplans);
      const checkuserplans_result = await db.query(checkuserplans);
      logger_all.info("[insert query response] : " + JSON.stringify(checkuserplans_result))

      if (checkuserplans_result.length > 0) {
        user_plans_id = checkuserplans_result[0].user_plans_id;
        array_plan_matserid.push(checkuserplans_result[0].plan_master_id)

        const checkplans = `select * from user_plans where user_id = '${slt_user_id}' and plan_master_id = '${plan_master_id}'`;
        logger_all.info("[insert query request] : " + checkplans);
        const checkplans_result = await db.query(checkplans);
        logger_all.info("[insert query response] : " + JSON.stringify(checkplans_result))

        if (checkplans_result.length > 0) {
          user_plans_id = checkplans_result[0].user_plans_id;
          plan_expiry_date = checkplans_result[0].plan_expiry_date;
          const renewdatestart = new Date(plan_expiry_date.getTime() - 7 * 24 * 60 * 60 * 1000);
          // Convert date strings to Date objects
          const renewdatestartObj = new Date(renewdatestart);
          const isoDateObj = new Date(isoDate);
          console.log(plan_expiry_date)
          console.log(renewdatestart);
          console.log(isoDateObj)

          if (renewdatestartObj >= isoDateObj) {
            const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Already plan is active.so cannot plan purchased' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger_all.info("[update query request] : " + update_log_exists_2);
            const update_log_exists_2_result = await db.query(update_log_exists_2);
            logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Already plan is active.so cannot plan purchased.' }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return response_json;
          }
          else {
            console.log("RENEW PLAN");
            const get_plan_status = `Select * from user_plans WHERE plan_master_id = '${plan_master_id}' and user_id = '${slt_user_id}'`;

            logger_all.info("[insert query request] : " + get_plan_status);
            const get_plan_status_result = await db.query(get_plan_status);
            logger_all.info("[insert query response] : " + JSON.stringify(get_plan_status_result))

            if (get_plan_status_result.length > 0) {
              var get_payment = `CALL InsertPaymentPlans('${plan_master_id}','${slt_user_id}','${whatsapp_no_max_count}','${group_no_max_count}','${message_limit}','${plan_amount}','${plan_comments}','${user_plans_id}')`;
              logger_all.info("[Select query request] : " + get_payment);
              var get_payment_result = await db.query(get_payment);
              logger_all.info("[Select query response] : " + JSON.stringify(get_payment_result))

              if (get_payment_result[0].length == 0) {
                return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
              }
              else {
                return {
                  response_code: 1, response_status: 200, response_msg: 'Success', payment_history_list: get_payment_result[0]
                };
              }
            } else {
              const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Inactive Plan' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
              logger_all.info("[update query request] : " + update_log_exists_2);
              const update_log_exists_2_result = await db.query(update_log_exists_2);
              logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

              response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Inactive Plan.' }
              logger.info("[API RESPONSE] " + JSON.stringify(response_json))
              logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
              return response_json;
            }

          }
        }
        else if (Array.isArray(array_plan_matserid) && array_plan_matserid.includes(plan_master_id)) {
          const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Already plan is active.so cannot Upgrade' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
          logger_all.info("[update query request] : " + update_log_exists_2);
          const update_log_exists_2_result = await db.query(update_log_exists_2);
          logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

          response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Already plan is active.so cannot Upgrade.' }
          logger.info("[API RESPONSE] " + JSON.stringify(response_json))
          logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
          return response_json;

        } else {
          console.log("UPGRADE PLANS")
          console.log(user_plans_id + "user_plans_id");
          const get_history = `Select * from plans_update WHERE plan_master_id in ('${plan_master_id}') and user_id = '${slt_user_id}' and plan_status in ('Y') ORDER BY plan_entry_date`;

          logger_all.info("[insert query request] : " + get_history);
          const get_history_result = await db.query(get_history);
          logger_all.info("[insert query response] : " + JSON.stringify(get_history_result))

          if (get_history_result.length > 0) {
            const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Only Upgrade Plan is active.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger_all.info("[update query request] : " + update_log_exists_2);
            const update_log_exists_2_result = await db.query(update_log_exists_2);
            logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Only Upgrade Plan is active.' }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return response_json;
          } else {
            var get_payment = `CALL InsertPaymentPlans('${plan_master_id}','${slt_user_id}','${whatsapp_no_max_count}','${group_no_max_count}','${message_limit}','${plan_amount}','${plan_comments}','${user_plans_id}')`;
            logger_all.info("[Select query request] : " + get_payment);
            var get_payment_result = await db.query(get_payment);
            logger_all.info("[Select query response] : " + JSON.stringify(get_payment_result))

            if (get_payment_result[0].length == 0) {
              return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
            }
            else {
              return {
                response_code: 1, response_status: 200, response_msg: 'Success', payment_history_list: get_payment_result[0]
              };
            }

          }
        }
      }
      else {
        console.log("PURCHASE PLANS");

        var get_payment = `CALL Purchase_plans('${slt_user_id}','${plan_master_id}','${whatsapp_no_max_count}','${group_no_max_count}','${message_limit}','${plan_amount}','${plan_comments}','${plan_reference_id}')`;
        logger_all.info("[Select query request] : " + get_payment);
        var get_payment_result = await db.query(get_payment);
        logger_all.info("[Select query response] : " + JSON.stringify(get_payment_result))

        if (get_payment_result[0].length == 0) {
          return { response_code: 0, response_status: 204, response_msg: 'No data available.' };
        }
        else {
          return {
            response_code: 1, response_status: 200, response_msg: 'Success'
          };
        }
      }
    } else {
      const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Invalid Plan' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
      logger_all.info("[update query request] : " + update_log_exists_2);
      const update_log_exists_2_result = await db.query(update_log_exists_2);
      logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

      response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Invalid Plan.' }
      logger.info("[API RESPONSE] " + JSON.stringify(response_json))
      logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
      return response_json;
    }

  } catch (err) {
    // any error occurres send error response to client
    logger_all.info("[User List error] : " + err);
    return {
      response_code: 0,
      response_status: 201,
      response_msg: "Error occurred"
    };
  }
}

module.exports = {
  user_plans,
};