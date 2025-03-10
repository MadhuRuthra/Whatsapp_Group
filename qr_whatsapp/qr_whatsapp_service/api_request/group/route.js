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
const { pool } = require("../../db_connect/postgre_connect");

const qr = require('qrcode');
const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;

const media_storage = env.MEDIA_STORAGE;
const whatsapp_link = env.WHATSAPP_LINK;

const CreateCsv = require("./create_csv");
const GetGroup = require("./get_group_details")
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
const valid_user_without_req = require("../../validation/valid_user_middleware");
const GetGroupDetailsValidation = require("../../validation/get_group_details_validation");
const AdminSettingValidation = require("../../validation/admin_setting_validation");
// get_group_details
router.get(
    "/group_latest_details",
    // validator.body(GetGroupDetailsValidation),
    valid_user_without_req,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await GetGroup.get_group_latest(req);

            logger.info("[API RESPONSE] " + JSON.stringify(result))

            res.json(result);

        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.get(
    "/get_group_details",
    validator.body(GetGroupDetailsValidation),
    valid_user_without_req,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await GetGroup.get_group(req);

            logger.info("[API RESPONSE] " + JSON.stringify(result))

            res.json(result);

        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/create_csv",
    validator.body(CreateCsvValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await CreateCsv.create_csv(req);
    logger.info("[API RESPONSE] " + JSON.stringify(result))
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
        // {
        //     "user_id":"1",
        //      "sender_numbers": "917904778285",
        //      "message": "fcdefcsd",
        //      "group_name" : "14","request_id" : "_2024056111806_716"
        //    }
        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var myGroupName = req.body.group_name;
            var sender_id = req.body.sender_numbers;
            var message_content = req.body.message;
            var image_url = req.body.image_url;
            var video_url = req.body.video_url;
            var function_call = false;
            var user_id = req.body.user_id;
            var sender_master_id, response_json, message_content, template_master_id;
            var grp_id = 0;
            var media_type = [];
            var media_urls = [];
            var group_array = myGroupName.split(",")

            if (image_url) {
                media_urls.push(image_url);
                media_type.push('IMAGE');
            }

            if (video_url) {
                media_urls.push(video_url);
                media_type.push('VIDEO');
            }

            logger.info(" [send_msg query parameters] : " + JSON.stringify(req.body));

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
                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
                logger_all.info(" [update query request] : " + update_inactive)
                const update_inactive_result = await db.query(update_inactive);
                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))


                user_id = select_sender_id_status[0].user_id;
                sender_master_id = select_sender_id_status[0].sender_master_id;


                // const select_grp = `SELECT * FROM group_master WHERE sender_master_id = '${sender_master_id}' AND group_name = '${myGroupName}' AND group_master_status = 'Y'`
                // logger_all.info("[select query request] : " + select_grp)
                // const select_grp_result = await db.query(select_grp);
                // logger_all.info("[select query response] : " + JSON.stringify(select_grp_result))

                // if (select_grp_result.length != 0) {
                //     grp_id = select_grp_result[0].group_master_id;
                // }

                // if (template_name) {
                //     const select_template = `SELECT * FROM template_master WHERE template_name = '${template_name}' AND template_status = 'Y'`
                //     logger_all.info("[select query request] : " + select_template)
                //     const select_template_result = await db.query(select_template);
                //     logger_all.info("[select query response] : " + JSON.stringify(select_template_result))
                //     if (select_template_result.length > 0) {
                //         template_message = select_template_result[0].template_message;
                //         template_master_id = select_template_result[0].template_master_id;
                //         const data = JSON.parse(template_message);
                //         var replace_msg;
                //         data.forEach(item => {
                //             const typeValue = item.type;
                //             var textValue = item.text;

                //             if (textValue.includes("<b>") || textValue.includes("<span>")) {
                //                 // Assuming textValue contains HTML text
                //                 replace_msg = textValue.replace(/<\/?b>/g, "*");
                //                 replace_msg = textValue.replace(/<\/?span>/g, "*");
                //                 message_content = replace_msg;
                //             } else {
                //                 message_content = textValue;
                //             }
                //             logger_all.info("Type:", typeValue)
                //             logger_all.info("Text:", message_content)
                //         });
                //     }
                // }

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
                        console.log(`Client logout with reason: ${reason}`);
                        // Perform logout logic here
                    } else {
                        console.log(`Client disconnected with reason: ${reason}`);
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
                        // try{
                        //     await client.destroy();
                        //     logger_all.info("client destroyed")
                        // }
                        // catch(e){

                        // }
                        logger_all.info("client destroyed")

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
                                        console.log(`Client logout with reason: ${reason}`);
                                        // Perform logout logic here
                                    } else {
                                        console.log(`Client disconnected with reason: ${reason}`);
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
                                        // try{
                                        //     await client.destroy();
                                        //     logger_all.info("client destroyed")
                                        // }
                                        // catch(e){

                                        // }
                                        logger_all.info("client destroyed")

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

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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

                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_inactive)
                            const update_inactive_result = await db.query(update_inactive);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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
                        var wtsp_grp_id = select_grp_result[0].wtsp_group_id;
                        // }
                        var grp_id = group_array[i];
                        console.log("@@@@@@@@@@" + grp_id)

                        const select_campaign_id = `SELECT * FROM compose_message_${user_id} ORDER BY compose_message_id DESC limit 1`;
                        logger_all.info("[select query request] : " + select_campaign_id)
                        const select_campaign_id_result = await db.query(select_campaign_id);
                        logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

                        if (select_campaign_id_result.length == 0) {
                            campaign_name = `ca_${user_id}_${new Date().julianDate()}_1`;
                        }
                        else {

                            let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                            logger_all.info(temp_var[temp_var.length - 1]);
                            let unique_id = parseInt(temp_var[temp_var.length - 1])
                            campaign_name = `ca_${user_id}_${new Date().julianDate()}_${unique_id + 1}`;
                        }

                        await client.getChats().then(async (chats) => {
                            try {
                                const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                                // Wait for the client to be ready
                                await new Promise(resolve => setTimeout(resolve, 5000));
                                logger_all.info(" Group name - " + JSON.stringify(myGroup))
                                if (!myGroup || myGroup.isReadOnly) {
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

                                    let res_msg, res_code, res_code_status, res_status, insert_msg_content, insert_msg_content_result;
                                    var com_media_lstid = [];

                                    const insert_msg = `INSERT INTO compose_message_${user_id} VALUES(NULL,'${user_id}','${sender_master_id}','${grp_id}','${message_content}','TEXT','${campaign_name}','N',NULL,'N',CURRENT_TIMESTAMP)`
                                    logger_all.info("[insert query request] : " + insert_msg);
                                    var insert_msg_result = await db.query(insert_msg);
                                    logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_result))

                                    for (var mediaurl = 0; mediaurl < media_urls.length; mediaurl++) {
                                        insert_msg_content = `INSERT INTO compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}',${message_content !== undefined ? `'${message_content}'` : 'NULL'},NULL,NULL,NULL,NULL,${media_urls.length !== 0 ? `'${media_urls[mediaurl]}'` : 'NULL'},${media_type.length !== 0 ? `'${media_type[mediaurl]}'` : 'NULL'},NULL,'N',CURRENT_TIMESTAMP)`
                                        logger_all.info("[insert query request] : " + insert_msg_content);
                                        insert_msg_content_result = await db.query(insert_msg_content);
                                        logger_all.info("[insert query response] : " + JSON.stringify(insert_msg_content_result))
                                        com_media_lstid.push(insert_msg_content_result.insertId);
                                    }

                                    if (media_urls.length == 0) {
                                        insert_msg_content = `INSERT INTO compose_msg_media_${user_id} VALUES(NULL,'${insert_msg_result.insertId}','${message_content}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N',CURRENT_TIMESTAMP)`
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

                                    const update_msg = `UPDATE compose_message_${user_id} SET cm_status = '${res_status}' WHERE compose_message_id = '${insert_msg_result.insertId}' AND cm_status = 'N'`
                                    logger_all.info("[update query request] : " + update_msg);
                                    const update_msg_result = await db.query(update_msg);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_msg_result))

                                    for (var last_id = 0; last_id < com_media_lstid.length; last_id++) {

                                        const update_msg_content = `UPDATE compose_msg_media_${user_id} SET cmm_status = '${res_status}' WHERE compose_msg_media_id = '${com_media_lstid[last_id]}' AND cmm_status = 'N'`

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

                                const update_msg = `UPDATE compose_message_${user_id} SET cm_status = 'F' WHERE compose_message_id = '${insert_msg_result.insertId}' AND cm_status = 'N'`
                                logger_all.info("[update query request] : " + update_msg);
                                const update_msg_result = await db.query(update_msg);
                                logger_all.info("[update query response] : " + JSON.stringify(update_msg_result))

                                for (var last_id = 0; last_id < com_media_lstid.length; last_id++) {

                                    const update_msg_content = `UPDATE compose_msg_media_${user_id} SET cmm_status = '${res_status}' WHERE compose_msg_media_id = '${com_media_lstid[last_id]}' AND cmm_status = 'N'`

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

                    const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                    logger_all.info(" [update query request] : " + update_inactive)
                    const update_inactive_result = await db.query(update_inactive);
                    logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                    const update_api_log = `UPDATE api_log SET response_status = 'Y',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`

                    logger_all.info("[update query request] : " + update_api_log);
                    const update_api_log_result = await db.query(update_api_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: "Success" }

                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                    setTimeout(async function () {
                        try {
                            await client.destroy();
                            logger_all.info("client destroyed")
                        }
                        catch (e) {

                        }
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
            var user_master_id = req.body.user_master_id;
            var constituency = 0;
            var mandal = 0;
            // var zone = 0;
            // var parliament = 0;
            var zone_name;
            var parliament_name;
            var constituency_name;

            var function_call = false;
            var sender_master_id, response_json, grp_id, contact_id = [], response_msg = [];
            var user_id = req.body.user_id;
            var grp_id = 0, totalCount = 0, available_group_count = 0;
            // Arrays to hold valid and invalid mobile numbers
            let valid_mobile_numbers = [];
            var exist_mobile_count = [];
            let participants_number = [];
            let invalid_mobile_numbers = [];
            let not_add_partcipants = [];
            // Set to store duplicate mobile numbers
            let duplicateMobileNumbers = [];
            let failed_numbers = [];

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
                        const firstColumnValue = row[0].trim();
                        // Check for duplicates
                        if (valid_mobile_numbers.includes(firstColumnValue)) {
                            duplicateMobileNumbers.push(firstColumnValue);
                        }
                        else {
                            // Validate mobile number format
                            const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                            if (isValidFormat && firstColumnValue != sender_id) {
                                valid_mobile_numbers.push(firstColumnValue);
                            } else if (firstColumnValue == sender_id) {
                                exist_mobile_count.push(firstColumnValue);
                            }
                            else {
                                invalid_mobile_numbers.push(firstColumnValue);
                            }
                        }
                    })
                    .on('error', (error) => {
                        console.error('Error:', error.message);
                    })
                    .on('end', async () => {
                        processValidMobileNumbers(valid_mobile_numbers, totalCount);
                        // console.log(valid_mobile_numbers + "valid_mobile_numbers1")
                    });
            } else {

                // for (var i =0; i<participants.length; i++) {
                //     // Remove the first element from sourceArray and add it to the end of destinationArray
                //     if(participants[i].toString() != sender_id.toString()){
                //         valid_mobile_numbers.push(participants[i]);
                //     }
                //     else{
                //         exist_mobile_count.push(participants[i])
                //     }
                // }
                for (var i = 0; i < participants.length; i++) {
                    var numbr = participants[i].trim();
                    if (valid_mobile_numbers.includes(numbr)) {
                        duplicateMobileNumbers.push(numbr);
                    }
                    else {
                        const isValidFormat = /^\d{12}$/.test(numbr) && numbr.startsWith('91') && /^[6-9]/.test(numbr.substring(2, 3));
                        if (isValidFormat && numbr != sender_id) {
                            valid_mobile_numbers.push(numbr);
                        }
                        else if (numbr == sender_id) {
                            exist_mobile_count.push(numbr);
                        }
                        else {
                            invalid_mobile_numbers.push(numbr);
                        }
                    }
                }
                console.log(valid_mobile_numbers + "valid_mobile_numbers1");
                // Call a function or perform any further processing that requires valid_mobile_numbers here
                processValidMobileNumbers(valid_mobile_numbers, participants);
            }

            async function processValidMobileNumbers(valid_mobile_numbers, participants) {

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
                    const update_staus = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
                    logger_all.info("[update query request] : " + update_staus);
                    const update_staus_result = await db.query(update_staus);
                    logger_all.info("[update query response] : " + JSON.stringify(update_staus_result))

                    sender_master_id = select_sender_result[0].sender_master_id;

                    Date.prototype.julianDate = function () {
                        var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                            i = 3 - j.length;
                        while (i-- > 0) j = 0 + j;
                        return j
                    };

                    const select_campaign_id = `SELECT * FROM group_contacts WHERE campaign_name !="cron_campaign" ORDER BY group_contacts_id DESC limit 1`
                    logger_all.info("[select query request] : " + select_campaign_id)
                    const select_campaign_id_result = await db.query(select_campaign_id);
                    logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))

                    if (select_campaign_id_result.length == 0) {
                        campaign_name = `ca_${user_id}_${new Date().julianDate()}_1`;
                    }
                    else {
                        let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                        let unique_id = parseInt(temp_var[temp_var.length - 1])
                        campaign_name = `ca_${user_id}_${new Date().julianDate()}_${unique_id + 1}`;
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
                    client.on('disconnect', async (reason) => {
                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                            console.log(`Client logout with reason: ${reason}`);
                            // Perform logout logic here
                        } else {
                            console.log(`Client disconnected with reason: ${reason}`);
                            // Perform other cleanup or disconnection logic here
                        }
                        try {
                            await client.destroy();
                            logger_all.info("client destroyed")
                        }
                        catch (e) {

                        }
                    });

                    client.initialize();

                    client.on('ready', async (data) => {
                        logger_all.info('Client is ready! - ' + sender_id);
                        create_grp();
                    });

                    setTimeout(async function () {
                        if (function_call == false) {
                            // try {
                            //     await client.destroy();
                            //     logger_all.info("client destroyed")
                            // }
                            // catch (e) {

                            // }
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
                                    client.on('disconnect', async (reason) => {
                                        if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                                            console.log(`Client logout with reason: ${reason}`);
                                            // Perform logout logic here
                                        } else {
                                            console.log(`Client disconnected with reason: ${reason}`);
                                            // Perform other cleanup or disconnection logic here
                                        }
                                        try {
                                            await client.destroy();
                                            logger_all.info("client destroyed")
                                        }
                                        catch (e) {

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
                                            // try {
                                            //     await client.destroy();
                                            //     logger_all.info("client destroyed")
                                            // }
                                            // catch (e) {

                                            // }
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

                                    // try {
                                    //     await client.destroy();
                                    //     logger_all.info("client destroyed")
                                    // }
                                    // catch (e) {

                                    // }

                                    const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                    logger_all.info(" [update query request] : " + update_inactive)
                                    const update_inactive_result = await db.query(update_inactive);
                                    logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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
                        if (user_master_id == 3) {
                            constituency = req.body.constituency_id;

                            const select_zone = `SELECT con.consti_name,parl.parl_name,zon.zone_name FROM master_constituency con 
                            left join master_parliament parl ON parl.parl_id = con.parl_id
                            LEFT JOIN master_zone zon ON zon.zone_id = parl.zone_id
                            where con.consti_id = ${constituency} and con.consti_status = 'Y';`;
                            logger_all.info(" [select query request] : " + select_zone)
                            const select_zone_result = await db.query(select_zone);
                            logger_all.info(" [select query response] : " + JSON.stringify(select_zone_result))

                            parliament_name = select_zone_result[0].parl_name;
                            zone_name = select_zone_result[0].zone_name;
                            constituency_name = select_zone_result[0].consti_name;
                        }

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
                                            failed_numbers.push(valid_mobile_numbers[i])
                                            logger_all.info('Not in whatsapp!!!');
                                            response_msg.push("Mobile number not in whatsapp")
                                        }
                                    } else {
                                        failed_numbers.push(valid_mobile_numbers[i])
                                        logger_all.info('Not found!!!');
                                        response_msg.push("Contact not found")
                                    }
                                }
                            });

                            if (contact_id.length == 0) {
                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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
                            var wtsp_grp_id = create_grp.gid._serialized;
                            var myGroup = await client.getChatById(create_grp.gid._serialized)
                            const participantsCount = myGroup.participants.length;
                            var latest_status = 'N'
                            var qr_path;
                            var another_number;

                            if (myGroup) {
                                // Get the invite code for the group
                                group_code = await myGroup.getInviteCode();
                                group_link = `${whatsapp_link + group_code}`;

                                logger_all.info(group_code, group_link);
                                var randomNumber = Math.floor(Math.random() * 900) + 100;
                                var now = new Date();

                                if (user_master_id == 3) {

                                    // const get_qr_link = `SELECT qr_url,mobile_number FROM user_zone_details WHERE user_id = '${user_id}' AND usr_zone_status = 'Y'`
                                    // logger_all.info("[select query request] : " + get_qr_link)
                                    // const get_qr_link_result = await db.query(get_qr_link);
                                    // logger_all.info("[select query response] : " + JSON.stringify(get_qr_link_result))
                                    latest_status = 'L'

                                    // another_number = get_qr_link_result[0].mobile_number
                                    // qr_path = get_qr_link_result[0].qr_url;
                                }
                                // else {

                                    qr_path = `/uploads/group_qr/${new Date().julianDate()}${now.getHours()}${now.getMinutes()}${now.getSeconds()}_${randomNumber}.png`

                                    // Generate QR code
                                    qr.toFile(media_storage + `${qr_path}`, group_link, (err) => {
                                        if (err) throw err;

                                    });
                                    logger_all.info("QR code generated successfully");
                                    qr_path = `${media_storage}${qr_path}`
                                // }
                            }
                            else {

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))
                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                                return res.json(response_json)
                            }

                            var another_admin;
                            var admin_count = 1;
                            var parti_count = contact_id.length + 1;
                            var valid_parti = contact_id.length + 1;
                            var test_flag = false;

                            // if (user_master_id == 3) {
                            //     // const update_old_grp = `UPDATE group_master SET latest_group = 'N' WHERE user_id = '${user_id}' AND latest_group = 'L'`
                            //     // logger_all.info("[update query request] : " + update_old_grp);
                            //     // const update_old_grp_result = await db.query(update_old_grp);
                            //     // logger_all.info("[update query response] : " + JSON.stringify(update_old_grp_result))

                            //     // const update_lates = `INSERT INTO public.qr_list(
                            //     //             zone, parliament, constituency, "group", latest_group, static_url, whatsapp_url, qr_url, group_status, group_entry_date)
                            //     //             VALUES ( '${zone_name}', '${parliament_name}', '${constituency_name}', '${myGroupName}', '${myGroupName}', 'http://whatsappgroupactivity.com/getACWhatsappLink/${myGroupName}', '${group_link}', '-', 'Y', CURRENT_TIMESTAMP)`
                            //     // logger_all.info("[update query request] : " + update_lates);
                            //     // const update_lates_result = await db.query(update_lates);
                            //     // logger_all.info("[update query response] : " + JSON.stringify(update_lates_result))

                            //     // let client_db;
                            //     // try {
                            //     //     client_db = await pool.connect();
                            //     //     const result = await client_db.query(`INSERT INTO public.qr_list(
                            //     //         zone, parliament, constituency, "group", latest_group, static_url, whatsapp_url, qr_url, group_status, group_entry_date)
                            //     //        VALUES ( '${zone_name}', '${parliament_name}', '${constituency_name}', '${myGroupName}', '${myGroupName}', 'http://whatsappgroupactivity.com/getACWhatsappLink/${myGroupName}', '${group_link}', '-', 'Y', CURRENT_TIMESTAMP)`);
                            //     //     //console.log(result.rows[0])
                            //     //     //           if (result.rows.length === 0) {
                            //     //     logger_all.info("[postgresql grp updated] : " + result);
                            //     //     //             // return null; // AC not found
                            //     //     //           } else {
                            //     //     //             return result.rows[0];
                            //     //     //           }
                            //     // } catch (err) {
                            //     //     logger_all.info("[postgresql grp updated error] : " + err);
                            //     // } finally {
                            //     //     if (client_db) {
                            //     //         client_db.release();
                            //     //         logger_all.info("[postgresql grp updated] : client released");
                            //     //     }
                            //     // }

                            //     // Split the string into an array of numbers
                            //     var numbersArray = another_number.split(',');

                            //     // Filter out the excluded number
                            //     var filteredNumbers = numbersArray.filter(function (num) {
                            //         return num !== sender_id;
                            //     });

                            //     // Join the filtered numbers back into a string
                            //     another_admin = filteredNumbers.join(',');
                            //     logger_all.info("another number : " +another_admin);
                            //     if (another_admin != "" && another_admin != null && another_admin.trim() != "-") {
                            //         var numberDetails = await client.getNumberId(another_admin);
                            //         logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));
                            //         admin_count = admin_count + 1

                            //         try {
                            //             var group_add = await myGroup.addParticipants([numberDetails._serialized]);
                            //             logger_all.info("add group : " + JSON.stringify(group_add));

                            //             // setTimeout(async function () {
                            //             // var admin_add = await myGroup.promoteParticipants([numberDetails._serialized]);
                            //             // logger_all.info("promote admin : " + JSON.stringify(admin_add));
                            //             // },);
                            //             parti_count = parti_count + 1;
                            //             valid_parti = valid_parti + 1;
                            //             test_flag = true;
                            //         }
                            //         catch (e) {
                            //             logger_all.info("not added !!!!!")
                            //         }
                            //     }
                            // }

                            // if (user_master_id == 3) {
                            //     let client_db;
                            //     try {
                            //         client_db = await pool.connect();
                            //         const result = await client_db.query(`INSERT INTO public.qr_list(
                            //             zone, parliament, constituency, "group", latest_group, static_url, whatsapp_url, qr_url, group_status, group_entry_date)
                            //            VALUES ( '${zone_name}', '${parliament_name}', '${constituency_name}', '${myGroupName}', '${myGroupName}', 'http://whatsappgroupactivity.com/getACWhatsappLink/${myGroupName}', '${group_link}', '-', 'Y', CURRENT_TIMESTAMP)`);
                            //         //console.log(result.rows[0])
                            //         //           if (result.rows.length === 0) {
                            //         logger_all.info("[postgresql grp updated] : " + result);
                            //         //             // return null; // AC not found
                            //         //           } else {
                            //         //             return result.rows[0];
                            //         //           }
                            //     } catch (err) {
                            //         logger_all.info("[postgresql grp updated error] : " + err);
                            //     } finally {
                            //         if (client_db) {
                            //             client_db.release();
                            //             logger_all.info("[postgresql grp updated] : client released");
                            //         }
                            //     }
                            // }

                            var insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_master_id}','${wtsp_grp_id}',${constituency == 0 ? null : constituency},${mandal == 0 ? null : mandal},'${myGroupName}','${parti_count}','${valid_parti}','${valid_mobile_numbers.length - contact_id.length}','Y','Y',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'${group_link}','${qr_path}',${admin_count},'${parti_count}','${latest_status}')`
                            // update latest in postgresql
                            logger_all.info("[insert query request] : " + insert_grp);
                            const insert_grp_result = await db.query(insert_grp);
                            logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                            var insert_rights = `INSERT INTO group_rights VALUES(NULL,'${insert_grp_result.insertId}','1','N','Y',CURRENT_TIMESTAMP)`

                            logger_all.info("[insert query request] : " + insert_rights);
                            const insert_rights_result = await db.query(insert_rights);
                            logger_all.info("[insert query response] : " + JSON.stringify(insert_rights_result))

                            const insert_admin = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','${campaign_name}','${sender_id}','${sender_id}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                            logger_all.info("[insert query request] : " + insert_admin);
                            const insert_admin_result = await db.query(insert_admin);
                            logger_all.info("[insert query response] : " + JSON.stringify(insert_admin_result))

                            // if (user_master_id == 3 && another_admin != "" && another_admin.trim() != "-") {
                            //     // await sleep(3000)
                            //     var numberDetails = await client.getNumberId(another_admin);
                            //     logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                            //     var admin_add = await myGroup.promoteParticipants([numberDetails._serialized]);
                            //     logger_all.info("promote admin : " + JSON.stringify(admin_add));
                            //     // if(test_flag){
                            //     var update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','${campaign_name}','${another_admin}','${another_admin}','Success','Y',CURRENT_TIMESTAMP,NULL,'Y')`
                            //     logger_all.info("[insert query request] : " + update_number_status);
                            //     const update_number_status_result = await db.query(update_number_status);
                            //     logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))

                            //     // }

                            // }

                            for (var k = 0; k < valid_mobile_numbers.length; k++) {

                                if (user_master_id == 3 && valid_mobile_numbers[k] == another_admin) {
                                    // if the number and default sender id are same
                                    if (test_flag) {
                                        const update_count = `UPDATE group_master SET members_count = members_count-1,total_count=total_count-1,success_count=success_count-1 WHERE group_master_id = '${insert_grp_result.insertId}' AND group_master_status = 'N'`
                                        logger_all.info("[update query request] : " + update_count);
                                        const update_count_result = await db.query(update_count);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_count_result))
                                    }
                                }
                                else {
                                    var contact_status = participants_number.includes(`${valid_mobile_numbers[k]}`) ? 'Y' : 'F';
                                    var update_number_status
                                    // if(another_admin.includes(valid_mobile_numbers[k].toString())){
                                    //     update_number_status= `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','${campaign_name}','${valid_mobile_numbers[k]}','${valid_mobile_numbers[k]}','${response_msg[k]}','${contact_status}',CURRENT_TIMESTAMP,NULL,'Y')`
                                    // }
                                    // else{
                                    update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','${campaign_name}','${valid_mobile_numbers[k]}','${valid_mobile_numbers[k]}','${response_msg[k]}','${contact_status}',CURRENT_TIMESTAMP,NULL,NULL)`
                                    // }

                                    logger_all.info("[insert query request] : " + update_number_status);
                                    const update_number_status_result = await db.query(update_number_status);
                                    logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))
                                }
                            }

                            const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_inactive)
                            const update_inactive_result = await db.query(update_inactive);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                            response_json = {
                                request_id: req.body.request_id,
                                response_code: 1,
                                response_status: 200,
                                response_msg: 'Group Created and Members Added.!!',
                                "success": participants_number,
                                "failure": failed_numbers,
                                "invalid": invalid_mobile_numbers,
                                "duplicate": duplicateMobileNumbers,
                                "exist": exist_mobile_count
                            }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                            await client.destroy();
                            logger_all.info(" Destroy client - " + sender_id)

                            return res.json(response_json)

                        }
                        catch (e) {
                            logger_all.info(e);
                            await client.destroy();
                            logger_all.info(" Destroy client - " + sender_id)

                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_inactive)
                            const update_inactive_result = await db.query(update_inactive);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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
    "/admin_setting",
    validator.body(AdminSettingValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all
            var function_call = false;

            var grp_id = req.body.group_id;
            var user_id = req.body.user_id;
            var user_master_id = req.body.user_master_id;

            var remove_participants = req.body.remove_participants;
            var remove_participants_docs = req.body.remove_participants_docs;
            var add_participants = req.body.add_participants;
            var add_participants_docs = req.body.add_participants_docs;
            var promote_participants = req.body.promote_participants;
            var demote_participants = req.body.demote_participants;
            var message_setting = req.body.message_setting;

            var sender_id;
            var wtsp_grp_id;
            var client;
            var member_count;
            var exist_add_number = [];
            var failed_add_number = [];
            var not_remove_partcipants = [];
            var not_promote_partcipants = [];
            var not_demote_partcipants = [];

            var group_docs = req.body.group_docs;
            var remove_comments = req.body.remove_comments;
            var sender_master_id, response_json, grp_id, contact_id = [];
            var totalCount = 0;

            // Arrays to hold valid and invalid mobile numbers
            var valid_remove_numbers = [];
            var invalid_remove_numbers = [];
            var duplicate_remove_numbers = [];
            var total_remove_numbers = 0;
            var remove_response = 'Success';
            var remove_success = [];

            var valid_add_numbers = [];
            var invalid_add_numbers = [];
            var duplicate_add_numbers = [];
            var total_add_numbers = 0;
            var add_response = 'Success';
            var add_success = [];

            var valid_promote_numbers = [];
            var invalid_promote_numbers = [];
            var promote_response = 'Success';
            var promote_success = [];

            var valid_demote_numbers = [];
            var invalid_demote_numbers = [];
            var demote_response = 'Success';
            var message_setting_response = 'Success';
            var demote_success = [];

            const select_sender_id = `SELECT * FROM group_master grp LEFT JOIN senderid_master snd ON snd.sender_master_id = grp.sender_master_id WHERE grp.group_master_id = '${grp_id}' AND grp.group_master_status = 'Y'`
            logger_all.info(" [select query request] : " + select_sender_id)
            const select_sender_id_status = await db.query(select_sender_id);
            logger_all.info(" [select query response] : " + JSON.stringify(select_sender_id_status))

            if (select_sender_id_status.length == 0) {

                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }

            if (select_sender_id_status[0].senderid_master_status != 'Y') {

                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not available.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_api_log);
                const update_api_log_result = await db.query(update_api_log);
                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not available.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }

            user_id = select_sender_id_status[0].user_id;
            sender_master_id = select_sender_id_status[0].sender_master_id;
            sender_id = select_sender_id_status[0].mobile_no
            wtsp_grp_id = select_sender_id_status[0].wtsp_group_id;
            member_count = select_sender_id_status[0].members_count;

            const update_staus = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'Y'`
            logger_all.info("[update query request] : " + update_staus);
            const update_staus_result = await db.query(update_staus);
            logger_all.info("[update query response] : " + JSON.stringify(update_staus_result))

            // Check if group_docs are provided
            if (remove_participants_docs || remove_participants) {
                if (remove_participants_docs) {
                    // Fetch the CSV file
                    fs.createReadStream(group_docs)
                        // Read the CSV file from the stream
                        .pipe(csv({
                            headers: false
                        })) // Set headers to false since there are no column headers
                        .on('data', (row) => {
                            total_remove_numbers++;
                            const firstColumnValue = row[0].trim();
                            // Check for duplicates
                            if (valid_remove_numbers.includes(firstColumnValue)) {
                                duplicate_remove_numbers.push(firstColumnValue);
                            }
                            else {
                                // Validate mobile number format
                                const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                                if (isValidFormat) {
                                    valid_remove_numbers.push(firstColumnValue);
                                } else {
                                    invalid_remove_numbers.push(firstColumnValue);
                                }
                            }
                        })
                        .on('error', (error) => {
                            console.error('Error:', error.message);
                        })
                        .on('end', async () => {
                            processAddSetting();
                        });
                } else {
                    var rm_array = remove_participants.split(",")
                    for (var i = 0; i < rm_array.length; i++) {
                        var numbr = rm_array[i].trim();
                        if (valid_remove_numbers.includes(numbr)) {
                            duplicate_remove_numbers.push(numbr);
                        }
                        else {
                            const isValidFormat = /^\d{12}$/.test(numbr) && numbr.startsWith('91') && /^[6-9]/.test(numbr.substring(2, 3));
                            if (isValidFormat) {
                                valid_remove_numbers.push(numbr);
                            } else {
                                invalid_remove_numbers.push(numbr);
                            }
                        }
                    }
                    console.log(valid_remove_numbers + "valid_remove_numbers");
                    // Call a function or perform any further processing that requires valid_remove_numbers here
                    processAddSetting();
                }
            }
            else {
                processAddSetting();
            }

            async function processAddSetting() {
                if (add_participants_docs || add_participants) {
                    if (add_participants_docs) {
                        // Fetch the CSV file
                        fs.createReadStream(group_docs)
                            // Read the CSV file from the stream
                            .pipe(csv({
                                headers: false
                            })) // Set headers to false since there are no column headers
                            .on('data', (row) => {
                                total_add_numbers++;
                                const firstColumnValue = row[0].trim();
                                // Check for duplicates
                                if (valid_add_numbers.includes(firstColumnValue)) {
                                    duplicate_add_numbers.push(firstColumnValue);
                                }
                                else {
                                    // Validate mobile number format
                                    const isValidFormat = /^\d{12}$/.test(firstColumnValue) && firstColumnValue.startsWith('91') && /^[6-9]/.test(firstColumnValue.substring(2, 3));
                                    if (isValidFormat) {
                                        valid_add_numbers.push(firstColumnValue);

                                    } else {
                                        invalid_add_numbers.push(firstColumnValue);
                                    }
                                }
                            })
                            .on('error', (error) => {
                                console.error('Error:', error.message);
                            })
                            .on('end', async () => {
                                processAdminSetting();
                            });
                    } else {

                        // while (add_participants.length > 0) {
                        //     // Remove the first element from sourceArray and add it to the end of destinationArray
                        //     valid_add_numbers.push(add_participants.shift());
                        // }
                        var ad_array = add_participants.split(",")
                        for (var i = 0; i < ad_array.length; i++) {
                            var numr = ad_array[i].trim();
                            if (valid_add_numbers.includes(numr)) {
                                duplicate_add_numbers.push(numr);
                            }
                            else {
                                const isValidFormat = /^\d{12}$/.test(numr) && numr.startsWith('91') && /^[6-9]/.test(numr.substring(2, 3));
                                if (isValidFormat) {
                                    valid_add_numbers.push(numr);
                                } else {
                                    invalid_add_numbers.push(numr);
                                }
                            }
                        }
                        console.log(valid_add_numbers + "valid_add_numbers");
                        // Call a function or perform any further processing that requires valid_add_numbers here
                        processAdminSetting();
                    }
                }
                else {
                    processAdminSetting();
                }
            }

            async function processAdminSetting() {

                Date.prototype.julianDate = function () {
                    var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                        i = 3 - j.length;
                    while (i-- > 0) j = 0 + j;
                    return j
                };

                if (promote_participants != "" && promote_participants != null && promote_participants != undefined) {
                    valid_promote_numbers = promote_participants.split(",")
                    console.log(valid_promote_numbers + "valid_remove_numbers");
                }
                if (demote_participants != "" && demote_participants != null && demote_participants != undefined) {
                    valid_demote_numbers = demote_participants.split(",")
                    console.log(valid_demote_numbers + "valid_remove_numbers");
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
                        console.log(`Client logout with reason: ${reason}`);
                        // Perform logout logic here
                    } else {
                        console.log(`Client disconnected with reason: ${reason}`);
                        // Perform other cleanup or disconnection logic here
                    }
                });

                client.initialize();

                client.on('ready', async (data) => {
                    logger_all.info('Client is ready! - ' + sender_id);
                    admin_setting();
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
                                        console.log(`Client logout with reason: ${reason}`);
                                        // Perform logout logic here
                                    } else {
                                        console.log(`Client disconnected with reason: ${reason}`);
                                        // Perform other cleanup or disconnection logic here
                                    }
                                });

                                client.initialize();

                                client.on('authenticated', async (data) => {
                                    logger_all.info(" [Client is Log in] : " + JSON.stringify(data));

                                });

                                client.on('ready', async (data) => {
                                    logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                                    admin_setting()
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

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

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

                            const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info(" [update query request] : " + update_inactive)
                            const update_inactive_result = await db.query(update_inactive);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred.' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    }
                }, waiting_time);

                async function admin_setting() {
                    function_call = true;
                    logger_all.info("[API RESPONSE] admin_setting Function calling")
                    var grp_created_usr;
                    client.getChats().then(async (chats) => {
                        try {

                            const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                            // const parti_count = myGroup.participants.length;
                            await new Promise(resolve => setTimeout(resolve, 5000));
                            logger_all.info(JSON.stringify(myGroup));

                            if (!myGroup || myGroup.isReadOnly) {
                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)

                                const update_group = `UPDATE group_master SET group_master_status = 'D',group_updated_date = CURRENT_TIMESTAMP WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                logger_all.info("[update query request] : " + update_group);
                                const update_group_result = await db.query(update_group);
                                logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                const update_inactive = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                                logger_all.info(" [update query request] : " + update_inactive)
                                const update_inactive_result = await db.query(update_inactive);
                                logger_all.info(" [update query response] : " + JSON.stringify(update_inactive_result))

                                const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Group not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_api_log);
                                const update_api_log_result = await db.query(update_api_log);
                                logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Group not found' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)

                            }
                            grp_created_usr = myGroup.owner.user;

                            // await client.getContacts().then(async (contacts) => {
                            const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                const number = participant.id.user;
                                result.participantNumbers.push(number);
                                result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                return result;
                            }, { participantNumbers: [], participants_details: [] });
                            var already_group_count = participantNumbers.length;
                            // var admin_count = 0;

                            // for (var k = 0; k < participants_details.length; k++) {
                            //     if (participants_details[k].isAdmin) {
                            //         admin_count = admin_count + 1;
                            //     }
                            // }

                            logger_all.info(valid_add_numbers)

                            if (valid_add_numbers.length != 0) {
                                var contact_id = [];

                                if (member_count + valid_add_numbers.length > 1000) {
                                    add_response = "Can't add more than 1000 numbers."
                                }
                                else {

                                    await client.getContacts().then(async (contacts) => {

                                        for (var i = 0; i < valid_add_numbers.length; i++) {
                                            logger_all.info(" - " + valid_add_numbers[i])

                                            // Check if the mobile number already exists in the group
                                            const numberExistsInGroup = myGroup.participants.some(
                                                (participant) => participant.id.user === valid_add_numbers[i]
                                            );

                                            if (numberExistsInGroup) {
                                                exist_add_number.push(valid_add_numbers[i]);

                                                logger_all.info(`${valid_add_numbers[i]} is already in the group.`);
                                            } else {

                                                const contactToAdd = contacts.find(
                                                    (contact) => contact.number === `${valid_add_numbers[i]}`
                                                );

                                                if (contactToAdd) {
                                                    logger_all.info("Contact Found!!!");
                                                    const sanitized_number = valid_add_numbers[i].toString().replace(/[- )(]/g, ""); // remove unnecessary chars from the number
                                                    const final_number = `${sanitized_number.substring(sanitized_number.length - 10)}`; // add 91 before the number here 91 is country code of India
                                                    const number_details = await client.getNumberId(final_number); // get mobile number details
                                                    if (number_details) {
                                                        contact_id.push(contactToAdd.id._serialized);
                                                        add_success.push(valid_add_numbers[i]);
                                                    }
                                                    else {
                                                        logger_all.info('Not in whatsapp!!!');
                                                        failed_add_number.push(valid_add_numbers[i])
                                                    }
                                                } else {
                                                    logger_all.info('Not found!!!');
                                                    failed_add_number.push(valid_add_numbers[i])
                                                }
                                            }

                                        }

                                        if (contact_id.length == 0) {
                                            logger_all.info("************")
                                            logger_all.info(contact_id)
                                            add_response = 'No contacts found'

                                            if (exist_add_number.length == valid_add_numbers.length) {
                                                logger_all.info("************")
                                                logger_all.info(contact_id)
                                                add_response = 'Already Exists Contacts'
                                            }
                                        }
                                        else {

                                            var group_add = await myGroup.addParticipants(contact_id);
                                            logger_all.info(group_add);

                                            const select_campaign_id = `SELECT * FROM compose_message_${user_id} ORDER BY compose_message_id DESC limit 1`;
                                            logger_all.info("[select query request] : " + select_campaign_id)
                                            const select_campaign_id_result = await db.query(select_campaign_id);
                                            logger_all.info("[select query response] : " + JSON.stringify(select_campaign_id_result))
                                            var campaign_name;
                                            if (select_campaign_id_result.length == 0) {
                                                campaign_name = `ca_${user_id}_${new Date().julianDate()}_1`;
                                            }
                                            else {

                                                let temp_var = select_campaign_id_result[0].campaign_name.split("_");
                                                logger_all.info(temp_var[temp_var.length - 1]);
                                                let unique_id = parseInt(temp_var[temp_var.length - 1])
                                                campaign_name = `ca_${user_id}_${new Date().julianDate()}_${unique_id + 1}`;
                                            }

                                            for (var k = 0; k < add_success.length; k++) {

                                                // const select_number = `SELECT con.campaign_name FROM group_contacts con  LEFT JOIN group_master grp ON grp.group_master_id = con.group_master_id WHERE con.mobile_no = '${valid_add_numbers[k]}' AND grp.wtsp_group_id = '${wtsp_grp_id}'  `
                                                // logger_all.info("[select query request] : " + select_number);
                                                // const select_number_result = await db.query(select_number);
                                                // logger_all.info("[select query response] : " + JSON.stringify(select_number_result))

                                                // if (select_number_result.length > 0) {

                                                //     const update_grp_count = `UPDATE group_master SET total_count = total_count+1,success_count = success_count + 1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count + 1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                                //     logger_all.info("[update query request] : " + update_grp_count);
                                                //     const update_grp_count_result = await db.query(update_grp_count);
                                                //     logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                                //     const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'Y',remove_comments = NULL,admin_status = NULL WHERE group_master_id = '${grp_id}' AND group_contacts_status != 'Y' and mobile_no = '${valid_add_numbers[k]}'`
                                                //     logger_all.info("[Update query request] : " + update_remove_members);
                                                //     const update_remove_members_result = await db.query(update_remove_members);

                                                //     logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))

                                                // } else {
                                                var contact_status = 'Y';
                                                const update_number_status = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${grp_id}','${campaign_name}','${add_success[k]}','${add_success[k]}','Success','${contact_status}',CURRENT_TIMESTAMP,NULL,NULL)`
                                                logger_all.info("[insert query request] : " + update_number_status);
                                                const update_number_status_result = await db.query(update_number_status);
                                                logger_all.info("[insert query response] : " + JSON.stringify(update_number_status_result))


                                                // }
                                            }
                                            const update_grp_count = `UPDATE group_master SET total_count = ${already_group_count}+${add_success.length},success_count= ${already_group_count}+${contact_id.length}, failure_count= failure_count+${add_success.length - contact_id.length},group_updated_date = CURRENT_TIMESTAMP,members_count = ${already_group_count}+ ${contact_id.length} WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                            logger_all.info("[update query request] : " + update_grp_count);
                                            const update_grp_count_result = await db.query(update_grp_count);
                                            logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))
                                        }
                                    });
                                }
                            }
                            await new Promise(resolve => setTimeout(resolve, 3000));

                            if (valid_remove_numbers.length != 0) {

                                const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                                const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants_details: [] });
                                var already_group_count = participantNumbers.length;
                                // var admin_count = 0;

                                // for (var k = 0; k < participants_details.length; k++) {
                                //     if (participants_details[k].isAdmin) {
                                //         admin_count = admin_count + 1;
                                //     }
                                // }

                                if (valid_remove_numbers.length > 1000) {
                                    add_response = "Can't remove more than 1000 numbers."
                                }
                                else {
                                    for (let i = 0; i < valid_remove_numbers.length; i++) {
                                        var participant = valid_remove_numbers[i];
                                        // res_status = 'Y';

                                        // Check if participant number exists in the group
                                        const participantIndex = participantNumbers.indexOf(participant);
                                        if (participantIndex !== -1 && participant != grp_created_usr) {
                                            logger_all.info(`Phone number ${participant} exists in the group.`)

                                            // Get participant object
                                            // const participantObject = participants_details[participantIndex];

                                            // // Check if participant is already an admin
                                            // if (participantObject.isAdmin) {
                                            //     logger_all.info("ContactToadminRemove + Contact Found!!!");
                                            //     // Get number details for the participant
                                            //     var numberDetails = await client.getNumberId(participant);
                                            //     logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));
                                            //     contact_id.push(participant);
                                            //     // Promote the participant to admin
                                            //     var remove_participants = await myGroup.removeParticipants([numberDetails._serialized]);
                                            //     logger_all.info("[ ContactToadminRemove ] : " + JSON.stringify(remove_participants));

                                            //     if (remove_participants.status != 200) {
                                            //         logger_all.info("[Promote admin response Error:]" + JSON.stringify(remove_participants));
                                            //         not_remove_partcipants.push(participant);
                                            //     }

                                            //     logger_all.info(" GROUP ID IS " + grp_id)
                                            //     const update_grp_count = `UPDATE group_master SET total_count = total_count-1,success_count = success_count-1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count-1,admin_count = admin_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                            //     logger_all.info("[update query request] : " + update_grp_count);
                                            //     const update_grp_count_result = await db.query(update_grp_count);
                                            //     logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                            //     const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'R',remove_comments ='${remove_comments}',admin_status = NULL WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${valid_mobile_numbers[i]}'`
                                            //     logger_all.info("[Update query request] : " + update_remove_members);
                                            //     const update_remove_members_result = await db.query(update_remove_members);

                                            //     logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))

                                            // } else {
                                            logger_all.info("ContactRemove + Contact Found!!!");
                                            // Get number details for the participant
                                            // contact_id.push(participant);
                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Promote the participant to admin
                                            var remove_participants = await myGroup.removeParticipants([numberDetails._serialized]);
                                            logger_all.info("[ ContactRemove ] : " + JSON.stringify(remove_participants));

                                            if (remove_participants.status == 200) {

                                                // const update_grp_count = `UPDATE group_master SET total_count = total_count-1,success_count= success_count-1,group_updated_date = CURRENT_TIMESTAMP,members_count = members_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                                // logger_all.info("[update query request] : " + update_grp_count);
                                                // const update_grp_count_result = await db.query(update_grp_count);
                                                // logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                                const update_admin_count = `SELECT admin_status from group_contacts WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${valid_remove_numbers[i]}'`
                                                logger_all.info("[Update query request] : " + update_admin_count);
                                                const update_admin_count_result = await db.query(update_admin_count);

                                                const update_remove_members = `UPDATE group_contacts SET group_contacts_status = 'R' WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${valid_remove_numbers[i]}'`
                                                logger_all.info("[Update query request] : " + update_remove_members);
                                                const update_remove_members_result = await db.query(update_remove_members);

                                                // if (update_admin_count_result[0].admin_status == 'Y') {
                                                //     const update_grp_count = `UPDATE group_master SET admin_count = admin_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                                //     logger_all.info("[update query request] : " + update_grp_count);
                                                //     const update_grp_count_result = await db.query(update_grp_count);
                                                //     logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                                //     // admin_count = admin_count - 1;
                                                // }

                                                remove_success.push(valid_remove_numbers[i])

                                                logger_all.info("[Update query response] : " + JSON.stringify(update_remove_members_result))
                                            }
                                            else {
                                                not_remove_partcipants.push(participant);
                                                logger_all.info(`Phone number ${participant} does not removed from the group.`)
                                            }
                                            // }
                                        } else {
                                            not_remove_partcipants.push(participant);
                                            logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                        }
                                    }

                                    const update_grp_count = `UPDATE group_master SET total_count = ${already_group_count}-${remove_success.length},success_count= ${already_group_count}-${remove_success.length},group_updated_date = CURRENT_TIMESTAMP,members_count = ${already_group_count}-${remove_success.length} WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_grp_count);
                                    const update_grp_count_result = await db.query(update_grp_count);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                }
                            }

                            await new Promise(resolve => setTimeout(resolve, 3000));

                            if (valid_promote_numbers.length != 0) {

                                const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                                const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants_details: [] });
                                var already_group_count = participantNumbers.length;
                                // var admin_count = 0;

                                // for (var k = 0; k < participants_details.length; k++) {
                                //     if (participants_details[k].isAdmin) {
                                //         admin_count = admin_count + 1;
                                //     }
                                // }

                                for (let i = 0; i < valid_promote_numbers.length; i++) {
                                    var participant = valid_promote_numbers[i];
                                    res_status = 'Y';

                                    // Check if participant number exists in the group
                                    const participantIndex = participantNumbers.indexOf(participant);
                                    if (participantIndex !== -1) {
                                        logger_all.info(`Phone number ${participant} exists in the group.`)

                                        // Get participant object
                                        const participantObject = participants_details[participantIndex];

                                        // Check if participant is already an admin
                                        if (participantObject.isAdmin) {
                                            //contact_id.push(participant);
                                            not_promote_partcipants.push(participant);

                                        } else {

                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Promote the participant to admin
                                            var admin_add = await myGroup.promoteParticipants([numberDetails._serialized]);
                                            logger_all.info("[Promote admin response] : " + JSON.stringify(admin_add));
                                            if (admin_add.status == 200) {

                                                // // Define the group_contacts query here
                                                // var group_master = `UPDATE group_master SET admin_count = admin_count+1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`;
                                                // logger_all.info("[update query request] : " + group_master);
                                                // const group_master_res = await db.query(group_master);
                                                // logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                                                var group_contacts = `UPDATE group_contacts SET admin_status = '${res_status}' WHERE group_master_id = '${grp_id}' and mobile_no = '${participant}' AND group_contacts_status = 'Y'`;

                                                promote_success.push(participant)
                                                logger_all.info("[update query request] : " + group_contacts);
                                                const group_contacts_result = await db.query(group_contacts);
                                                logger_all.info("[update query response] : " + JSON.stringify(group_contacts_result))
                                            }
                                            else {
                                                not_promote_partcipants.push(participant);
                                            }
                                        }
                                    } else {
                                        not_promote_partcipants.push(participant);

                                        logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                    }

                                }

                                // Define the group_contacts query here
                                // var group_master = `UPDATE group_master SET admin_count = ${admin_count}+${promote_success.length},group_updated_date = CURRENT_TIMESTAMP WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`;
                                // logger_all.info("[update query request] : " + group_master);
                                // const group_master_res = await db.query(group_master);
                                // logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                                // admin_count = admin_count + promote_success.length;

                            }

                            await new Promise(resolve => setTimeout(resolve, 3000));

                            if (valid_demote_numbers.length != 0) {

                                const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                                const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                    const number = participant.id.user;
                                    result.participantNumbers.push(number);
                                    result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                    return result;
                                }, { participantNumbers: [], participants_details: [] });
                                var already_group_count = participantNumbers.length;
                                // var admin_count = 0;

                                // for (var k = 0; k < participants_details.length; k++) {
                                //     if (participants_details[k].isAdmin) {
                                //         admin_count = admin_count + 1;
                                //     }
                                // }

                                for (let i = 0; i < valid_demote_numbers.length; i++) {
                                    var participant = valid_demote_numbers[i];
                                    // res_status = 'Y';

                                    // Check if participant number exists in the group
                                    const participantIndex = participantNumbers.indexOf(participant);
                                    if (participantIndex !== -1 && participant != grp_created_usr) {
                                        logger_all.info(`Phone number ${participant} exists in the group.`)

                                        // Get participant object
                                        const participantObject = participants_details[participantIndex];

                                        // Check if participant is already an admin
                                        if (!participantObject.isAdmin) {
                                            not_demote_partcipants.push(participant);
                                            logger_all.info(`Phone number ${participant} is already an demotedadmin.`)

                                        } else {
                                            var numberDetails = await client.getNumberId(participant);
                                            logger_all.info("[Phone Number Details] : " + JSON.stringify(numberDetails));

                                            // Demote the participant to admin
                                            var admin_add = await myGroup.demoteParticipants([numberDetails._serialized]);
                                            logger_all.info("[Demote admin response] : " + JSON.stringify(admin_add));

                                            // Define the group_contacts query here

                                            if (admin_add.status == 200) {
                                                // var group_master = `UPDATE group_master SET admin_count = admin_count-1 WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`;
                                                // logger_all.info("[update query request] : " + group_master);
                                                // const group_master_res = await db.query(group_master);
                                                // logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                                                var group_contacts = `UPDATE group_contacts SET admin_status = 'N' WHERE group_master_id = '${grp_id}' and mobile_no = '${participant}' AND group_contacts_status = 'Y'`;
                                                logger_all.info("[update query request] : " + group_contacts);
                                                const group_contacts_result = await db.query(group_contacts);
                                                logger_all.info("[update query response] : " + JSON.stringify(group_contacts_result))
                                                demote_success.push(participant)
                                            }
                                            else {
                                                not_demote_partcipants.push(participant);
                                            }
                                        }
                                    } else {
                                        not_demote_partcipants.push(participant);
                                        logger_all.info(`Phone number ${participant} does not exist in the group.`)
                                    }

                                }

                                // Define the group_contacts query here
                                // var group_master = `UPDATE group_master SET admin_count = ${admin_count}-${demote_success.length},group_updated_date = CURRENT_TIMESTAMP WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`;
                                // logger_all.info("[update query request] : " + group_master);
                                // const group_master_res = await db.query(group_master);
                                // logger_all.info("[update query response] : " + JSON.stringify(group_master_res))

                            }
                            if (message_setting != "" || message_setting != null) {
                                var msg_flag = false;
                                var set_status = 'N'
                                if (message_setting == 'A') {
                                    msg_flag = true;
                                    set_status = 'Y'
                                }
                                const setAdminonlymsg = await myGroup.setMessagesAdminsOnly(msg_flag);

                                if (setAdminonlymsg) {
                                    const update_result = `UPDATE group_rights SET rights_value = '${set_status}' WHERE group_master_id = '${grp_id}' and right_status = 'Y' AND setting_id = '1'`
                                    logger_all.info("[update query request] : " + update_result);
                                    const update_result_result = await db.query(update_result);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_result_result))
                                }
                                else {
                                    message_setting_response = 'Failed'
                                }

                            }


                            logger_all.info("finished")
                            await new Promise(resolve => setTimeout(resolve, 5000));

                            await client.getChats().then(async (chats) => {
                                try {
                                    await new Promise(resolve => setTimeout(resolve, 5000));
                                    const myGroup = await chats.find((chat) => chat.id._serialized === wtsp_grp_id);
                                    // const parti_count = myGroup.participants.length;
                                    logger_all.info(myGroup.name);
                                    var group_wtsp_name = myGroup.name
                                    // await client.getContacts().then(async (contacts) => {
                                    const { participantNumbers, participants_details } = myGroup.participants.reduce((result, participant) => {
                                        const number = participant.id.user;
                                        result.participantNumbers.push(number);
                                        result.participants_details.push({ number, isAdmin: participant.isAdmin });
                                        return result;
                                    }, { participantNumbers: [], participants_details: [] });
                                    var already_group_count = participantNumbers.length;
                                    var admin_count = 0;

                                    for (var k = 0; k < participants_details.length; k++) {
                                        if (participants_details[k].isAdmin) {
                                            admin_count = admin_count + 1;
                                        }
                                    }

                                    const update_all_contact = `UPDATE group_contacts SET group_contacts_status = 'T',admin_status = 'N'
                            WHERE group_master_id = '${grp_id}' AND group_contacts_status='Y'`
                                    logger_all.info(" [get query request] : " + update_all_contact)
                                    const update_all_contact_result = await db.query(update_all_contact);

                                    for (var k = 0; k < participants_details.length; k++) {

                                        logger_all.info(JSON.stringify(participants_details[k]));
                                        var participant = participants_details[k].number;

                                        const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'Y'
                                WHERE group_master_id = '${grp_id}' and mobile_no = '${participant}' AND group_contacts_status='T'`
                                        logger_all.info(" [get query request] : " + update_one_contact)
                                        const update_one_contact_result = await db.query(update_one_contact);

                                        const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}' AND group_master_id = '${grp_id}' AND group_contacts_status = 'Y'`;
                                        logger_all.info("[update query request] : " + get_members);
                                        const get_members_result = await db.query(get_members);
                                        logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                        if (get_members_result.length == 0) {
                                            const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${grp_id}','cron_campaign','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                            logger_all.info("[insert query request] : " + group_contacts);
                                            const group_contacts_result = await db.query(group_contacts);
                                            logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                        }

                                        // Check if the participant has admin privileges
                                        if (participants_details[k].isAdmin && participant != sender_id) {
                                            // const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and admin_status = 'Y'`;
                                            // logger_all.info("[update query request] : " + get_admin);
                                            // const get_admin_result = await db.query(get_admin);
                                            // logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));
                                            if (get_members_result.length != 0) {

                                                if (get_members_result[0].admin_status != 'Y') {
                                                    const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                    logger_all.info("[update query request] : " + update_group);
                                                    const update_group_result = await db.query(update_group);
                                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                }
                                            }
                                            else {
                                                const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${grp_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                logger_all.info("[update query request] : " + update_group);
                                                const update_group_result = await db.query(update_group);
                                                logger_all.info("[update query response] : " + JSON.stringify(update_group_result))

                                            }
                                        }
                                    }

                                    const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'L'
                                    WHERE group_master_id = '${grp_id}' AND group_contacts_status='T'`
                                    logger_all.info(" [get query request] : " + update_one_contact)
                                    const update_one_contact_result = await db.query(update_one_contact);

                                    const update_grp_count = `UPDATE group_master SET group_name = '${group_wtsp_name}',total_count = ${already_group_count},success_count= ${already_group_count},admin_count = ${admin_count},group_updated_date = CURRENT_TIMESTAMP,members_count = ${already_group_count} WHERE group_master_id = '${grp_id}' AND group_master_status = 'Y'`
                                    logger_all.info("[update query request] : " + update_grp_count);
                                    const update_grp_count_result = await db.query(update_grp_count);
                                    logger_all.info("[update query response] : " + JSON.stringify(update_grp_count_result))

                                }
                                catch (e) {
                                    logger_all.info(e);
                                }
                            });
                            setTimeout(async function () {
                                await client.destroy();
                                logger_all.info(" Destroy client - " + sender_id)
                            }, 3000);

                            const update_api_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_api_log);
                            const update_api_log_result = await db.query(update_api_log);
                            logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

                            const update_staus = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info("[update query request] : " + update_staus);
                            const update_staus_result = await db.query(update_staus);
                            logger_all.info("[update query response] : " + JSON.stringify(update_staus_result))

                            response_json = {
                                "request_id": req.body.request_id,
                                "response_code": 1,
                                "response_status": 200,
                                "status": { add_response, remove_response, promote_response, demote_response, message_setting_response },
                                "add": { success: add_success, exist: exist_add_number, invalid: invalid_add_numbers, duplicate: duplicate_add_numbers, failed: failed_add_number },
                                "remove": { success: remove_success, failed: not_remove_partcipants, invalid: invalid_remove_numbers, duplicate: duplicate_remove_numbers },
                                "promote": { success: promote_success, failed: not_promote_partcipants },
                                "demote": { success: demote_success, failed: not_demote_partcipants }
                            }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                        catch (e) {
                            logger_all.info(e);

                            await client.destroy();
                            logger_all.info(" Destroy client - " + sender_id)

                            const update_staus = `UPDATE senderid_master SET senderid_master_status = 'Y' WHERE mobile_no = '${sender_id}' AND senderid_master_status = 'P'`
                            logger_all.info("[update query request] : " + update_staus);
                            const update_staus_result = await db.query(update_staus);
                            logger_all.info("[update query response] : " + JSON.stringify(update_staus_result))

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

        } catch (err) {
            try {
                await client.destroy();
                logger_all.info(" Destroy client - " + sender_id)
            }
            catch (e) {

            }
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);


module.exports = router;
