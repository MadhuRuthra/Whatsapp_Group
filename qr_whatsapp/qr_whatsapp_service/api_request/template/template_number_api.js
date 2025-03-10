/*
API that allows your frontend to communicate with your backend server (Node.js) for processing and retrieving data.
To access a MySQL database with Node.js and can be use it.
This page is used in template function which is used to get a number of template
details.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const db = require("../../db_connect/connect");
const main = require('../../logger')
require('dotenv').config();
// getTemplateNumber - start
async function getTemplateNumber(req) {
    try {
        var logger_all = main.logger_all
        //  Get all the req header data
        const header_token = req.headers['authorization'];

        // get all the req data
        let template_id = req.body.template_id;
        // declare the variables
        let user_id;
        var user_type;
        // declare the array
        var select_template_numbers = [];
        var result = [];
        // query parameters
        logger_all.info("[get template numbers query parameters] : " + JSON.stringify(req.body));
        // To get the User_id
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
        else {// otherwise to get the user details
            user_id = get_user_id[0].user_id;
            user_type = get_user_id[0].user_master_id;
        }
        //if the user type is '4' the process are executed.and to get the select_template_numbers to the available user.
        if (user_type == 4) {
            logger_all.info("[select query request] : " + `SELECT distinct wht.mobile_no,wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and wht.user_id = '${user_id}' and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`)
            select_template_numbers = await db.query(`SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit,wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and wht.user_id = '${user_id}' and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_template_numbers))

        }
        else if (user_type == 3) {//if the user type is '3' the process are executed and to get the userid will act as a parent id.
            logger_all.info("[select query request] : " + `SELECT user_id, user_name FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`)
            const select_usr = await db.query(`SELECT user_id, user_name FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_usr))

            var user_ids = '';
            // if the select_usr length is '0' will be execute.
            if (select_usr.length == 0) {
                // logger_all.info("- No Sender ID available")
                // return { response_code: 0, response_status: 201, response_msg: 'No Sender ID available' };
                user_ids = "," + user_id
            }

            //var user_ids = '';
            // if number of select_usr length  is available then process the will be continued .loop all the get the user ids to act as the user_ids.
            for (var i = 0; i < select_usr.length; i++) {
                user_ids = user_ids.concat(`,${select_usr[i].user_id}`)
            }
            // to get the select_template numbers in the available user.
            logger_all.info("[select query request] : " + `SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and (wht.user_id = '${user_id}' or wht.user_id in (${user_ids.substring(1)})) and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`)
            select_template_numbers = await db.query(`SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit,wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and (wht.user_id = '${user_id}' or wht.user_id in (${user_ids.substring(1)})) and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_template_numbers))

        }
        else if (user_type == 2) { //if the user type is '2' the process are executed.and to get the select_usr to the available user.
            logger_all.info("[select query request] : " + `SELECT user_id FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`)
            const select_usr = await db.query(`SELECT user_id FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_usr))

            var user_ids = '';
            // if the select_usr length is '0' will be execute.
            if (select_usr.length == 0) {
                logger_all.info("- No Sender ID available")
                return { response_code: 0, response_status: 201, response_msg: 'No Sender ID available' };
                user_ids = "," + user_id
            }
            // if number of select_usr length  is available then process the will be continued .loop all the get the user ids to act as the user_ids.
            for (var i = 0; i < select_usr.length; i++) {
                logger_all.info("[select query request] : " + `SELECT user_id FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`)
                const select_usr_id = await db.query(`SELECT user_id FROM user_management where parent_id = '${user_id}' ORDER BY user_master_id, user_id ASC`);
                logger_all.info("[select query response] : " + JSON.stringify(select_usr_id))
                // if number of select_usr length  is available then process the will be continued .loop all the get the user ids to act as the user_ids.
                for (var j = 0; j < select_usr.length; j++) {
                    user_ids = user_ids.concat(`,${select_usr_id[j].user_id}`)
                }
                user_ids = user_ids.concat(`,${select_usr[i].user_id}`)
            }
            // to get the select_template to the available user.
            logger_all.info("[select query request] : " + `SELECT distinct wht.mobile_no,wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and (wht.user_id = '${user_id}' or wht.user_id in (${user_ids.substring(1)})) and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`)
            select_template_numbers = await db.query(`SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and (wht.user_id = '${user_id}' or wht.user_id in (${user_ids.substring(1)})) and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_template_numbers))

        }
        // if the user type is '1' the process are executed and to get the select_template to the template_status is 'Y'.
        else if (user_type == 1) {
            logger_all.info("[select query request] : " + `SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`)
            select_template_numbers = await db.query(`SELECT distinct wht.mobile_no, wht.available_credit- wht.sent_count available_credit, wht.country_code FROM message_template tmp left join whatsapp_config wht on tmp.whatsapp_config_id = wht.whatspp_config_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' and wht.whatspp_config_status = 'Y' and wht.is_qr_code = 'N' and template_status = 'Y' ORDER BY wht.mobile_no ASC`);
            logger_all.info("[select query response] : " + JSON.stringify(select_template_numbers))

        }
        /* for (var k = 0; k < select_template_numbers.length; k++) {
            result.push(`${select_template_numbers[k].country_code}${select_template_numbers[k].mobile_no}`)
        } */
        // to return the success message 
        return { response_code: 1, response_status: 200, response_msg: 'Success', num_of_rows: select_template_numbers.length, data: select_template_numbers };

    }
    catch (e) {// any error occurres send error response to client
        logger_all.info("[get template numbers failed response] : " + e)
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
    }
}
// getTemplateNumber - end

