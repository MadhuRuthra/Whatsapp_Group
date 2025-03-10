/*
API that allows your frontend to communicate with your backend server (Node.js) for processing and retrieving data.
To access a MySQL database with Node.js and can be use it.
This page is used in delete template function which is used to delete a template.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const db = require("../../db_connect/connect");
const main = require('../../logger')
require('dotenv').config();
// deleteTemplate - start
async function deleteTemplate(req) {

  try {
    var logger_all = main.logger_all
    //  Get all the req header data
    const header_token = req.headers['authorization'];

    // get all the req data
    let template_id = req.body.template_id;
    // query parameters
    logger_all.info("[deleteTemplate query parameters] : " + JSON.stringify(req.body));
    // To get the User_id
    logger_all.info("[select query request] : " + `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `);
    var get_user = `SELECT * FROM user_management where bearer_token = '${header_token}' AND usr_mgt_status = 'Y' `;
    if (req.body.user_id) {
      get_user = get_user + `and user_id = '${req.body.user_id}' `;
    }
    logger_all.info("[select query request] : " + get_user);
    const get_user_id = await db.query(get_user);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_id));
    // If get_user not available send error response to client in ivalid token
    if (get_user_id.length == 0) {
      logger_all.info("Invalid Token")
      return { response_code: 0, response_status: 201, response_msg: 'Invalid Token' };
    }
    else {   // otherwise to get the user details
      user_id = get_user_id[0].user_id;
    }
    // to check the unique_template_id from the message_template
    logger_all.info("[select query request] : " + `SELECT * from message_template WHERE unique_template_id = '${template_id}'`)
    const select_template = await db.query(`SELECT * from message_template WHERE unique_template_id = '${template_id}'`);
    logger_all.info("[select query response] : " + JSON.stringify(select_template))
    // if the select_template length is '0' to send the Template not found response message.
    if (select_template.length == 0) {
      return { response_code: 0, response_status: 201, response_msg: 'Template not found.' };
    }
    else { // otherwise process will be continued to update the message_template table in template_status 'D'
      logger_all.info("[update query request] : " + `UPDATE message_template SET template_status = 'D' WHERE unique_template_id ='${template_id}'`)
      const delete_template = await db.query(`UPDATE message_template SET template_status = 'D' WHERE unique_template_id ='${template_id}'`);
      logger_all.info("[update query response] : " + JSON.stringify(delete_template))
      // to return the response message in 'Template deleted successfully'.
      return { response_code: 1, response_status: 200, response_msg: 'Template deleted successfully.' };

    }
  }
  catch (e) {// any error occurres send error response to client
    logger_all.info("[delete template failed response] : " + e)
    return { response_code: 0, response_status: 201, response_msg: 'Error occurred while delete template' };

  }
}
// deleteTemplate - end
// using for module exporting
module.exports = {
  deleteTemplate,
};

