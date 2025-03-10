/*
API that allows your frontend to communicate with your backend server (Node.js) for processing and retrieving data.
To access a MySQL database with Node.js and can be use it.
This page is used in template function which is used to get a template
details.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const db = require("../../db_connect/connect");
const main = require('../../logger')
require('dotenv').config();
// getTemplate - start
async function getTemplate(req) {
  try {
    var logger_all = main.logger_all

    // get all the req data
    var select_template = [];
    var user_id = req.body.user_id;
    var user_master_id = req.body.user_master_id;
    var get_template;
    // query parameters
    logger_all.info("[get template query parameters] : " + JSON.stringify(req.body));

    // get the given user's master short name 
    var get_user_details = `SELECT * FROM user_management WHERE user_id = '${user_id}' AND usr_mgt_status = 'Y'`;
    logger_all.info("[select query request] : " + get_user_details)
    const get_user_details_result = await db.query(get_user_details);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_details_result))

    if (get_user_details_result.length > 0) {
      user_master_id = get_user_details_result[0].user_master_id;
      user_name = get_user_details_result[0].user_name;
    }
    if (user_master_id == 1) {
      get_template = `SELECT * FROM template_master tmp LEFT JOIN master_language lang on lang.language_id = tmp.language_id where tmp.template_status = 'Y' ORDER BY tmp.template_entry_date ASC;`;
    } else {
      get_template = `SELECT * FROM template_master tmp LEFT JOIN master_language lang on lang.language_id = tmp.language_id where tmp.template_status = 'Y'  and tmp.user_id = '${user_id}' ORDER BY tmp.template_entry_date ASC`
    }
    logger_all.info("[select query request] : " + get_template)
    select_template = await db.query(get_template);
    logger_all.info("[select query response] : " + JSON.stringify(select_template))

    // to return the success message 
    return { response_code: 1, response_status: 200, response_msg: 'Success ', num_of_rows: select_template.length, templates: select_template };
  }
  catch (e) { // any error occurres send error response to client
    logger_all.info("[get template failed response] : " + e)
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
  }
}
// getTemplate - end

// using for module exporting
module.exports = {
  getTemplate,
};