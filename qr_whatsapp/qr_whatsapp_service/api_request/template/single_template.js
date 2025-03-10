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

    // get all the req data
    let template_name = req.body.template_name;

    logger_all.info("[get single template query parameters] : " + JSON.stringify(req.body));

    var get_template = `SELECT * FROM template_master where template_status = 'Y' and template_name = '${template_name}'`;
    logger_all.info("[select query request] : " + get_template)
    const get_user_number = await db.query(get_template);
    logger_all.info("[select query response] : " + JSON.stringify(get_user_number))

    if (get_user_number.length == 0) {
      return { response_code: 0, response_status: 201, response_msg: 'Not available template' };
    }
    else {
      // it will be return the response message and data
      return { response_code: 1, response_status: 200, get_single_template: get_user_number };
    }

  }
  catch (e) { // any error occurres send error response to client
    logger_all.info("[get single template failed response] : " + e)
    return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
  }
}
// getSingleTemplate - end


// using for module exporting
module.exports = {
  getSingleTemplate
};