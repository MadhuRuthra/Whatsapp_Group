const express = require("express");
const router = express.Router();
const axios = require('axios');
const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const fse = require('fs-extra');
const fs = require('fs');
const csv = require('csv-parser');
const env = process.env
const mime = require('mime');
const moment = require("moment")
const cron = require('node-cron');

const qr = require('qrcode');
const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;

const media_storage = env.MEDIA_STORAGE;
const whatsapp_link = env.WHATSAPP_LINK;

const CreateCsv = require("./create_csv");

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware_with_request");
const CreateGroupValidation = require("../../validation/create_group_validation");
const CreateCsvValidation = require("../../validation/create_csv_validation");
const SendMessageValidation = require("../../validation/send_message_validation");
const AdminProDeValidation = require("../../validation/admin_prode_validation");
const main = require('../../logger')
const db = require("../../db_connect/connect");
const { log } = require("util");
const OnlyAdminSendMsgValidation = require("../../validation/only_admin_msg_setting_validation");

router.post(
    "/create_csv",
    validator.body(CreateCsvValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await CreateCsv.create_csv(req);
            result['request_id'] = req.body.request_id;

            var update_api_log = "";
            if (result.response_code == 0) {
                update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = '${result.response_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            }
            else {
                update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            }

            logger_all.info("[update query request] : " + update_api_log);
            const update_api_log_result = await db.query(update_api_log);
            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

            logger.info("[API RESPONSE] " + JSON.stringify(result))
            logger_all.info("[API RESPONSE] " + JSON.stringify(result))
            res.json(result);
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/send_message",
    validator.body(SendMessageValidation),
    valid_user,
    async function (req, res, next) {

        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var sender_id = req.body.sender_numbers;
            var template_name = req.body.template_name;
            var image_url = req.body.image_url;
            var video_url = req.body.video_url;
            var function_call = false;
            var user_id = req.body.user_id;
            var sender_master_id, response_json, message_content, template_master_id;
            var grp_id = 0;
            var media_type = [];
            var media_urls = [];
            var group_array = myGroupName.split(",")

            if (template_name == undefined) {
                template_master_id = '-';
            }

            if (image_url) {
                media_urls.push(image_url);
                media_type.push('IMAGE');
            }

            if (video_url) {
                media_urls.push(video_url);
                media_type.push('VIDEO');
            }

            logger.info(" [send_msg query parameters] : " + JSON.stringify(req.body));
            if (user_id != '1') {

                const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                logger_all.info("[Select query request] : " + get_plan);
                const get_plan_result = await db.query(get_plan);
                logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                if (get_plan_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }
            }
            const select_sender_id = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
            logger_all.info(" [select query request] : " + select_sender_id)
            const select_sender_id_status = await db.query(select_sender_id);
            logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id_status))

            if (select_sender_id_status.length == 0) {

                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }
            else {

                user_id = select_sender_id_status[0].user_id;
                sender_master_id = select_sender_id_status[0].sender_master_id;


                // const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                // logger_all.info("[select query request] : " + select_grp)
                // const select_grp_result = await db.query(select_grp);
                // logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

                // if (select_grp_result.length != 0) {
                //     grp_id = select_grp_result[0].group_master_id;
                // }

                if (template_name) {
                    const select_template = `SELECT * FROM template_master WHERE template_name = '${template_name}' AND template_status = 'Y'`
                    logger_all.info("[select query request] : " + select_template)
                    const select_template_result = await db.query(select_template);
                    logger_all.info("[select query response] : " + JSON.stringify(select_template_result))
                    if (select_template_result.length > 0) {
                        template_message = select_template_result[0].template_message;
                        template_master_id = select_template_result[0].template_master_id;
                        const data = JSON.parse(template_message);
                        var replace_msg;
                        data.forEach(item => {
                            const typeValue = item.type;
                            var textValue = item.text;

                            if (textValue.includes("<b>") || textValue.includes("<span>")) {
                                // Assuming textValue contains HTML text
                                replace_msg = textValue.replace(/<\/?b>/g, "*");
                                replace_msg = textValue.replace(/<\/?span>/g, "*");
                                message_content = replace_msg;
                            } else {
                                message_content = textValue;
                            }
                            logger_all.info("Type:", typeValue)
                            logger_all.info("Text:", message_content)
                        });
                    }
                }

                Date.prototype.julianDate = function () {
                    var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                        i = 3 - j.length;
                    while (i-- > 0) j = 0 + j;
                    return j
                };

                var client = new Client({
                    restartOnAuthFail: true,
                    takeoverOnConflict: true,
                    takeoverTimeoutMs: 0,
                    puppeteer: {
                        handleSIGINT: false,
                        args: [
                            '--no-sandbox',
                            '--disable-setuid-sandbox',
                            '--disable-dev-shm-usage',
                            '--disable-accelerated-2d-canvas',
                            '--no-first-run',
                            '--no-zygote',
                            '--disable-gpu'
                        ],
                        executablePath: chrome_path,
                    },
                    authStrategy: new LocalAuth(
                        { clientId: sender_id }
                    )
                }
                );
                // Event: Client is disconnected
                client.on('disconnect', (reason) => {
                    if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                        logger_all.info(`Client logout with reason: ${reason}`)
                        // Perform logout logic here
                    } else {
                        logger_all.info(`Client disconnected with reason: ${reason}`)
                        // Perform other cleanup or disconnection logic here
                    }
                });

                client.initialize();

                client.on('ready', async (data) => {
                    logger_all.info('Client is ready! - ' + sender_id);
                    send_message();
                });

                setTimeout(async function () {
                    if (function_call == false) {
                        logger_all.info(' rescan number - ' + sender_id)
                        if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                            fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

                        }
                        if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                            try {
                                if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')
                                }
                                await client.destroy();

                                client = new Client({
                                    restartOnAuthFail: true,
                                    takeoverOnConflict: true,
                                    takeoverTimeoutMs: 0,
                                    puppeteer: {
                                        handleSIGINT: false,
                                        args: [
                                            '--no-sandbox',
                                            '--disable-setuid-sandbox',
                                            '--disable-dev-shm-usage',
                                            '--disable-accelerated-2d-canvas',
                                            '--no-first-run',
                                            '--no-zygote',
                                            '--disable-gpu'
                                        ],
                                        executablePath: chrome_path,
                                    },
                                    authStrategy: new LocalAuth(
                                        { clientId: sender_id }
                                    )
                                }
                                );
                                // Event: Client is disconnected
                                client.on('disconnect', (reason) => {
                                    if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                        logger_all.info(`Client logout with reason: ${reason}`)
                                        // Perform logout logic here
                                    } else {
                                        logger_all.info(`Client disconnected with reason: ${reason}`)
                                        // Perform other cleanup or disconnection logic here
                                    }
                                });

                                client.initialize();

                                client.on('authenticated', async (data) => {
                                    logger_all.info(" [Client is Log in] : " + JSON.stringify(data));
                                });
                                client.on('ready', async (data) => {
                                    logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                    send_message()
                                });

                                setTimeout(async function () {
                                    if (function_call == false) {
                                        const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                        logger_all.info(" [update query request] : " + update_inactive)
                                        const update_inactive_result = await db.query(update_inactive);
                                        logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                        logger_all.info("[update query request] : " + update_api_log);
                                        const update_api_log_result = await db.query(update_api_log);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                        return res.json(response_json)
                                    }
                                }, waiting_time);
                            } catch (err) {
                                logger_all.info(err)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                        else {
                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    }
                }, waiting_time);

                async function send_message() {
                    logger_all.info(" send_message Function calling")
                    array_receiver_nos = []
                    function_call = true;

                    for (var i = 0; i < group_array.length; i++) {

                        const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_master_id = '${group_array[i]}' AND group_master_status = 'Y'`
                        logger_all.info("[select query request] : " + select_grp)
                        const select_grp_result = await db.query(select_grp);
                        logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

                        // if (select_grp_result.length != 0) {
                        var myGroupName = select_grp_result[0].group_name;
                        // }
                        var grp_id = group_array[i];
                        logger_all.info("@@@@@@@@@@" + grp_id)

                        const select_campaign_id = `SELECT * FROM whatsapp_group_newapi_${user_id}.compose_message_${user_id} ORDER BY compose_message_id DESC limit 1`;
                        logger_all.info("[select query request] : " + select_campaign_id)
                        const select_campaign_id_result = await db.query(select_campaign_id);
                        logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

                        if (select_campaign_id_result.length == 0) {
                            campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
                        }
                        else {

                            let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                            logger_all.info(temp_var[temp_var.length - 1]);
                            let unique_id = parseInt(temp_var[temp_var.length - 1])
                            campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
                        }

                        await client.getChats().then(async (chats) => {
                            try {
                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                // Wait for the client to be ready
                                await new Promise(resolve => setTimeout(resolve, 5000));
                                logger_all.info(" Group name - " + JSON.stringify(myGroup))
                                if (!myGroup) {
                                    // await client.destroy();
                                    // logger_all.info(" Destroy client - " + sender_id)

                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_master_id = '${group_array[i]}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                    // const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    // logger_all.info("[update query request] : " + update_api_log);
                                    // const update_api_log_result = await db.query(update_api_log);
                                    // logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    // response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    // logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    // logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    // return res.json(response_json)
                                    // continue;
                                }
                                else {
                                    // if (grp_id == 0) {
                                    //     const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${myGroupName}','${myGroup.participants.length}','0','${myGroup.participants.length}','N','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL,NULL,'N')`
                                    //     logger_all.info("[insert query request] : " + insert_grp);
                                    //     const insert_grp_result = await db.query(insert_grp);
                                    //     logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                    //     grp_id = insert_grp_result.insertId;
                                    // }

                                    let res_msg, res_code, res_code_status, res_status, insert_msg_content, insert_msg_content_result;
                                    var com_media_lstid = [];

                                    const insert_msg = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_message_${user_id} VALUES(NULL,'${user_id}','${sender_master_id}','${grp_id}',${template_master_id !== undefined ? `'${template_master_id}'` : 'NULL'},'TEXT','${campaign_name}','N',NULL,'N',CURRENT_TIMESTAMP)`
                                    logger_all.info("[insert query request] : " + insert_msg);
                                    var insert_msg_result = await db.query(insert_msg);
                                    logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_result))

                                    for (var mediaurl = 0; mediaurl < media_urls.length; mediaurl++) {
                                        insert_msg_content = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}',${message_content !== undefined ? `'${message_content}'` : 'NULL'},NULL,NULL,NULL,NULL,${media_urls.length !== 0 ? `'${media_urls[mediaurl]}'` : 'NULL'},${media_type.length !== 0 ? `'${media_type[mediaurl]}'` : 'NULL'},NULL,'N',CURRENT_TIMESTAMP)`
                                        logger_all.info("[insert query request] : " + insert_msg_content);
                                        insert_msg_content_result = await db.query(insert_msg_content);
                                        logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_content_result))
                                        com_media_lstid.push(insert_msg_content_result.insertId);
                                    }

                                    if (media_urls.length == 0) {
                                        insert_msg_content = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}','${message_content}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N',CURRENT_TIMESTAMP)`
                                        logger_all.info("[insert query request] : " + insert_msg_content);
                                        insert_msg_content_result = await db.query(insert_msg_content);
                                        logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_content_result))
                                        com_media_lstid.push(insert_msg_content_result.insertId);
                                    }

                                    res_status = 'F'
                                    res_msg = 'Error occurred'
                                    res_code = 201
                                    res_code_status = 0

                                    try {

                                        var send_media, message_response;
                                        for (const media_url of media_urls) {
                                            const response = await axios.get(media_url, { responseType: 'arraybuffer' });
                                            const b64data = Buffer.from(response.data, 'binary').toString('base64');
                                            // // Get file extension from URL
                                            const fileName = media_url.split('/').pop();
                                            const mimetype = mime.getType(media_url);
                                            // Create MessageMedia object with media
                                            send_media = new MessageMedia(mimetype, b64data, fileName);

                                            if (message_content) {
                                                message_response = await myGroup.sendMessage(send_media, { caption: message_content });
                                            } else {
                                                message_response = await myGroup.sendMessage(send_media);
                                            }

                                            logger_all.info('Message sent successfully:', JSON.stringify(message_response));
                                        }

                                        if (message_content && media_urls.length == 0) {

                                            const message_response = await myGroup.sendMessage(message_content);
                                            logger_all.info('Message sent successfully:', JSON.stringify(message_response));
                                        }
                                        logger_all.info('Group ID:', myGroup.id._serialized + 'message:', message_content);

                                        res_status = 'Y'
                                        res_msg = 'Success'
                                        res_code = 200
                                        res_code_status = 1
                                    }
                                    catch (e) {
                                        logger_all.info(" Send message error - " + e)
                                    }

                                    const update_msg = `UPDATE whatsapp_group_newapi_${user_id}.compose_message_${user_id} SET cm_status = '${res_status}' WHERE compose_message_id = '${insert_msg_result.insertId}' AND cm_status = 'N'`
                                    logger_all.info("[update query request] : " + update_msg);
                                    const update_msg_result = await db.query(update_msg);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_msg_result))

                                    for (var last_id = 0; last_id < com_media_lstid.length; last_id++) {

                                        const update_msg_content = `UPDATE whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} SET cmm_status = '${res_status}' WHERE compose_msg_media_id = '${com_media_lstid[last_id]}' AND cmm_status = 'N'`

                                        logger_all.info("[update query request] : " + update_msg_content);
                                        const update_msg_content_result = await db.query(update_msg_content);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_msg_content_result))
                                    }
                                }
                                // const update_api_log = `UPDATE api_log SET response_status = '${res_status}',response_date = CURRENT_TIMESTAMP, response_comments = '${res_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`

                                // logger_all.info("[update query request] : " + update_api_log);
                                // const update_api_log_result = await db.query(update_api_log);
                                // logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                // response_json = { request_id: req.body.request_id, response_code: res_code_status, response_status: res_code, response_msg: res_msg }

                                // logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                // logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                // setTimeout(function () {
                                //     client.destroy();
                                //     logger_all.info(" Destroy client - " + sender_id)
                                // }, 3000);
                                // return res.json(response_json)
                            }

                            catch (e) {
                                logger_all.info(e);

                                const update_msg = `UPDATE whatsapp_group_newapi_${user_id}.compose_message_${user_id} SET cm_status = 'F' WHERE compose_message_id = '${insert_msg_result.insertId}' AND cm_status = 'N'`
                                logger_all.info("[update query request] : " + update_msg);
                                const update_msg_result = await db.query(update_msg);
                                logger_all.info("[update query response] : " + JSON.stringify(update_msg_result))

                                for (var last_id = 0; last_id < com_media_lstid.length; last_id++) {

                                    const update_msg_content = `UPDATE whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} SET cmm_status = '${res_status}' WHERE compose_msg_media_id = '${com_media_lstid[last_id]}' AND cmm_status = 'N'`

                                    logger_all.info("[update query request] : " + update_msg_content);
                                    const update_msg_content_result = await db.query(update_msg_content);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_msg_content_result))
                                }

                                // await client.destroy();
                                // logger_all.info(" Destroy client - " + sender_id)

                                // const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                // logger_all.info("[update query request] : " + update_api_log);
                                // const update_api_log_Result = await db.query(update_api_log);
                                // logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                // response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                // logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                // logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                // return res.json(response_json)
                            }
                        })
                    }


                    const update_api_log = `UPDATE api_log SET response_status = 'Y',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`

                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: "Success" }

                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    setTimeout(function () {
                        client.destroy();
                        logger_all.info(" Destroy client - " + sender_id)
                    }, group_array.length * 5000);
                    return res.json(response_json)

                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);