// PgetTemplateNumber - start
async function PgetTemplateNumber(req) {
    try {
        var logger_all = main.logger_all
        // Get all the req data
        let template_id = req.body.template_id;
        var user_id = req.body.user_id;
        // declare the variables

        // declare the array
        var select_template_numbers = [];
        // query parameters
        logger_all.info("[get template numbers query parameters] : " + JSON.stringify(req.body));


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


        var get_sender_ids = `SELECT distinct wht.sender_master_id, wht.user_id, wht.mobile_no
        FROM template_master tmp left join senderid_master wht on tmp.sender_master_id = wht.sender_master_id left join master_language lng on lng.language_id = tmp.language_id where tmp.unique_template_id = '${template_id}' ORDER BY wht.mobile_no ASC`;
    }else{

    }
            logger_all.info("[select query request] : " + get_sender_ids)
            select_template_numbers = await db.query(get_sender_ids);
            logger_all.info("[select query response] : " + JSON.stringify(select_template_numbers))

        // }
        // to return the success message 
        return { response_code: 1, response_status: 200, response_msg: 'Success', data: select_template_numbers };

    }
    catch (e) {// any error occurres send error response to client
        logger_all.info("[get template numbers failed response] : " + e)
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
    }
}
// PgetTemplateNumber - end

// getVariableCount - start
async function getVariableCount(req) {
    try {
        var logger_all = main.logger_all
        //  Get all the req header data
        const header_token = req.headers['authorization'];

        // Get all the req data
        let template_name = req.body.template_name;
        let template_lang = req.body.template_lang;
        // query parameters
        logger_all.info("[get template variable count query parameters] : " + JSON.stringify(req.body));
        // To get the User_id
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
        else { // otherwise to get the user details
            user_id = get_user_id[0].user_id;
            user_master_id = get_user_id[0].user_master_id;
        }
        // to check template_name ,template_status = 'Y',language_code to select_variable_count 
        logger_all.info("[select query request] : " + `SELECT tmp.body_variable_count FROM message_template tmp
        LEFT JOIN master_language lan ON lan.language_id = tmp.language_id
        WHERE tmp.template_name = '${template_name}' AND tmp.template_status = 'Y' AND lan.language_code = '${template_lang}'`)
        const select_variable_count = await db.query(`SELECT tmp.body_variable_count FROM message_template tmp
        LEFT JOIN master_language lan ON lan.language_id = tmp.language_id
        WHERE tmp.template_name = '${template_name}' AND tmp.template_status = 'Y' AND lan.language_code = '${template_lang}'`);
        logger_all.info("[select query response] : " + JSON.stringify(select_variable_count))
        //if the select_variable_count length is '0' to send the 'Template not available' in the response message.
        if (select_variable_count.length == 0) {
            return { response_code: 0, response_status: 201, response_msg: 'Template not available' };
        }
        else { // otherwise to send the success message, select_variable_count,body_variable_count
            return { response_code: 1, response_status: 200, response_msg: 'Success', variable_count: select_variable_count[0].body_variable_count };
        }
    }
    catch (e) { // any error occurres send error response to client
        logger_all.info("[get template variable count failed response] : " + e)
        return { response_code: 0, response_status: 201, response_msg: 'Error Occurred ' };
    }
}
// getVariableCount - end

// using for module exporting
module.exports = {
    getTemplateNumber,
    PgetTemplateNumber,
    getVariableCount
};
