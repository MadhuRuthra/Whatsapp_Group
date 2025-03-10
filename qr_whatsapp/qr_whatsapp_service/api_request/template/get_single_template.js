/*
API that allows your frontend to communicate with your backend server (Node.js) for processing and retrieving data.
To access a MySQL database with Node.js and can be use it.
This page is used in template function which is used to get a single template
details.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const db = require("../../db_connect/connect");
const main = require('../../logger')
const env = process.env;
require('dotenv').config();
const api_url = env.API_URL;

var axios = require('axios');
// getSingleTemplate - start
async function getSingleTemplate(req) {
  try {
    var logger_all = main.logger_all
    //  Get all the req header data
    const header_token = req.headers['authorization'];

    // get all the req data
    let template_name = req.body.template_name;
    let template_lang = req.body.template_lang;
    let mobile_number = req.body.mobile_number;
    // query parameters
    logger_all.info("[get single template query parameters] : " + JSON.stringify(req.body));
    // To get the User_id
    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;
    if (req.body.user_id) {
      get_user = get_user + `and user_id = '${req.body.user_id}' `;
    }
    logger_all.info("[select query request] : " + get_user);
    const get_user_id = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_id));

    if (get_user_id.length == 0) { // If get_user not available send error response to client in ivalid token
      logger_all.info("Invalid Token")
      return { response_code: 0, response_status: 201, response_msg: 'Invalid Token' };
    }
    // to check the apikey and usr_mgt_status is 'Y' and mobile no and is_qr_code = 'N' .If the condition is true process are continued.
    logger_all.info("[select query request] : " + `SELECT con.mobile_no, con.bearer_token, con.phone_number_id, con.whatsapp_business_acc_id FROM user_management usr
        LEFT JOIN whatsapp_config con ON con.user_id = usr.user_id where concat(con.country_code, con.mobile_no) = '${mobile_number}' AND con.is_qr_code = 'N'`)
    const get_user_number = await db.query(`SELECT con.mobile_no, con.bearer_token, con.phone_number_id, con.whatsapp_business_acc_id FROM user_management usr
        LEFT JOIN whatsapp_config con ON con.user_id = usr.user_id
        WHERE concat(con.country_code, con.mobile_no) = '${mobile_number}' AND con.is_qr_code = 'N'`);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_number))
    // if the get_user_number length is '0' to send the 'Number not available'.otherwise to get the template details from the facebook api.
    if (get_user_number.length == 0) {
      return { response_code: 0, response_status: 201, response_msg: 'Number not available' };
    }
    else {
      var config = {
        method: 'get',
        url: `${api_url}${get_user_number[0].whatsapp_business_acc_id}/message_templates?name=${template_name}&language=${template_lang}`,
        headers: {
          'Authorization': 'Bearer ' + get_user_number[0].bearer_token
        }
      };

      var response_msg;
      var data;

      await axios(config) //with config to get the success message
        .then(function (response) {

          response_msg = 'Success';
          data = response.data.data;
        })
        .catch(function (error) {
          logger_all.info(error); // any error occurres send error response to client

          response_msg = 'Error occured';
          data = error;
        });
      // it will be return the response message and data
      return { response_code: 1, response_status: 200, response_msg: response_msg, data };
    }

  }
  catch (e) { // any error occurres send error response to client
    logger_all.info("[get single template failed response] : " + e)
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
  }
}
// getSingleTemplate - end

// ApproveRejectTemplate - start
async function ApproveRejectTemplate(req) {
  try {
    var logger_all = main.logger_all

    // get current Date and time
    var day = new Date();
    var today_date = day.getFullYear() + '-' + (day.getMonth() + 1) + '-' + day.getDate();
    var today_time = day.getHours() + ":" + day.getMinutes() + ":" + day.getSeconds();
    var current_date = today_date + ' ' + today_time;

    // get all the req data
    var change_status = req.body.change_status;
    var template_id = req.body.template_id;
    // query parameters
    logger_all.info("[ApproveRejectTemplate query parameters] : " + JSON.stringify(req.body));
    // to check template_id and update the message_template table in template status and approve date.
    logger_all.info("[update query request] : " + `UPDATE message_template SET template_status = '${change_status}', approve_date = '${current_date}' WHERE template_id = ${template_id}`)
    update_template_status = await db.query(`UPDATE message_template SET template_status = '${change_status}', approve_date = '${current_date}' WHERE template_id = ${template_id}`);
    logger_all.info("[update query response] : " + JSON.stringify(update_template_status))
    // if the update_template_status is '0' to send the 'No data available' message
    if (update_template_status.length == 0) {
      return {
        response_code: 1,
        response_status: 204,
        response_msg: 'No data available'
      };
    } else { // otherwise to send the 'Success' in response message.
      return {
        response_code: 1,
        response_status: 200,
        num_of_rows: update_template_status.length,
        response_msg: 'Success'
      };
    }


  } catch (e) { // any error occurres send error response to client
    logger_all.info("[ApproveRejectTemplate failed response] : " + e)
    return {
      response_code: 0,
      response_status: 201,
      response_msg: 'Error occured'
    };
  }
}
// WhatsappSenderID - end
// using for module exporting
module.exports = {
  getSingleTemplate,
  ApproveRejectTemplate
};