router.post(
    "/schedule_send_message",
    validator.body(SendMessageValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var myGroupName = req.body.group_name;
            var sender_id = req.body.sender_numbers;
            var template_name = req.body.template_name;
            var sms_send_time = req.body.sms_send_time;
            var image_url = req.body.image_url;
            var video_url = req.body.video_url;
            var function_call = false;
            var user_id = req.body.user_id;
            var sender_master_id, response_json, message_content, replace_msg, template_master_id;
            var grp_id = 0;
            var media_type = [];
            var media_urls = [];

            if (template_name == undefined) {
                template_master_id = '-';
            }

            if (image_url) {
                media_urls.push(image_url);
                media_type.push('IMAGE');
            }

            if (video_url) {
                media_urls.push(video_url);
                media_type.push('VIDEO');
            }
            // cronExpressionToDate To normal date convert
            function cronExpressionToDate(cronExpression) {
                const parts = cronExpression.split(' ');
                const minute = parts[0];
                const hour = parts[1];
                const dayOfMonth = parts[2];
                const month = parts[3];
                const dayOfWeek = parts[4]; // Not used in this conversion

                // Construct a Date object with the extracted components
                const date = new Date();
                date.setUTCFullYear(new Date().getFullYear());
                date.setUTCMinutes(minute);
                date.setUTCHours(hour);
                date.setUTCDate(dayOfMonth);
                date.setUTCMonth(month - 1); // Month in JavaScript is 0-indexed

                // Format the date string without seconds
                const dateString = `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}-${String(date.getUTCDate()).padStart(2, '0')} ${String(date.getUTCHours()).padStart(2, '0')}:${String(date.getUTCMinutes()).padStart(2, '0')}`;

                return dateString;
            }

            logger.info(" [send_msg query parameters] : " + JSON.stringify(req.body));
            if (user_id != '1') {
                const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                logger_all.info("[Select query request] : " + get_plan);
                const get_plan_result = await db.query(get_plan);
                logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                if (get_plan_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }
            }
            const select_sender_id = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
            logger_all.info(" [select query request] : " + select_sender_id)
            const select_sender_id_status = await db.query(select_sender_id);
            logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id_status))

            if (select_sender_id_status.length == 0) {
                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }

            user_id = select_sender_id_status[0].user_id;
            sender_master_id = select_sender_id_status[0].sender_master_id;

            const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
            logger_all.info("[select query request] : " + select_grp)
            const select_grp_result = await db.query(select_grp);
            logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

            if (select_grp_result.length != 0) {
                grp_id = select_grp_result[0].group_master_id;
            }

            // Get Template message
            if (template_name) {
                const select_template = `SELECT * FROM template_master WHERE template_name = '${template_name}' AND template_status = 'Y'`
                logger_all.info("[select query request] : " + select_template)
                const select_template_result = await db.query(select_template);
                logger_all.info("[select query response] : " + JSON.stringify(select_template_result))
                template_message = select_template_result[0].template_message;
                template_master_id = select_template_result[0].template_master_id;
                const data = JSON.parse(template_message);
                var replace_msg;
                data.forEach(item => {
                    const typeValue = item.type;
                    var textValue = item.text;

                    if (textValue.includes("<b>") || textValue.includes("<span>")) {
                        // Assuming textValue contains HTML text
                        replace_msg = textValue.replace(/<\/?b>/g, "*");
                        replace_msg = textValue.replace(/<\/?span>/g, "*");
                        message_content = replace_msg;
                    } else {
                        message_content = textValue;
                    }
                    logger_all.info("Type:", typeValue)
                    logger_all.info("Text:", message_content)
                });
            }

            // campaign name create
            Date.prototype.julianDate = function () {
                var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                    i = 3 - j.length;
                while (i-- > 0) j = 0 + j;
                return j
            };

            const select_campaign_id = `SELECT * FROM whatsapp_group_newapi_${user_id}.compose_message_${user_id} ORDER BY compose_message_id DESC limit 1`;
            logger_all.info("[select query request] : " + select_campaign_id)
            const select_campaign_id_result = await db.query(select_campaign_id);
            logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

            if (select_campaign_id_result.length == 0) {
                campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
            }
            else {
                let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                logger_all.info(temp_var[temp_var.length - 1]);
                let unique_id = parseInt(temp_var[temp_var.length - 1])
                campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
            }

            let res_msg, res_code, res_code_status, res_status, insert_msg_content, insert_msg_content_result;
            var com_media_lstid = [];

            const insert_msg = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_message_${user_id} VALUES(NULL,'${user_id}','${sender_master_id}','${grp_id}',${template_master_id !== undefined ? `'${template_master_id}'` : 'NULL'},'TEXT','${campaign_name}','N',NULL,'N',CURRENT_TIMESTAMP)`
            logger_all.info("[insert query request] : " + insert_msg);
            const insert_msg_result = await db.query(insert_msg);
            logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_result))

            for (var mediaurl = 0; mediaurl < media_urls.length; mediaurl++) {
                insert_msg_content = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}',${message_content !== undefined ? `'${message_content}'` : 'NULL'},NULL,NULL,NULL,NULL,${media_urls.length !== 0 ? `'${media_urls[mediaurl]}'` : 'NULL'},${media_type.length !== 0 ? `'${media_type[mediaurl]}'` : 'NULL'},NULL,'N',CURRENT_TIMESTAMP)`
                logger_all.info("[insert query request] : " + insert_msg_content);
                insert_msg_content_result = await db.query(insert_msg_content);
                logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_content_result))
                com_media_lstid.push(insert_msg_content_result.insertId);

                const insert_cron_compose = `INSERT INTO cron_compose VALUES(NULL,'${insert_msg_result.insertId}','${insert_msg_content_result.insertId}','${user_id}','${grp_id}','N','${sms_send_time}',NULL)`;
                logger_all.info("[insert query request] : " + insert_cron_compose);
                const cron_compose_result = await db.query(insert_cron_compose);
                logger_all.info("[insert query response] : " + JSON.stringify(cron_compose_result))

            }

            if (media_urls.length == 0) {
                insert_msg_content = `INSERT INTO whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}','${message_content}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N',CURRENT_TIMESTAMP)`
                logger_all.info("[insert query request] : " + insert_msg_content);
                insert_msg_content_result = await db.query(insert_msg_content);
                logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_content_result))
                com_media_lstid.push(insert_msg_content_result.insertId);

                const insert_cron_compose = `INSERT INTO cron_compose VALUES(NULL,'${insert_msg_result.insertId}','${insert_msg_content_result.insertId}','${user_id}','${grp_id}','N','${sms_send_time}',NULL)`;
                logger_all.info("[insert query request] : " + insert_cron_compose);
                const cron_compose_result = await db.query(insert_cron_compose);
                logger_all.info("[insert query response] : " + JSON.stringify(cron_compose_result))
            }

            res_status = 'S'
            res_msg = 'Success'
            res_code = 200
            res_code_status = 1

            // Function to convert a date string to a cron expression
            function dateStringToCronExpression(dateString) {
                const date = new Date(dateString);
                const minute = date.getMinutes();
                const hour = date.getHours();
                const dayOfMonth = date.getDate();
                const month = date.getMonth() + 1; // Month in JavaScript starts from 0
                const dayOfWeek = '*'; // You can set the day of the week if needed, otherwise use '*'
                // Construct the cron expression
                const cronExpression = `${minute} ${hour} ${dayOfMonth} ${month} ${dayOfWeek}`;
                return cronExpression;
            }

            const cronExpression = dateStringToCronExpression(sms_send_time);

            // Set up cron job using the cron expression
            cron.schedule(cronExpression, async () => {
                try {

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        schedule_send_message();
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            const dateString = cronExpressionToDate(cronExpression);
                            const select_cron_compose = `SELECT * FROM cron_compose WHERE DATE_FORMAT(schedule_date, '%Y-%m-%d %H:%i') = '${dateString}' and cron_status = 'N'`;

                            logger_all.info("[select query request] : " + select_cron_compose)
                            const select_cron_compose_result = await db.query(select_cron_compose);
                            logger_all.info("[select query response] : " + JSON.stringify(select_cron_compose_result))
                            if (select_cron_compose_result.length > 0) {

                                slt_user_id = select_cron_compose_result[0].user_id;
                                const update_inactive = `UPDATE cron_compose SET cron_status = 'F' WHERE user_id = '${slt_user_id}' AND cron_status != 'F' and com_msg_media_id = '${select_cron_compose_result[0].com_msg_media_id}'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                const update_msg_content = `UPDATE whatsapp_group_newapi_${slt_user_id}.compose_msg_media_${slt_user_id} SET cmm_status = 'F',failed_reason = 'Sender ID unlinked' WHERE compose_msg_media_id = '${select_cron_compose_result[0].com_msg_media_id}' AND cmm_status = 'N'`;
                                logger_all.info("[update query request] : " + update_msg_content);
                                const update_msg_content_result = await db.query(update_msg_content);
                                logger_all.info("[update query response] : " + JSON.stringify(update_msg_content_result))

                            }

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                        fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                        logger_all.info('Folder copied successfully')
                                    }

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        schedule_send_message();
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {
                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                            const update_msg_content = `UPDATE whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} SET cmm_status = 'F',failed_reason = 'Sender ID unlinked' WHERE compose_msg_media_id = '${insert_msg_content_result.insertId}' AND cmm_status = 'N'`;
                                            logger_all.info("[update query request] : " + update_msg_content);
                                            const update_msg_content_result = await db.query(update_msg_content);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_msg_content_result))

                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {
                                    logger_all.info(err)

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }
                            }
                            else {
                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);

                    async function schedule_send_message() {
                        logger_all.info(" schedule_send_message Function calling")
                        function_call = true;
                        client.getChats().then(async (chats) => {
                            try {

                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                // Wait for the client to be ready
                                await new Promise(resolve => setTimeout(resolve, 5000));

                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)

                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)

                                }

                                if (grp_id == 0) {
                                    const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${myGroupName}','${myGroup.participants.length}','0','${myGroup.participants.length}','N','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL,NULL,'N')`
                                    logger_all.info("[insert query request] : " + insert_grp);
                                    const insert_grp_result = await db.query(insert_grp);
                                    logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                    grp_id = insert_grp_result.insertId;
                                }

                                try {

                                    var send_media, message_response;

                                    for (const media_url of media_urls) {
                                        const response = await axios.get(media_url, { responseType: 'arraybuffer' });
                                        const b64data = Buffer.from(response.data, 'binary').toString('base64');
                                        // // Get file extension from URL
                                        const fileName = media_url.split('/').pop();
                                        const mimetype = mime.getType(media_url);
                                        // Create MessageMedia object with media
                                        send_media = new MessageMedia(mimetype, b64data, fileName);

                                        if (message_content) {
                                            message_response = await myGroup.sendMessage(send_media, { caption: message_content });

                                        } else {
                                            message_response = await myGroup.sendMessage(send_media);
                                        }
                                        logger_all.info('Message sent successfully:', JSON.stringify(message_response));
                                    }

                                    if (message_content && media_urls.length == 0) {
                                        const message_response = await myGroup.sendMessage(message_content);
                                        logger_all.info('Message sent successfully:', JSON.stringify(message_response));
                                    }
                                    logger_all.info('Group ID:', myGroup.id._serialized + 'message:', message_content);

                                    res_status = 'Y'
                                    res_msg = 'Success'
                                    res_code = 200
                                    res_code_status = 1
                                }
                                catch (e) {  // send message catch condition
                                    logger_all.info(" Send message error - " + e)
                                }

                                for (var last_id = 0; last_id < com_media_lstid.length; last_id++) {
                                    const update_msg_content = `UPDATE whatsapp_group_newapi_${user_id}.compose_msg_media_${user_id} SET cmm_status = '${res_status}' WHERE compose_msg_media_id = '${com_media_lstid[last_id]}' AND cmm_status = 'N'`
                                    logger_all.info("[update query request] : " + update_msg_content);
                                    const update_msg_content_result = await db.query(update_msg_content);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_msg_content_result))

                                    const update_active = `UPDATE cron_compose SET cron_status = '${res_status}' WHERE user_id = '${user_id}' AND cron_status != 'Y' and com_msg_media_id = '${com_media_lstid[last_id]}' `
                                    logger_all.info(" [update query request] : " + update_active)
                                    const update_active_result = await db.query(update_active);
                                    logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))

                                }

                                const update_msg = `UPDATE whatsapp_group_newapi_${user_id}.compose_message_${user_id} SET cm_status = '${res_status}' WHERE compose_message_id = '${insert_msg_result.insertId}' AND cm_status = 'N'`
                                logger_all.info("[update query request] : " + update_msg);
                                const update_msg_result = await db.query(update_msg);
                                logger_all.info("[update query response] : " + JSON.stringify(update_msg_result))

                                const update_api_log = `UPDATE api_log SET response_status = '${res_status}',response_date = CURRENT_TIMESTAMP, response_comments = '${res_msg}' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: res_code_status, response_status: res_code, response_msg: res_msg }

                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                setTimeout(async function () {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                }, 3000);
                            }

                            catch (e) {   // Get chat catch condition
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        })
                    }
                } catch (error) {    // cron catch condition
                    console.error('Error:', error);
                }
            });  //cron function close
            response_json = { request_id: req.body.request_id, response_code: res_code_status, response_status: res_code, response_msg: res_msg }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)
        } catch (err) { // function starting catch condition
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);


router.post(
    "/add_members",
    validator.body(CreateGroupValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var participants = req.body.participants;
            var group_docs = req.body.group_docs;
            var sender_id = req.body.sender_id;
            var function_call = false;
            var sender_master_id, response_json, grp_id, contact_id = [], response_msg = [];
            var user_id = req.body.user_id;
            var grp_id = 0, totalCount = 0;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [], exist_mobile_count = [];
            let participants_number = [];
            let invalid_mobile_numbers = [];
            let not_add_partcipants = [];
            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = new Set();
            // Check if group_docs are provided
            if (group_docs) {
                // Fetch the CSV file
                fs.createReadStream(group_docs)
                    // Read the CSV file from the stream
                    .pipe(csv({
                        headers: false
                    })) // Set headers to false since there are no column headers
                    .on('data', (row) => {
                        totalCount++;
                        const firstColumnValue = row[0];
                        // Validate mobile number format
                        const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                        // Check for duplicates
                        if (duplicateMobileNumbers.has(firstColumnValue)) {
                            not_add_partcipants.push(firstColumnValue);
                            invalid_mobile_numbers.push(firstColumnValue);
                        } else {
                            duplicateMobileNumbers.add(firstColumnValue);
                            while (duplicateMobileNumbers.length > 0) {
                                not_add_partcipants.push(duplicateMobileNumbers.shift());
                            }
                            if (isValidFormat) {
                                valid_mobile_numbers.push(firstColumnValue);

                            } else {
                                not_add_partcipants.push(firstColumnValue);
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        //  logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                while (participants.length > 0) {
                    // Remove the first element from sourceArray and add it to the end of destinationArray
                    valid_mobile_numbers.push(participants.shift());
                }
                logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {

                if (user_id != '1') {
                    const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                    logger_all.info("[Select query request] : " + get_plan);
                    logger_all.info("[Select query request] : " + get_plan);
                    const get_plan_result = await db.query(get_plan);
                    logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                    if (get_plan_result.length > 0) {
                        available_group_count = get_plan_result[0].available_group_count;

                        if (available_group_count <= 0) {
                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No available credit to Add Senderid.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No available credit to Add Senderid.' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    } else if (get_plan_result.length == 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }
                }
                const select_sender_id = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
                logger_all.info(" [select query request] : " + select_sender_id)
                const select_sender_id_status = await db.query(select_sender_id);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id_status))

                if (select_sender_id_status.length == 0) {

                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }
                else {

                    user_id = select_sender_id_status[0].user_id;
                    sender_master_id = select_sender_id_status[0].sender_master_id;

                    const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp)
                    const select_grp_result = await db.query(select_grp);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

                    if (select_grp_result.length != 0) {
                        grp_id = select_grp_result[0].group_master_id;
                    }

                    Date.prototype.julianDate = function () {
                        var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                            i = 3 - j.length;
                        while (i-- > 0) j = 0 + j;
                        return j
                    };

                    const select_campaign_id = `SELECT * FROM group_contacts ORDER BY group_contacts_id DESC limit 1`
                    logger_all.info("[select query request] : " + select_campaign_id)
                    const select_campaign_id_result = await db.query(select_campaign_id);
                    logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

                    if (select_campaign_id_result.length == 0) {
                        campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
                    }
                    else {
                        let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                        logger_all.info(temp_var[temp_var.length - 1]);
                        let unique_id = parseInt(temp_var[temp_var.length - 1])
                        campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        add_participant();
                    });

                    setTimeout(async function () {
                        if (function_call == false) {
                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        add_participant()
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {

                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {
                                    logger_all.info(err)

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }
                            }
                            else {
                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);

                    async function add_participant() {
                        logger_all.info(" add_participant Function calling")
                        function_call = true;

                        client.getChats().then(async (chats) => {
                            try {
                                // Find the newly created group
                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                const parti_count = myGroup.participants.length;
                                await new Promise(resolve => setTimeout(resolve, 5000));
                                // logger_all.info(JSON.stringify(myGroup));
                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)

                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)
                                }
                                else if (participants.length > 1000 || valid_mobile_numbers.length > 1000) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Cannot add more than 1000 numbers to a group.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Cannot add more than 1000 numbers to a group.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }

                                if (grp_id == 0) {

                                    const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${myGroupName}','${myGroup.participants.length}','0','${myGroup.participants.length}','N','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,NULL,NULL,'N')`
                                    logger_all.info("[insert query request] : " + insert_grp);
                                    const insert_grp_result = await db.query(insert_grp);
                                    logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                    grp_id = insert_grp_result.insertId;
                                }

                                await client.getContacts().then(async (contacts) => {

                                    for (var i = 0; i < valid_mobile_numbers.length; i++) {
                                        logger_all.info(" - " + valid_mobile_numbers[i])

                                        // Check if the mobile number already exists in the group
                                        const numberExistsInGroup = myGroup.participants.some(
                                            (participant) => participant.id.user === valid_mobile_numbers[i]
                                        );

                                        if (numberExistsInGroup) {
                                            exist_mobile_count.push(valid_mobile_numbers[i]);
                                            logger_all.info(`${valid_mobile_numbers[i]} is already in the ${myGroupName} group.`);
                                            response_msg.push('Already Exists');
                                        } else {

                                            const contactToAdd = contacts.find(
                                                (contact) => contact.number === `${valid_mobile_numbers[i]}`
                                            );

                                            if (contactToAdd) {
                                                logger_all.info("Contact Found!!!");
                                                const sanitized_number = valid_mobile_numbers[i].toString().replace(/[- )(]/g, ""); // remove unnecessary chars from the number
                                                const final_number = `${sanitized_number.substring(sanitized_number.length - 10)}`; // add 91 before the number here 91 is country code of India
                                                const number_details = await client.getNumberId(final_number); // get mobile number details
                                                if (number_details) {
                                                    contact_id.push(contactToAdd.id._serialized);
                                                    response_msg.push('Success');
                                                    participants_number.push(valid_mobile_numbers[i]);
                                                }
                                                else {
                                                    response_msg.push('Not in whatsapp!!!');
                                                    logger_all.info('Not in whatsapp!!!');
                                                }
                                            } else {
                                                response_msg.push('Not found!!!');
                                                logger_all.info('Not found!!!');
                                            }
                                        }

                                    }
                                });

                                if (exist_mobile_count.length == valid_mobile_numbers.length) {

                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Already Exists Contacts' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Already Exists Contacts' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                } else if (contact_id.length == 0) {

                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json);
                                }


                                var group_add = await myGroup.addParticipants(contact_id);
                                logger_all.info(group_add);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                for (var k = 0; k < valid_mobile_numbers.length; k++) {

                                    const select_number = `SELECT con.campaign_name FROM group_contacts con  LEFT JOIN group_master grp ON grp.group_master_id = con.group_master_id WHERE con.mobile_no = '${valid_mobile_numbers[k]}' AND grp.group_name = '${myGroupName}'  `
                                    logger_all.info("[select query request] : " + select_number);
                                    const select_number_result = await db.query(select_number);
                                    logger_all.info("[select query response] : " + JSON.stringify(select_number_result))

                                    if (select_number_result.length > 0) {

                                        const update_grp_count = `UPDATE group_master SET total_count = total_count+1,success_count = success_count + 1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count + 1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                        logger_all.info("[update query request] : " + update_grp_count);
                                        const update_grp_count_result = await db.query(update_grp_count);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                        const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'Y',remove_comments = NULL,admin_status = NULL WHERE group_master_id = '${grp_id}' AND group_contacts_status != 'Y' and mobile_no = '${valid_mobile_numbers[k]}'`
                                        logger_all.info("[Update query request] : " + update_remove_members);
                                        const update_remove_members_result = await db.query(update_remove_members);

                                        logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))

                                    } else {
                                        var contact_status = participants_number.includes(`${valid_mobile_numbers[k]}`) ? 'Y' : 'F';
                                        const update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${grp_id}','${campaign_name}','${valid_mobile_numbers[k]}','${valid_mobile_numbers[k]}','${response_msg[k]}','${contact_status}',CURRENT_TIMESTAMP,NULL,NULL)`
                                        logger_all.info("[insert query request] : " + update_number_status);
                                        const update_number_status_result = await db.query(update_number_status);
                                        logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))

                                        const update_grp_count = `UPDATE group_master SET total_count = total_count+${valid_mobile_numbers.length},success_count= success_count+${contact_id.length}, failure_count= failure_count+${valid_mobile_numbers.length - contact_id.length},group_updated_date = CURRENT_TIMESTAMP,members_count = ${parti_count} + 1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                        logger_all.info("[update query request] : " + update_grp_count);
                                        const update_grp_count_result = await db.query(update_grp_count);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                    }
                                }
                                const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))



                                response_json = {
                                    request_id: req.body.request_id,
                                    response_code: 1,
                                    response_status: 200,
                                    response_msg: 'Members Added.!!',
                                    "success": contact_id.length,
                                    "failure": valid_mobile_numbers.length - contact_id.length - not_add_partcipants.length
                                }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)

                            }
                            catch (e) {
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        })
                    }
                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/create_group",
    validator.body(CreateGroupValidation),
    valid_user,
    async function (req, res, next) {
        try {

            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var participants = req.body.participants;
            var group_docs = req.body.group_docs;
            var sender_id = req.body.sender_id;
            var function_call = false;
            var sender_master_id, response_json, grp_id, contact_id = [], response_msg = [];
            var user_id = req.body.user_id;
            var grp_id = 0, totalCount = 0, available_group_count = 0;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [], exist_mobile_count = [];
            let participants_number = [];
            let invalid_mobile_numbers = [];
            let not_add_partcipants = [];

            var day = new Date();
            var today_date = day.getFullYear() + '' + (day.getMonth() + 1) + '' + day.getDate();
            var today_time = day.getHours() + "" + day.getMinutes() + "" + day.getSeconds();
            var current_date = today_date + '_' + today_time;

            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = new Set();
            // Check if group_docs are provided
            if (group_docs) {
                // Fetch the CSV file
                fs.createReadStream(group_docs)
                    // Read the CSV file from the stream
                    .pipe(csv({
                        headers: false
                    })) // Set headers to false since there are no column headers
                    .on('data', (row) => {
                        totalCount++;
                        const firstColumnValue = row[0];
                        // Validate mobile number format
                        const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                        // Check for duplicates
                        if (duplicateMobileNumbers.has(firstColumnValue)) {
                            not_add_partcipants.push(firstColumnValue);
                            invalid_mobile_numbers.push(firstColumnValue);
                        } else {
                            duplicateMobileNumbers.add(firstColumnValue);
                            while (duplicateMobileNumbers.length > 0) {
                                not_add_partcipants.push(duplicateMobileNumbers.shift());
                            }
                            if (isValidFormat) {
                                valid_mobile_numbers.push(firstColumnValue);

                            } else {
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        //  logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                while (participants.length > 0) {
                    // Remove the first element from sourceArray and add it to the end of destinationArray
                    valid_mobile_numbers.push(participants.shift());
                }
                logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {


                if (user_id != '1') {

                    const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                    logger_all.info("[Select query request] : " + get_plan);
                    logger_all.info("[Select query request] : " + get_plan);
                    const get_plan_result = await db.query(get_plan);
                    logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                    if (get_plan_result.length > 0) {
                        available_group_count = get_plan_result[0].available_group_count;

                        if (available_group_count <= 0) {
                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No available credit to credit group.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No available credit to credit group.' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    } else if (get_plan_result.length == 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }
                }

                const select_sender = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
                logger_all.info(" [select query request] : " + select_sender)
                const select_sender_result = await db.query(select_sender);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_result))

                if (select_sender_result.length == 0) {

                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }
                else {
                    sender_master_id = select_sender_result[0].sender_master_id;

                    const select_grp_result = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp_result)
                    const select_grp_result_result = await db.query(select_grp_result);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result_result))

                    if (select_grp_result_result.length != 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group already exists' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)

                    }

                    if (participants.length > 1000 || valid_mobile_numbers.length > 1000) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Cannot add more than 1000 numbers to a group.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Cannot add more than 1000 numbers to a group.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }
                    Date.prototype.julianDate = function () {
                        var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                            i = 3 - j.length;
                        while (i-- > 0) j = 0 + j;
                        return j
                    };

                    const select_campaign_id = `SELECT * FROM group_contacts ORDER BY group_contacts_id DESC limit 1`
                    logger_all.info("[select query request] : " + select_campaign_id)
                    const select_campaign_id_result = await db.query(select_campaign_id);
                    logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

                    if (select_campaign_id_result.length == 0) {
                        campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_1`;
                    }
                    else {
                        let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                        let unique_id = parseInt(temp_var[temp_var.length - 1])
                        campaign_name = `ca_${myGroupName}_${new Date().julianDate()}_${unique_id + 1}`;
                    }
                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        create_grp();
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        create_grp()
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {

                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {
                                    logger_all.info(err)

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": valid_mobile_numbers.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }
                            }
                            else {

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);

                    async function create_grp() {
                        logger_all.info(" create_grp Function calling")
                        function_call = true; var group_link;

                        try {

                            await client.getContacts().then(async (contacts) => {

                                for (var i = 0; i < valid_mobile_numbers.length; i++) {
                                    logger_all.info(" - " + valid_mobile_numbers[i])
                                    const contactToAdd = contacts.find(
                                        (contact) => contact.number === `${valid_mobile_numbers[i]}`
                                    );
                                    if (contactToAdd) {
                                        logger_all.info("Contact Found!!!");
                                        const sanitized_number = valid_mobile_numbers[i].toString().replace(/[- )(]/g, ""); // remove unnecessary chars from the number
                                        const final_number = `${sanitized_number.substring(sanitized_number.length - 10)}`; // add 91 before the number here 91 is country code of India
                                        const number_details = await client.getNumberId(final_number); // get mobile number details
                                        if (number_details) {
                                            contact_id.push(contactToAdd.id._serialized);
                                            participants_number.push(valid_mobile_numbers[i]);
                                            response_msg.push("Success")
                                        }
                                        else {
                                            logger_all.info('Not in whatsapp!!!');
                                            response_msg.push("Mobile number not in whatsapp")
                                        }
                                    } else {
                                        logger_all.info('Not found!!!');
                                        response_msg.push("Contact not found")
                                    }
                                }
                            });

                            if (contact_id.length == 0) {
                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }

                            var create_grp = await client.createGroup(myGroupName, contact_id)
                            var myGroup = await client.getChatById(create_grp.gid._serialized)
                            const participantsCount = myGroup.participants.length;
                            if (myGroup) {
                                // Get the invite code for the group
                                group_code = await myGroup.getInviteCode();
                                group_link = `${whatsapp_link + group_code}`;

                                logger_all.info(group_code, group_link);

                                // Generate QR code
                                qr.toFile(media_storage + '/uploads/group_qr/' + current_date+ '.png', group_link, (err) => {
                                    if (err) throw err;

                                });
                                logger_all.info("QR code generated successfully");
                            }
                            else {
                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                return res.json(response_json)
                            }

                            const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${myGroupName}','${valid_mobile_numbers.length}','${contact_id.length}','${valid_mobile_numbers.length - contact_id.length}','Y','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'${group_link}','${media_storage}/uploads/group_qr/${current_date}.png',1,'${valid_mobile_numbers.length}','N')`
                            logger_all.info("[insert query request] : " + insert_grp);
                            const insert_grp_result = await db.query(insert_grp);
                            logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                            for (var k = 0; k < valid_mobile_numbers.length; k++) {

                                var contact_status = participants_number.includes(`${valid_mobile_numbers[k]}`) ? 'Y' : 'F';

                                const update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','${campaign_name}','${valid_mobile_numbers[k]}','${valid_mobile_numbers[k]}','${response_msg[k]}','${contact_status}',CURRENT_TIMESTAMP,NULL,NULL)`
                                logger_all.info("[insert query request] : " + update_number_status);
                                const update_number_status_result = await db.query(update_number_status);
                                logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))

                            }

                            const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                            // Update plans_update table
                            const plans_update = ` UPDATE plans_update SET available_group_count = available_group_count - 1,used_group_count = used_group_count + 1 WHERE user_id = '${user_id}' AND plan_status = 'Y'`;

                            logger_all.info("[update query request] : " + plans_update);
                            const plans_update_result = await db.query(plans_update);
                            logger_all.info("[update query response] : " + JSON.stringify(plans_update_result))



                            response_json = {
                                request_id: req.body.request_id,
                                response_code: 1,
                                response_status: 200,
                                response_msg: 'Group Created and Members Added.!!',
                                "success": contact_id.length,
                                "failure": valid_mobile_numbers.length - contact_id.length - not_add_partcipants.length
                            }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                            await client.destroy();
                            return res.json(response_json)

                        }
                        catch (e) {
                            logger_all.info(e);
                            await client.destroy();
                            logger_all.info(" Destroy client - " + sender_id)
                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    }
                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);


