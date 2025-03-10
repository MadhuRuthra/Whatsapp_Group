const express = require("express");
const router = express.Router();

const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const fse = require('fs-extra');
const fs = require('fs');
const env = process.env
const moment = require("moment")

const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware_with_request");

const composeMsgValidation = require("../../validation/send_message_validation");

const main = require('../../logger')
const db = require("../../db_connect/connect");

// api for to send compose_whatsapp_message
router.post("/", validator.body(composeMsgValidation),
    valid_user, async (req, res) => {
        try {


            // get all the req data
            var senders = req.body.sender_numbers;
            var mobiles = req.body.receiver_numbers;
            var api_bearer = req.headers.authorization;
            var whtsap_send = req.body.components;
            var template_id = req.body.template_id;
            var tmpl_name;
            var tmpl_lang;
            var body_variable = req.body.variable_values;

            // declare and initialize all the required variables and array
            var sender_numbers = {};
            var notready_numbers = [];
            var api_url_updated;
            var error_array = [];
            var user_id;
            var store_id;
            var full_short_name;
            var user_master;
            var sender_numbers_array = [];

            logger.info(" [send_msg query parameters] : " + JSON.stringify(req.body));


            const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
            logger_all.info("[Select query request] : " + get_plan);
            logger_all.info("[Select query request] : " + get_plan);
            const get_plan_result = await db.query(get_plan);
            logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

            if (get_plan_result.length > 0) {
                available_message_limit = get_plan_result[0].available_message_limit;
            }

            if (available_message_limit <= 0) {
                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No available credit to Compose.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No available credit to create group.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            } else if (get_plan_result.length == 0) {
                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            } else if (available_message_limit < mobiles.length) {
                logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Available credit not enough.', request_id: req.body.request_id }))

                var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Available credit not enough' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger.silly("[update query request] : " + log_update);
                const log_update_result = await db.query(log_update);
                logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                return res.json({ response_code: 0, response_status: 201, response_msg: 'Available credit not enough.', request_id: req.body.request_id });
            }


            // get the available creidts of the user
            var get_users = `SELECT * FROM user_management WHERE user_id = '${user_id}' AND usr_mgt_status = 'Y'`
            logger_all.info("[select query request] : " + get_users)

            const get_user_details = await db.query(get_users);
            logger_all.info("[select query response] : " + JSON.stringify(get_user_details))

            // get the user_id, user's parent id and user shortname to generate campaign name
            user_id = get_user_details[0].user_id;
            user_name = get_user_id[0].user_name;
            user_short_name = user_name.slice(0, 3);
            user_master = get_user_details[0].parent_id;

            // get the given user's master short name
            logger_all.info("[select query request] : " + `SELECT usr1.user_short_name FROM user_management usr
			LEFT JOIN user_management usr1 on usr.parent_id = usr1.user_id
			WHERE usr.user_short_name = '${user_name}'`)
            const get_user_short_name = await db.query(`SELECT usr1.user_short_name FROM user_management usr
			LEFT JOIN user_management usr1 on usr.parent_id = usr1.user_id
			WHERE usr.user_short_name = '${user_name}'`);
            logger_all.info("[select query response] : " + JSON.stringify(get_user_short_name))

            // if nothing returns set given user's short_name as full_short_name
            if (get_user_short_name.length == 0) {
                full_short_name = user_short_name;
            }
            else {
                // if the given user is primary admin then no master shouldn't be there. so set given user's short_name as full_short_name
                if (user_master == 1 || user_master == '1') {
                    full_short_name = user_short_name;
                }
                // concat the given user's master short_name in given user's short_name
                else {
                    full_short_name = `${get_user_short_name[0].user_short_name}_${user_short_name}`;
                }
            }

            // check if the template is available
            var get_template = `SELECT * FROM message_template tmp
			LEFT JOIN master_language lan ON lan.language_id = tmp.language_id
			WHERE tmp.unique_template_id = '${template_id}' AND tmp.template_status = 'Y'`;
            logger_all.info("[select query request] : " + get_template)
            const check_variable_count = await db.query(get_template);
            logger_all.info("[select query response] : " + JSON.stringify(check_variable_count))

            // if template not available send error response to the client
            if (check_variable_count.length == 0) {
                logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'template not available', request_id: req.body.request_id }))

                var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Template not available' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger.silly("[update query request] : " + log_update);
                const log_update_result = await db.query(log_update);
                logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                return res.json({ response_code: 0, response_status: 201, response_msg: 'template not available', request_id: req.body.request_id });
            }
            // if template available process will be continued
            else {

                // get the template name and language from template id
                tmpl_name = check_variable_count[0].template_name;
                tmpl_lang = check_variable_count[0].language_code;
                //var tmpl_message = JSON.parse(check_variable_count[0].template_message);

                try {
                    // get the template json from db to check the template has media and variables
                    var replced_message = check_variable_count[0].template_message.replace(/(\r\n|\n|\r)/gm, " ");
                    var tmpl_message = JSON.parse(replced_message);
                    // assign 0 and 1  value as 0 to check the media
                    var get_temp_details = [0, 0];

                    // loop the template json to check the template has media
                    for (var t = 0; t < tmpl_message.length; t++) {
                        // check if the template has image if yes set 2nd index value as i
                        if (tmpl_message[t].type.toLowerCase() == 'header' && tmpl_message[t].format.toLowerCase() == 'image') {
                            get_temp_details[2] = 'i';
                            get_temp_details[3] = 0;
                            get_temp_details[4] = 0;
                        }
                        // check if the template has video if yes set 3rd index value as v
                        else if (tmpl_message[t].type.toLowerCase() == 'header' && tmpl_message[t].format.toLowerCase() == 'video') {
                            get_temp_details[2] = 0;
                            get_temp_details[3] = 'v';
                            get_temp_details[4] = 0;
                        }
                        // check if the template has document if yes set 4th index value as d
                        else if (tmpl_message[t].type.toLowerCase() == 'header' && tmpl_message[t].format.toLowerCase() == 'document') {
                            get_temp_details[2] = 0;
                            get_temp_details[3] = 0;
                            get_temp_details[4] = 'd';
                        }
                        // if template doesn't have any media then set 2,3,4 index as 0
                        else {
                            get_temp_details[2] = 0;
                            get_temp_details[3] = 0;
                            get_temp_details[4] = 0;
                        }
                    }

                    if (get_temp_details.length != 0) {

                        // check if 2,3,4 is not 0. If these 3 index values are 0 then no media for this template
                        if (get_temp_details[2] != 0 || get_temp_details[3] != 0 || get_temp_details[4] != 0) {

                            // flag to check the request have media
                            var media_flag = false;

                            // loop the received json have media 
                            for (var p = 0; p < whtsap_send.length; p++) {
                                if (whtsap_send[p]['type'] == 'header' || whtsap_send[p]['type'] == 'HEADER') {
                                    // check the request have image
                                    if (get_temp_details[2] != 0) {
                                        if ((whtsap_send[p]['parameters'][0]['type'] == 'image' || whtsap_send[p]['parameters'][0]['type'] == 'IMAGE') && get_temp_details[2] != 0) {
                                            media_flag = true;
                                        }
                                        else { // Otherwise to send the  response message in 'Image required for this template' to the user
                                            logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Image required for this template', request_id: req.body.request_id }))

                                            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Image required for this template' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger.silly("[update query request] : " + log_update);
                                            const log_update_result = await db.query(log_update);
                                            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                                            return res.json({ response_code: 0, response_status: 201, response_msg: 'Image required for this template', request_id: req.body.request_id });
                                        }
                                    }
                                    // check the request have video
                                    else if (get_temp_details[3] != 0) {

                                        if ((whtsap_send[p]['parameters'][0]['type'] == 'video' || whtsap_send[p]['parameters'][0]['type'] == 'VIDEO') && get_temp_details[3] != 0) {
                                            media_flag = true;
                                        }
                                        else {// Otherwise to send the  response message in 'Video required for this template' to the user
                                            logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Video required for this template', request_id: req.body.request_id }))

                                            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Video required for this template' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger.silly("[update query request] : " + log_update);
                                            const log_update_result = await db.query(log_update);
                                            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                                            return res.json({ response_code: 0, response_status: 201, response_msg: 'Video required for this template', request_id: req.body.request_id });
                                        }
                                    }

                                    // check the request have document
                                    else if (get_temp_details[4] != 0) {
                                        if ((whtsap_send[p]['parameters'][0]['type'] == 'document' || whtsap_send[p]['parameters'][0]['type'] == 'DOCUMENT') && get_temp_details[4] != 0) {
                                            media_flag = true;
                                        }
                                        else {// Otherwise to send the  response message in 'Document required for this template' to the user
                                            logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Document required for this template', request_id: req.body.request_id }))

                                            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Document required for this template' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger.silly("[update query request] : " + log_update);
                                            const log_update_result = await db.query(log_update);
                                            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                                            return res.json({ response_code: 0, response_status: 201, response_msg: 'Document required for this template', request_id: req.body.request_id });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch (e) { // any error occurres send error response to client
                    logger_all.info("[media check error] : " + e)
                }

                // check how many variables the template have
                if (check_variable_count[0].body_variable_count != 0) {
                    if (req.body.variable_values && body_variable.length != 0) {
                        if (check_variable_count[0].body_variable_count == body_variable[0].length && body_variable.length == mobiles.length) {
                        }
                        else {
                            logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Variable value mismatch.', request_id: req.body.request_id }))

                            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Variable value mismatch' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger.silly("[update query request] : " + log_update);
                            const log_update_result = await db.query(log_update);
                            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                            return res.json({ response_code: 0, response_status: 201, response_msg: 'Variable value mismatch.', request_id: req.body.request_id });
                        }
                    }
                    else {
                        logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Variable values required', request_id: req.body.request_id }))

                        var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Variable values required' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger.silly("[update query request] : " + log_update);
                        const log_update_result = await db.query(log_update);
                        logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                        return res.json({ response_code: 0, response_status: 201, response_msg: 'Variable values required', request_id: req.body.request_id });
                    }
                }


                var msg_limit_for_sender = 0;
                // loop all the sender number's to get available credit
                for (var s = 0; s < senders.length; s++) {

                    // get all the sender number's available credit
                    var sender_master = `SELECT * from senderid_master WHERE mobile_no = '${senders[s]}' AND senderid_master_status = 'Y'`;
                    logger_all.info("[select query request] : " + sender_master)
                    const select_details = await db.query(sender_master);
                    logger_all.info("[select query response] : " + JSON.stringify(select_details))

                    // check if the sender number have the template
                    if (select_details.length != 0) {

                        var get_template = `SELECT con.user_id,tmp.template_name,con.available_credit-con.sent_count available_credit FROM message_template tmp LEFT JOIN senderid_master con ON con.sender_master_id  = tmp.sender_master_id LEFT JOIN master_language lan ON lan.language_id = tmp.language_id  WHERE tmp.template_name = '${tmpl_name}' AND tmp.template_status = 'Y' AND con.mobile_no = '${senders[s]}' AND lan.language_code = '${tmpl_lang}'`;
                        logger_all.info("[select query request] : " + get_template )
                        const check_template = await db.query(get_template);
                        logger_all.info("[select query response] : " + JSON.stringify(check_template))

                        // if template not available push the sender number in notready_numbers array.
                        if (check_template.length == 0) {
                            notready_numbers.push({ sender_number: senders[s], reason: 'Template not available for this number.' })

                        }
                        // otherwise process will be continued. Add the available sender_numbers in array
                        else {
                            msg_limit_for_sender = msg_limit_for_sender + check_template[0].available_credit

                            sender_numbers_array.push(senders[s])
                            // sender_numbers[senders[s]] = ({ user_id: check_template[0].user_id, count: check_template[0].available_credit, phone_number_id: select_details[0].phone_number_id, whatsapp_business_acc_id: select_details[0].whatsapp_business_acc_id, bearer_token: select_details[0].bearer_token })
                        }
                    }
                    // if sender_number not available push the sender number in notready_numbers array.
                    else {
                        notready_numbers.push({ sender_number: senders[s], reason: 'Number not available.' })
                    }

                }

                // if the sender_number json have no values then no sender number available. then send error response to the client.
                if (Object.keys(sender_numbers).length == 0) {
                    logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'No sender available', data: notready_numbers, request_id: req.body.request_id }))

                    var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No sender available' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger.silly("[update query request] : " + log_update);
                    const log_update_result = await db.query(log_update);
                    logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                    res.json({ response_code: 0, response_status: 201, response_msg: 'No sender available', data: notready_numbers, request_id: req.body.request_id });
                }
                else {

                    // check the limits and messages count
                    // if (msg_limit_for_sender < mobiles.length) {
                    //     logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 0, response_status: 201, response_msg: 'Not sufficient credits.', request_id: req.body.request_id }))

                    //     var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Not sufficient credits' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    //     logger.silly("[update query request] : " + log_update);
                    //     const log_update_result = await db.query(log_update);
                    //     logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                    //     return res.json({ response_code: 0, response_status: 201, response_msg: 'Not sufficient credits.', request_id: req.body.request_id });
                    // }
                    // get today's julian date to generate compose_unique_name
                    Date.prototype.julianDate = function () {
                        var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                            i = 3 - j.length;
                        while (i-- > 0) j = 0 + j;
                        return j
                    };

                    // declare db name and tables_name
                    var db_name = `whatsapp_messenger_${user_id}`;
                    var table_names = [`compose_whatsapp_tmpl_${user_id}`, `compose_whatsapp_status_tmpl_${user_id}`, `whatsapp_text_${user_id}`];
                    var compose_whatsapp_id;
                    var compose_unique_name;

                    logger_all.info("[select query request] : " + `SELECT compose_whatsapp_id from ${table_names[0]} ORDER BY compose_whatsapp_id desc limit 1`)
                    const select_compose_id = await dynamic_db.query(`SELECT compose_whatsapp_id from ${table_names[0]} ORDER BY compose_whatsapp_id desc limit 1`, null, `${db_name}`);
                    logger_all.info("[select query response] : " + JSON.stringify(select_compose_id))
                    // To select the select_compose_id length is '0' to create the compose unique name 
                    if (select_compose_id.length == 0) {
                        compose_unique_name = `ca_${full_short_name}_${new Date().julianDate()}_1`;
                    }

                    else { // Otherwise to get the select_compose_id using
                        compose_unique_name = `ca_${full_short_name}_${new Date().julianDate()}_${select_compose_id[0].compose_whatsapp_id + 1}`;
                    }
                    // To insert the tempalate details.
                    logger_all.info("[insert query request] : " + `INSERT INTO ${table_names[0]} VALUES(NULL,${user_id},${store_id},1,'${mobiles}','${senders}','${tmpl_name}','TEXT',${mobiles.length},1,${mobiles.length},'${compose_unique_name}','Y',CURRENT_TIMESTAMP)`)
                    const insert_compose = await dynamic_db.query(`INSERT INTO ${table_names[0]} VALUES(NULL,${user_id},${store_id},1,'${mobiles}','${senders}','${tmpl_name}','TEXT',${mobiles.length},1,${mobiles.length},'${compose_unique_name}','Y',CURRENT_TIMESTAMP)`, null, `${db_name}`);
                    logger_all.info("[insert query response] : " + JSON.stringify(insert_compose))
                    // To get the compose insert id.
                    compose_whatsapp_id = insert_compose.insertId;
                    // to the response message is send to client initiated 
                    logger.info("[API RESPONSE] " + JSON.stringify({ response_code: 1, response_status: 200, response_msg: 'Initiated', compose_id: compose_unique_name, available_senders: sender_numbers_array, not_available_senders: notready_numbers, request_id: req.body.request_id }))

                    var log_update = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger.silly("[update query request] : " + log_update);
                    const log_update_result = await db.query(log_update);
                    logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                    res.json({ response_code: 1, response_status: 200, response_msg: 'Initiated', compose_id: compose_unique_name, available_senders: sender_numbers_array, not_available_senders: notready_numbers, request_id: req.body.request_id });

                    var insert_count = 1;
                    var insert_query = `INSERT INTO ${table_names[1]} VALUES`;
                    // the looping condition is true to continue the process and insert the table names and values
                    for (var i = 0; i < mobiles.length; i++) {

                        insert_query = insert_query + "" + `(NULL,${compose_whatsapp_id},NULL,'${mobiles[i]}','-','Y',CURRENT_TIMESTAMP,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),`;

                        if (insert_count == 1000) {
                            insert_query = insert_query.substring(0, insert_query.length - 1)

                            logger_all.info(insert_query);
                            const insert_mobile_numbers = await dynamic_db.query(insert_query, null, `${db_name}`);
                            logger_all.info(" [insert query response] : " + JSON.stringify(insert_mobile_numbers))

                            insert_count = 0;
                            insert_query = `INSERT INTO ${table_names[1]} VALUES`;

                        }
                        insert_count = insert_count + 1;

                    }
                    insert_query = insert_query.substring(0, insert_query.length - 1)
                    // to connect the db and insert insert_mobile_numbers details and to update the  available_messages is available_messages - to the mobile number length
                    logger_all.info(insert_query);
                    const insert_mobile_numbers = await dynamic_db.query(insert_query, null, `${db_name}`);
                    logger_all.info(" [insert query response] : " + JSON.stringify(insert_mobile_numbers))

                    // looping condition is true continue the process .to check the mobiles length is validated.
                    for (var m = 0; m < mobiles.length; m) {
                        // loop with in loop key var using in sender numbers 
                        for (var key in sender_numbers) {
                            if (sender_numbers[key].count >= 1) {


                                var data;
                                // body variable condition
                                if (body_variable) {
                                    // looping condition is true continue the process .to check the whtsap_send length is validated.
                                    for (var p = 0; p < whtsap_send.length; p++) {
                                        if (whtsap_send[p]['type'] == 'body' || whtsap_send[p]['type'] == 'BODY') {
                                            whtsap_send.splice(p, 1); // 2nd parameter means remove one item only
                                        }
                                    }
                                    var variable_array = [];
                                    // looping condition is true continue the process .to check the body_variable length is validated.
                                    for (var p = 0; p < body_variable[m].length; p++) {
                                        variable_array.push({
                                            "type": "text",
                                            "text": body_variable[m][p]
                                        })
                                    }

                                    whtsap_send.push({
                                        "type": "body",
                                        "parameters": variable_array
                                    })

                                }
                                // whtsap_send length is not equal to '0' to get the valaue in data
                                if (whtsap_send.length != 0) {
                                    data = JSON.stringify({
                                        "messaging_product": "whatsapp",
                                        "to": mobiles[m].toString(),
                                        "type": "template",
                                        "template": {
                                            "name": tmpl_name,
                                            "language": {
                                                "code": tmpl_lang
                                            },
                                            "components": whtsap_send
                                        }
                                    });
                                }

                                else {
                                    // otherwise to get the details in the value name is data
                                    data = JSON.stringify({
                                        "messaging_product": "whatsapp",
                                        "to": mobiles[m].toString(),
                                        "type": "template",
                                        "template": {
                                            "name": tmpl_name,
                                            "language": {
                                                "code": tmpl_lang
                                            }
                                        }
                                    });
                                }
                                // send msg value initiated .
                                // var send_msg = {
                                //     method: 'post',
                                //     url: api_url_updated,
                                //     headers: {
                                //         'Authorization': 'Bearer ' + sender_numbers[key].bearer_token,
                                //         'Content-Type': 'application/json'
                                //     },
                                //     data: data
                                // // };

                                // logger_all.info("[send msg request] : " + JSON.stringify(send_msg))
                                // // send_msg function 
                                // await axios(send_msg)
                                //     .then(async function (response) {

                                        if (response.status == 200) {
                                            // to update the response_date,response_status,response_message,response_id in the particular table
                                            logger_all.info("[update query request] : " + `UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'SUCCESS',response_id = '${response.data.messages[0].id}',comments='${key}' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`)
                                            const update_success = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'S',response_message = 'SUCCESS',response_id = '${response.data.messages[0].id}',comments='${key}' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_success))
                                            // to update the whatsapp_config in the sent_count
                                            logger_all.info("[update query request] : " + `UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${key}'`)
                                            const update_count = await db.query(`UPDATE whatsapp_config SET sent_count = sent_count+1 WHERE concat(country_code, mobile_no) = '${key}'`);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_count))

                                            logger_all.info("[update query request] : " + `UPDATE message_limit SET available_messages = available_messages - 1 WHERE user_id ='${sender_numbers[key].user_id}'`)
                                            const update_limit = await db.query(`UPDATE message_limit SET available_messages = available_messages - 1 WHERE user_id ='${sender_numbers[key].user_id}'`);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_limit))

                                            sender_numbers[key].count = sender_numbers[key].count - 1;

                                        }
                                        else {
                                            // to update the response_date,response_status,response_message,response_id in the particular table
                                            logger_all.info("[update query request] : " + `UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'FAILED' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`)
                                            const update_fail = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = 'FAILED' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_fail))

                                        }

                                        m++;

                                        if (m == mobiles.length) {

                                            var com_status = 'S';
                                            if (error_array.length == 0) {
                                                com_status = 'S';
                                            }
                                            else {
                                                com_status = 'F';
                                            }
                                            // to update the whatsapp_status 'S' or 'F' To set in the table names.
                                            logger_all.info("[update query request] : " + `UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`)
                                            const update_complete = await dynamic_db.query(`UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`, null, `${db_name}`);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_complete))

                                        }

                                        

                                    // })
                                    // any error occurres send error response to client and to update the getting details
                                    // .catch(async function (error) {
                                    //     logger_all.info("[send msg failed response] : " + error);

                                    //     error_array.push(mobiles[m])

                                    //     logger_all.info("[update query request] : " + `UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = '${error.message}' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`)
                                    //     const update_failure = await dynamic_db.query(`UPDATE ${table_names[1]} SET response_date = CURRENT_TIMESTAMP,response_status = 'F',response_message = '${error.message}' WHERE compose_whatsapp_id = ${compose_whatsapp_id} AND mobile_no = '${mobiles[m]}'`, null, `${db_name}`);
                                    //     logger_all.info("[update query response] : " + JSON.stringify(update_failure))

                                    //     m++;

                                    //     if (m == mobiles.length) {
                                    //         var com_status = 'F';
                                    //         // to update the whatsapp_status 'F' To set in the table names.
                                    //         logger_all.info("[update query request] : " + `UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`)
                                    //         const update_complete = await dynamic_db.query(`UPDATE ${table_names[0]} SET whatsapp_status = '${com_status}' WHERE compose_whatsapp_id = ${compose_whatsapp_id}`, null, `${db_name}`);
                                    //         logger_all.info("[update query response] : " + JSON.stringify(update_complete))

                                    //     }
                                    // });
                            }
                            else {
                                // sender_numbers.
                            }

                            if (m == mobiles.length) {
                                break;
                            }
                        }
                    }
                }
            }
        }
        catch (e) {// any error occurres send error response to client
            logger_all.info("[Send msg failed response] : " + e)
        }
    });

module.exports = router;