router.post(
    "/remove_members",
    validator.body(AdminProDeValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var myGroupName = req.body.group_name;
            var participants = req.body.participants;
            var group_docs = req.body.group_docs;
            var sender_id = req.body.sender_id;
            var remove_comments = req.body.remove_comments;
            var function_call = false;
            var sender_master_id, response_json, grp_id, contact_id = [];
            var user_id = req.body.user_id;
            var grp_id = 0, totalCount = 0;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [];
            let invalid_mobile_numbers = [];
            let not_remove_partcipants = [];
            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = new Set();
            // Check if group_docs are provided
            if (group_docs) {
                // Fetch the CSV file
                fs.createReadStream(group_docs)
                    // Read the CSV file from the stream
                    .pipe(csv({
                        headers: false
                    })) // Set headers to false since there are no column headers
                    .on('data', (row) => {
                        totalCount++;
                        const firstColumnValue = row[0];
                        // Validate mobile number format
                        const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                        // Check for duplicates
                        if (duplicateMobileNumbers.has(firstColumnValue)) {
                            not_remove_partcipants.push(firstColumnValue);
                            invalid_mobile_numbers.push(firstColumnValue);
                        } else {
                            duplicateMobileNumbers.add(firstColumnValue);
                            while (duplicateMobileNumbers.length > 0) {
                                not_remove_partcipants.push(duplicateMobileNumbers.shift());
                            }
                            if (isValidFormat) {
                                valid_mobile_numbers.push(firstColumnValue);

                            } else {
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        //  logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                while (participants.length > 0) {
                    // Remove the first element from sourceArray and add it to the end of destinationArray
                    valid_mobile_numbers.push(participants.shift());
                }
                logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {

                if (user_id != '1') {

                    const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                    logger_all.info("[Select query request] : " + get_plan);
                    logger_all.info("[Select query request] : " + get_plan);
                    const get_plan_result = await db.query(get_plan);
                    logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                    if (get_plan_result.length == 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }
                }

                const select_sender_id = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
                logger_all.info(" [select query request] : " + select_sender_id)
                const select_sender_id_status = await db.query(select_sender_id);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id_status))

                if (select_sender_id_status.length == 0) {

                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }
                else {

                    user_id = select_sender_id_status[0].user_id;
                    sender_master_id = select_sender_id_status[0].sender_master_id;

                    const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp)
                    const select_grp_result = await db.query(select_grp);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

                    if (select_grp_result.length != 0) {
                        grp_id = select_grp_result[0].group_master_id;
                    } else {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        remove_participant();
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })

                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')
                                    //}

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        remove_participant()
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {

                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {
                                    logger_all.info(err)

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }
                            }
                            else {
                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);


                    async function remove_participant() {
                        function_call = true;
                        logger_all.info("[API RESPONSE]  remove_participant Function calling")

                        client.getChats().then(async (chats) => {
                            try {

                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                // const parti_count = myGroup.participants.length;
                                await new Promise(resolve => setTimeout(resolve, 5000));
                                // logger_all.info(JSON.stringify(myGroup));

                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)

                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)

                                }
                                else if (participants.length > 1000 || valid_mobile_numbers.length > 1000) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Cannot remove more than 1000 numbers to a group.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Cannot remove more than 1000 numbers to a group.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }

                                const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants_details: [] });


                                for (let i = 0; i < valid_mobile_numbers.length; i++) {
                                    var participant = valid_mobile_numbers[i];
                                    res_status = 'Y';

                                    // Check if participant number exists in the group
                                    const participantIndex = participantNumbers.indexOf(participant);
                                    if (participantIndex !== -1) {
                                        logger_all.info(`Phone number ${participant} exists in the group.`)

                                        // Get participant object
                                        const participantObject = participants_details[participantIndex];

                                        // Check if participant is already an admin
                                        if (participantObject.isAdmin) {
                                            logger_all.info("ContactToadminRemove + Contact Found!!!");
                                            // Get number details for the participant
                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));
                                            contact_id.push(participant);
                                            // Promote the participant to admin
                                            var remove_participants = await myGroup.removeParticipants([numberDetails._serialized]);
                                            logger_all.info("[ ContactToadminRemove ] : " + JSON.stringify(remove_participants));

                                            if (remove_participants.status != 200) {
                                                logger_all.info("[Promote admin response Error:]" + JSON.stringify(remove_participants));
                                                not_remove_partcipants.push(participant);
                                            }

                                            logger_all.info(" GROUP ID IS " + grp_id)
                                            const update_grp_count = `UPDATE group_master SET total_count = total_count-1,success_count = success_count-1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count-1,admin_count = admin_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                            logger_all.info("[update query request] : " + update_grp_count);
                                            const update_grp_count_result = await db.query(update_grp_count);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                            const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'R',remove_comments ='${remove_comments}',admin_status = NULL WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${valid_mobile_numbers[i]}'`
                                            logger_all.info("[Update query request] : " + update_remove_members);
                                            const update_remove_members_result = await db.query(update_remove_members);

                                            logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))

                                        } else {
                                            logger_all.info("ContactRemove + Contact Found!!!");
                                            // Get number details for the participant
                                            contact_id.push(participant);
                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Promote the participant to admin
                                            var remove_participants = await myGroup.removeParticipants([numberDetails._serialized]);
                                            logger_all.info("[ ContactRemove ] : " + JSON.stringify(remove_participants));

                                            logger_all.info(" GROUP ID IS " + grp_id)
                                            const update_grp_count = `UPDATE group_master SET total_count = total_count-1,success_count= success_count-1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                            logger_all.info("[update query request] : " + update_grp_count);
                                            const update_grp_count_result = await db.query(update_grp_count);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                            const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'R',remove_comments = '${remove_comments}' WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${valid_mobile_numbers[i]}'`
                                            logger_all.info("[Update query request] : " + update_remove_members);
                                            const update_remove_members_result = await db.query(update_remove_members);

                                            logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))

                                            if (remove_participants.status != 200) {
                                                logger_all.info("[Promote admin response Error:]" + JSON.stringify(remove_participants));
                                                not_remove_partcipants.push(participant);
                                            }
                                        }
                                    } else {
                                        not_remove_partcipants.push(participant);
                                        logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                    }
                                }

                                if (valid_mobile_numbers.length == 0) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No contacts found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No contacts found.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                    return res.json(response_json)
                                }

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)


                                const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = {
                                    "request_id": req.body.request_id,
                                    "response_code": 1,
                                    "response_status": 200,
                                    "response_msg": "Members removed.!!",
                                    "success": contact_id.length,
                                    "failure": valid_mobile_numbers.length - contact_id.length - not_remove_partcipants.length
                                }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                            catch (e) {
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        })
                    }
                }

            }

        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/promote_admin",
    validator.body(AdminProDeValidation),
    valid_user,
    async function (req, res, next) {
        "use strict";
        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var participants = req.body.participants;
            var sender_id = req.body.sender_id;
            var group_docs = req.body.group_docs;
            var user_id = req.body.user_id;
            var function_call = false;
            var contact_id = [], totalCount = 0, grp_id = 0;
            var sender_master_id, response_json, grp_id, comments;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [];
            let invalid_mobile_numbers = [];
            let not_promote_partcipants = [];
            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = new Set();
            // Check if group_docs are provided
            if (group_docs) {
                // Fetch the CSV file
                fs.createReadStream(group_docs)
                    // Read the CSV file from the stream
                    .pipe(csv({
                        headers: false
                    })) // Set headers to false since there are no column headers
                    .on('data', (row) => {
                        totalCount++;
                        const firstColumnValue = row[0];
                        // Validate mobile number format
                        const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                        // Check for duplicates
                        if (duplicateMobileNumbers.has(firstColumnValue)) {
                            not_promote_partcipants.push(firstColumnValue);
                            invalid_mobile_numbers.push(firstColumnValue);
                        } else {
                            duplicateMobileNumbers.add(firstColumnValue);
                            while (duplicateMobileNumbers.length > 0) {
                                not_promote_partcipants.push(duplicateMobileNumbers.shift());
                            }
                            if (isValidFormat) {
                                valid_mobile_numbers.push(firstColumnValue);

                            } else {
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        //  logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                while (participants.length > 0) {
                    // Remove the first element from sourceArray and add it to the end of destinationArray
                    valid_mobile_numbers.push(participants.shift());
                }
                logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {
                if (user_id != '1') {
                    const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                    logger_all.info("[Select query request] : " + get_plan);
                    logger_all.info("[Select query request] : " + get_plan);
                    const get_plan_result = await db.query(get_plan);
                    logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                    if (get_plan_result.length == 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)
                    }
                }

                const select_sender = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
                logger_all.info(" [select query request] : " + select_sender)
                const select_sender_result = await db.query(select_sender);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_result))

                if (select_sender_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }
                else {
                    sender_master_id = select_sender_result[0].sender_master_id;

                    const select_grp_result = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp_result)
                    const select_grp_result_result = await db.query(select_grp_result);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result_result))

                    if (select_grp_result_result.length != 0) {
                        grp_id = select_grp_result_result[0].group_master_id;
                    } else {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        promote_admin()
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        promote_admin();
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {
                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))
                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {

                                    logger_all.info(err)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)
                                }
                            }
                            else {

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);
                    var res_status;
                    async function promote_admin() {
                        logger_all.info("[Promote_admin function calling] ")
                        function_call = true;
                        client.getChats().then(async (chats) => {
                            try {

                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                const participantsCount = myGroup.participants.length;
                                await new Promise(resolve => setTimeout(resolve, 5000));

                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)

                                }

                                const { participantNumbers, participants } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants: [] });

                                // Loop through valid_mobile_numbers array

                                for (let i = 0; i < valid_mobile_numbers.length; i++) {
                                    var participant = valid_mobile_numbers[i];
                                    res_status = 'Y';

                                    // Check if participant number exists in the group
                                    const participantIndex = participantNumbers.indexOf(participant);
                                    if (participantIndex !== -1) {
                                        logger_all.info(`Phone number ${participant} exists in the group.`)

                                        // Get participant object
                                        const participantObject = participants[participantIndex];

                                        // Check if participant is already an admin
                                        if (participantObject.isAdmin) {
                                            not_promote_partcipants.push(participant);
                                            comments = 'already admin';
                                            logger_all.info(`Phone number ${participant} is already an admin.`)

                                        } else {
                                            // Get number details for the participant
                                            contact_id.push(participant);

                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Promote the participant to admin
                                            var admin_add = await myGroup.promoteParticipants([numberDetails._serialized]);
                                            logger_all.info("[Promote admin response] : " + JSON.stringify(admin_add));
                                            comments = 'Success'

                                            // Define the group_contacts query here
                                            var group_master = `UPDATE group_master SET admin_count = admin_count+1,members_count = '${participantsCount}' WHERE group_master_id = '${grp_id}' and group_name = '${myGroupName}'`;
                                            logger_all.info("[update query request] : " + group_master);
                                            const group_master_res = await db.query(group_master);
                                            logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                                            if (admin_add.status != 200) {
                                                logger_all.info("[Promote admin response Error:]" + JSON.stringify(admin_add));
                                                not_promote_partcipants.push(participant);
                                                res_status = 'F';
                                                comments = 'Failure'
                                            }
                                        }
                                    } else {
                                        res_status = 'F';
                                        comments = 'Failure'
                                        not_promote_partcipants.push(participant);
                                        logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                    }
                                    // Define the group_contacts query here
                                    var group_contacts = `UPDATE group_contacts SET admin_status = '${res_status}',comments = '${comments}' WHERE group_master_id = '${grp_id}' and mobile_no = '${participant}'`;
                                    logger_all.info("[update query request] : " + group_contacts);
                                    const group_contacts_result = await db.query(group_contacts);
                                    logger_all.info("[update query response] : " + JSON.stringify(group_contacts_result))

                                }

                                if (valid_mobile_numbers.length == 0) {
                                    res_status = 'F';
                                    response_json = { request_id: req.body.request_id, response_code: 201, response_status: 0, response_msg: 'Invalid File Type.' }

                                } else {
                                    logger_all.info("[Promote admin response : ]");
                                    response_json = {
                                        "request_id": req.body.request_id,
                                        "response_code": 1,
                                        "response_status": 200,
                                        "response_msg": "Admin promoted.!!",
                                        "success": contact_id.length,
                                        "failure": not_promote_partcipants.length
                                    }
                                }

                                const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'SUCCESS' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))


                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                setTimeout(async function () {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                }, 3000);
                                return res.json(response_json)

                            }

                            catch (e) {   // Get chat catch condition
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        });

                    }
                }
            }
            // Process the arrays here, once the CSV parsing is complete
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/demote_admin",
    validator.body(AdminProDeValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var participants = req.body.participants;
            var sender_id = req.body.sender_id;
            var group_docs = req.body.group_docs;
            var user_id = req.body.user_id;
            var function_call = false;
            var contact_id = [], totalCount = 0;
            var sender_master_id, response_json, grp_id, comments;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [];
            let invalid_mobile_numbers = [];
            let not_demote_partcipants = [];
            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = new Set();
            // Check if group_docs are provided
            if (group_docs) {
                // Fetch the CSV file
                fs.createReadStream(group_docs)
                    // Read the CSV file from the stream
                    .pipe(csv({
                        headers: false
                    })) // Set headers to false since there are no column headers
                    .on('data', (row) => {
                        totalCount++;
                        const firstColumnValue = row[0];
                        // Validate mobile number format
                        const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                        // Check for duplicates
                        if (duplicateMobileNumbers.has(firstColumnValue)) {
                            not_demote_partcipants.push(firstColumnValue);
                            invalid_mobile_numbers.push(firstColumnValue);
                        } else {
                            duplicateMobileNumbers.add(firstColumnValue);
                            while (duplicateMobileNumbers.length > 0) {
                                not_demote_partcipants.push(duplicateMobileNumbers.shift());
                            }
                            if (isValidFormat) {
                                valid_mobile_numbers.push(firstColumnValue);

                            } else {
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        //  logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                while (participants.length > 0) {
                    // Remove the first element from sourceArray and add it to the end of destinationArray
                    valid_mobile_numbers.push(participants.shift());
                }
                logger_all.info(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {
                if (user_id != '1') {
                    const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                    logger_all.info("[Select query request] : " + get_plan);
                    logger_all.info("[Select query request] : " + get_plan);
                    const get_plan_result = await db.query(get_plan);
                    logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                    if (get_plan_result.length == 0) {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)
                    }
                }

                const select_sender = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
                logger_all.info(" [select query request] : " + select_sender)
                const select_sender_result = await db.query(select_sender);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_result))

                if (select_sender_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }
                else {
                    sender_master_id = select_sender_result[0].sender_master_id;

                    const select_grp_result = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp_result)
                    const select_grp_result_result = await db.query(select_grp_result);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result_result))

                    if (select_grp_result_result.length != 0) {
                        grp_id = select_grp_result_result[0].group_master_id;
                    } else {
                        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_api_log);
                        const update_api_log_result = await db.query(update_api_log);
                        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found.' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                        return res.json(response_json)
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        demote_admin()
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        demote_admin();
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {
                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))
                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {
                                    logger_all.info(err)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)
                                }
                            }
                            else {

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);
                    var res_status;
                    async function demote_admin() {
                        logger_all.info("[demote_admin function calling] ")
                        function_call = true;
                        client.getChats().then(async (chats) => {
                            try {
                                const myGroup = chats.find((chat) => chat.name === myGroupName);

                                await new Promise(resolve => setTimeout(resolve, 5000));

                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)

                                }

                                const participantsCount = myGroup.participants.length;

                                const { participantNumbers, participants } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants: [] });

                                // Loop through valid_mobile_numbers array
                                for (let i = 0; i < valid_mobile_numbers.length; i++) {
                                    var participant = valid_mobile_numbers[i];
                                    res_status = 'Y';

                                    // Check if participant number exists in the group
                                    const participantIndex = participantNumbers.indexOf(participant);
                                    if (participantIndex !== -1) {
                                        logger_all.info(`Phone number ${participant} exists in the group.`)

                                        // Get participant object
                                        const participantObject = participants[participantIndex];

                                        // Check if participant is already an admin
                                        if (!participantObject.isAdmin) {
                                            not_demote_partcipants.push(participant);
                                            comments = 'already Demoted';
                                            logger_all.info(`Phone number ${participant} is already an demotedadmin.`)

                                        } else {
                                            // Get number details for the participant
                                            contact_id.push(participant);
                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Demote the participant to admin
                                            var admin_add = await myGroup.demoteParticipants([numberDetails._serialized]);
                                            logger_all.info("[Demote admin response] : " + JSON.stringify(admin_add));
                                            comments = 'Success'

                                            // Define the group_contacts query here
                                            var group_master = `UPDATE group_master SET admin_count = admin_count-1,members_count = '${participantsCount}' WHERE group_master_id = '${grp_id}' and group_name = '${myGroupName}'`;
                                            logger_all.info("[update query request] : " + group_master);
                                            const group_master_res = await db.query(group_master);
                                            logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                                            if (admin_add.status != 200) {
                                                logger_all.info("[ Demote admin response Error:]" + JSON.stringify(admin_add));
                                                not_demote_partcipants.push(participant);
                                                res_status = 'F';
                                                comments = 'Failure'
                                            }
                                        }
                                    } else {
                                        not_demote_partcipants.push(participant);
                                        logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                    }
                                    // Define the group_contacts query here
                                    var group_contacts = `UPDATE group_contacts SET admin_status = 'R',comments = '${comments}' WHERE group_master_id = '${grp_id}' and mobile_no = '${participant}'`;
                                    logger_all.info("[update query request] : " + group_contacts);
                                    const group_contacts_result = await db.query(group_contacts);
                                    logger_all.info("[update query response] : " + JSON.stringify(group_contacts_result))

                                }

                                if (valid_mobile_numbers.length == 0) {
                                    res_status = 'F';
                                    response_json = { request_id: req.body.request_id, response_code: 201, response_status: 0, response_msg: 'Invalid File Type.' }

                                } else {
                                    logger_all.info("[Demote admin response : ]");
                                    response_json = {
                                        "request_id": req.body.request_id,
                                        "response_code": 1,
                                        "response_status": 200,
                                        "response_msg": "Admin demoted.!!",
                                        "success": contact_id.length,
                                        "failure": not_demote_partcipants.length
                                    }
                                }

                                const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'SUCCESS' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                setTimeout(async function () {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                }, 3000);
                                return res.json(response_json);
                            }
                            catch (e) {   // Get chat catch condition
                                logger_all.info(e);
                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)
                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        });

                    }
                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/only_admin_can_send_msg",
    validator.body(OnlyAdminSendMsgValidation),
    valid_user,
    async function (req, res, next) {
        try {

            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var sender_id = req.body.sender_id;
            var user_id = req.body.user_id;
            var function_call = false;
            var contact_id = []
            var sender_master_id, response_json, grp_id;

            if (user_id != '1') {
                const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                logger_all.info("[Select query request] : " + get_plan);
                logger_all.info("[Select query request] : " + get_plan);
                const get_plan_result = await db.query(get_plan);
                logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                if (get_plan_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }

                const select_sender = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
                logger_all.info(" [select query request] : " + select_sender)
                const select_sender_result = await db.query(select_sender);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_result))

                if (select_sender_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }
                else {
                    sender_master_id = select_sender_result[0].sender_master_id;

                    const select_grp_result = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp_result)
                    const select_grp_result_result = await db.query(select_grp_result);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result_result))

                    if (select_grp_result_result.length != 0) {
                        grp_id = select_grp_result_result[0].group_master_id;
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        admin_Setting()
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        admin_Setting();
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {
                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))
                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {

                                    logger_all.info(err)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)
                                }
                            }
                            else {

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);
                    async function admin_Setting() {
                        logger_all.info("[admin_Setting function calling] ")
                        function_call = true;
                        client.getChats().then(async (chats) => {
                            try {

                                const myGroup = chats.find((chat) => chat.name === myGroupName);

                                await new Promise(resolve => setTimeout(resolve, 5000));

                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)

                                }

                                const setAdminonlymsg = await myGroup.setMessagesAdminsOnly(true);

                                if (setAdminonlymsg) {
                                    const update_result = `UPDATE group_master SET is_admin_only_msg = 'Y' WHERE group_master_id = '${grp_id}' and group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_result);
                                    const update_result_result = await db.query(update_result);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_result_result))

                                    const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'SUCCESS' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success' }

                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                }
                                else {
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Failed' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Failed to edit the setting.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                }

                                setTimeout(async function () {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                }, 3000);
                                return res.json(response_json);
                            }

                            catch (e) {   // Get chat catch condition
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        });
                    }
                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/user_can_send_msg",
    validator.body(OnlyAdminSendMsgValidation),
    valid_user,
    async function (req, res, next) {
        try {

            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var sender_id = req.body.sender_id;
            var user_id = req.body.user_id;
            var function_call = false;
            var contact_id = []
            var sender_master_id, response_json, grp_id;

            if (user_id != '1') {
                const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
                logger_all.info("[Select query request] : " + get_plan);
                logger_all.info("[Select query request] : " + get_plan);
                const get_plan_result = await db.query(get_plan);
                logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

                if (get_plan_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Validity period is expired.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Validity period is expired.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }

                const select_sender = `SELECT * FROM senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`;
                logger_all.info(" [select query request] : " + select_sender)
                const select_sender_result = await db.query(select_sender);
                logger_all.info(" [select query response] : " + JSON.stringify(select_sender_result))

                if (select_sender_result.length == 0) {
                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found.' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    return res.json(response_json)
                }
                else {
                    sender_master_id = select_sender_result[0].sender_master_id;

                    const select_grp_result = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                    logger_all.info("[select query request] : " + select_grp_result)
                    const select_grp_result_result = await db.query(select_grp_result);
                    logger_all.info("[select query response] : " + JSON.stringify(select_grp_result_result))

                    if (select_grp_result_result.length != 0) {
                        grp_id = select_grp_result_result[0].group_master_id;
                    }

                    var client = new Client({
                        restartOnAuthFail: true,
                        takeoverOnConflict: true,
                        takeoverTimeoutMs: 0,
                        puppeteer: {
                            handleSIGINT: false,
                            args: [
                                '--no-sandbox',
                                '--disable-setuid-sandbox',
                                '--disable-dev-shm-usage',
                                '--disable-accelerated-2d-canvas',
                                '--no-first-run',
                                '--no-zygote',
                                '--disable-gpu'
                            ],
                            executablePath: chrome_path,
                        },
                        authStrategy: new LocalAuth(
                            { clientId: sender_id }
                        )
                    }
                    );
                    // Event: Client is disconnected
                    client.on('disconnect', (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            logger_all.info(`Client logout with reason: ${reason}`)
                            // Perform logout logic here
                        } else {
                            logger_all.info(`Client disconnected with reason: ${reason}`)
                            // Perform other cleanup or disconnection logic here
                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        admin_Setting()
                    });

                    setTimeout(async function () {
                        if (function_call == false) {

                            logger_all.info(' rescan number - ' + sender_id)
                            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                                fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                            }
                            if (fs.existsSync(`./session_copy/session-${sender_id}`)) {
                                try {
                                    fse.copySync(`./session_copy/session-${sender_id}`, `./.wwebjs_auth/session-${sender_id}`, { overwrite: true | false })
                                    logger_all.info('Folder copied successfully')

                                    client = new Client({
                                        restartOnAuthFail: true,
                                        takeoverOnConflict: true,
                                        takeoverTimeoutMs: 0,
                                        puppeteer: {
                                            handleSIGINT: false,
                                            args: [
                                                '--no-sandbox',
                                                '--disable-setuid-sandbox',
                                                '--disable-dev-shm-usage',
                                                '--disable-accelerated-2d-canvas',
                                                '--no-first-run',
                                                '--no-zygote',
                                                '--disable-gpu'
                                            ],
                                            executablePath: chrome_path,
                                        },
                                        authStrategy: new LocalAuth(
                                            { clientId: sender_id }
                                        )
                                    }
                                    );
                                    // Event: Client is disconnected
                                    client.on('disconnect', (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            logger_all.info(`Client logout with reason: ${reason}`)
                                            // Perform logout logic here
                                        } else {
                                            logger_all.info(`Client disconnected with reason: ${reason}`)
                                            // Perform other cleanup or disconnection logic here
                                        }
                                    });

                                    client.initialize();

                                    client.on('authenticated', async (data) => {
                                        logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                    });

                                    client.on('ready', async (data) => {
                                        logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                        admin_Setting();
                                    });

                                    setTimeout(async function () {
                                        if (function_call == false) {
                                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                                            logger_all.info(" [update query request] : " + update_inactive)
                                            const update_inactive_result = await db.query(update_inactive);
                                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))
                                            const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID unlinked' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                            logger_all.info("[update query request] : " + update_api_log);
                                            const update_api_log_result = await db.query(update_api_log);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID unlinked.', }
                                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                            return res.json(response_json)
                                        }
                                    }, waiting_time);
                                } catch (err) {

                                    logger_all.info(err)
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.', "success": contact_id.length, "failure": participants.length - contact_id.length }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)
                                }
                            }
                            else {

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                    }, waiting_time);
                    async function admin_Setting() {
                        logger_all.info("[admin_Setting function calling] ")
                        function_call = true;
                        client.getChats().then(async (chats) => {
                            try {

                                const myGroup = chats.find((chat) => chat.name === myGroupName);
                                await new Promise(resolve => setTimeout(resolve, 5000));
                                if (!myGroup) {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                    const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_name = '${myGroupName}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_group);
                                    const update_group_result = await db.query(update_group);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    return res.json(response_json)

                                }
                                const setAdminonlymsg = await myGroup.setMessagesAdminsOnly(false);

                                if (setAdminonlymsg) {
                                    const update_result = `UPDATE group_master SET is_admin_only_msg = 'N' WHERE group_master_id = '${grp_id}' and group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_result);
                                    const update_result_result = await db.query(update_result);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_result_result))

                                    const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'SUCCESS' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success' }

                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                }
                                else {
                                    const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Failed' WHERE request_id = '${req.body.request_id}' and response_status = 'N'`
                                    logger_all.info("[update query request] : " + update_api_log);
                                    const update_api_log_result = await db.query(update_api_log);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Failed to edit the setting.' }
                                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                }

                                setTimeout(async function () {
                                    await client.destroy();
                                    logger_all.info(" Destroy client - " + sender_id)
                                }, 3000);
                                return res.json(response_json);
                            }

                            catch (e) {   // Get chat catch condition
                                logger_all.info(e);

                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_Result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_Result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        });
                    }
                }
            }
        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

module.exports = router;