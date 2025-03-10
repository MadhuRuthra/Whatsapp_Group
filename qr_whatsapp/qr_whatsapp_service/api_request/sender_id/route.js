const express = require("express");
const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const qrcode_img = require('qrcode');
const moment = require("moment")
const fse = require('fs-extra');
const fs = require('fs');
const axios = require('axios');
const env = process.env

const whatsapp_link = env.WHATSAPP_LINK;
const media_storage = env.MEDIA_STORAGE;
const qr = require('qrcode');

const mime = require('mime');
const cron = require('node-cron');
const chrome_path = env.GOOGLE_CHROME;
const waiting_time = env.WAITING_TIME;

const router = express.Router();
const GetSender = require("./sender_id_list");
const Delete = require("./delete_sender_id");
const checkSender = require("./check_sender_id");

require("dotenv").config();
const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const valid_user_request_id = require("../../validation/valid_user_middleware_with_request");
const db = require("../../db_connect/connect");

const CheckSenderValidation = require("../../validation/check_sender_id_validation");
const GetSenderValidation = require("../../validation/sender_id_validation");
const DeleteValidation = require("../../validation/delete_sender_id_validation");
const AddSenderValidation = require("../../validation/add_sender_validation");
const EditSenderValidation = require("../../validation/edit_sender_validation");

const main = require('../../logger');
const { constituency_list } = require("../list/country_list");

router.get(
    "/get_sender_ids",
    validator.body(GetSenderValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await GetSender.sender_id_list(req);

            logger.info("[API RESPONSE] " + JSON.stringify(result))
            logger_all.info("[API RESPONSE] " + JSON.stringify(result))

            res.json(result);

        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.get(
    "/check_sender_status",
    validator.body(CheckSenderValidation),
    valid_user,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await checkSender.Check_Senderid(req);

            logger.info("[API RESPONSE] " + JSON.stringify(result))
            logger_all.info("[API RESPONSE] " + JSON.stringify(result))

            res.json(result);

        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.delete(
    "/delete_sender_id",
    validator.body(DeleteValidation),
    valid_user_request_id,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            var result = await Delete.delete_sender_id(req);
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

router.put(
    "/edit_sender_id",
    validator.body(EditSenderValidation),
    valid_user_request_id,
    async function (req, res, next) {
        try {
            var logger = main.logger
            var logger_all = main.logger_all

            let user_id = req.body.user_id;
            var sender_id = req.body.sender_id;
            var profile_name = req.body.profile_name;
            var profile_image = req.body.profile_image;
            var edit_fields = '';
            var function_call_flag = false;
            var sender_number;
            var response_json;

            try {

                const select_sender_id = `SELECT sndr.sender_master_id,sndr.mobile_no FROM senderid_master sndr left join user_management usr on usr.user_id = sndr.user_id where (sndr.user_id = '${user_id}' or usr.parent_id = '${user_id}') AND sndr.sender_master_id = '${sender_id}' AND sndr.senderid_master_status != 'D'`
                logger_all.info("[Select query request] : " + select_sender_id);
                var select_sender_id_result = await db.query(select_sender_id);
                logger_all.info("[Select query response] : " + JSON.stringify(select_sender_id_result))

                if (select_sender_id_result.length == 0) {

                    const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not found' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_log_error);
                    const update_log_error_result = await db.query(update_log_error);
                    logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not found' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }

                if (!profile_image && !profile_name) {

                    const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Kindly send atleast one field to update' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_log_error);
                    const update_log_error_result = await db.query(update_log_error);
                    logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                    response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Kindly send atleast one field to update' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }

                sender_number = select_sender_id_result[0].mobile_no
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
                        { clientId: sender_number }
                    )
                });

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
                    logger_all.info(" [Client is ready] : " + client.options.authStrategy.clientId);
                    update_details()

                });


                setTimeout(async function () {
                    if (function_call_flag == false) {

                        logger_all.info(' rescan number - ' + sender_number)
                        if (fs.existsSync(`./.wwebjs_auth/session-${sender_number}`)) {
                            fs.rmdirSync(`./.wwebjs_auth/session-${sender_number}`, { recursive: true })

                        }
                        if (fs.existsSync(`./session_copy/session-${sender_number}`)) {
                            try {
                                //if (fs.existsSync(`./session_copy/session-${sender_id}`)) { 
                                fse.copySync(`./session_copy/session-${sender_number}`, `./.wwebjs_auth/session-${sender_number}`, { overwrite: true | false })
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
                                        { clientId: sender_number }
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
                                    update_details()
                                });

                                setTimeout(async function () {
                                    if (function_call_flag == false) {

                                        const update_unliked = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_number}' AND senderid_master_status != 'D'`
                                        logger_all.info(" [update query request] : " + update_unliked)
                                        const update_unliked_result = await db.query(update_unliked);
                                        logger_all.info(" [update query response] : " + JSON.stringify(update_unliked_result))

                                        const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Sender ID not ready' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                        logger_all.info("[update query request] : " + update_log_error);
                                        const update_log_error_result = await db.query(update_log_error);
                                        logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Sender ID not ready' }
                                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                        return res.json(response_json)
                                    }
                                }, waiting_time);
                            } catch (err) {
                                logger_all.info(err)

                                const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                                logger_all.info("[update query request] : " + update_log_error);
                                const update_log_error_result = await db.query(update_log_error);
                                logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred' }
                                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                                return res.json(response_json)
                            }
                        }
                        //}
                        else {

                            const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                            logger_all.info("[update query request] : " + update_log_error);
                            const update_log_error_result = await db.query(update_log_error);
                            logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                            response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred' }
                            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                            return res.json(response_json)
                        }
                    }
                }, waiting_time);

                async function update_details() {
                    function_call_flag = true;
                    if (profile_name) {
                        edit_fields += `,profile_name ='${profile_name}'`;
                        var set_profile_name = await client.setDisplayName(profile_name);
                        logger_all.info(" Profile name updated - " + profile_name + " : " + set_profile_name);

                    }

                    if (profile_image) {
                        edit_fields += `,profile_image ='${profile_image}'`;
                        var media = await MessageMedia.fromUrl(profile_image);

                        var set_profile_image = await client.setProfilePicture(media);
                        logger_all.info(" Profile image updated - " + profile_image + " : " + set_profile_image);

                    }
                    const update_sender_detail = `UPDATE senderid_master SET ${edit_fields.substring(1)} WHERE sender_master_id = '${sender_id}' AND senderid_master_status != 'D'`
                    logger_all.info("[update query request] : " + update_sender_detail);
                    var update_sender_detail_result = await db.query(update_sender_detail);
                    logger_all.info("[update query response] : " + JSON.stringify(update_sender_detail_result))

                    const update_log_error = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_log_error);
                    const update_log_error_result = await db.query(update_log_error);
                    logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                    try {
                        await client.destroy();
                        logger_all.info(" Destroy client - " + sender_number)
                    }
                    catch (e) {
                        logger_all.info(" Destroy client Error - " + e)
                    }

                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success' }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                }


            }

            catch (err) {
                // Failed - call_index_signin Sign in function
                logger_all.info(" [delete sender id error] - " + err);
                try {
                    await client.destroy();
                    logger_all.info(" Destroy client - " + sender_number)
                }
                catch (e) {
                    logger_all.info(" Destroy client Error - " + e)
                }

                const update_log_error = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Error occurred' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_log_error);
                const update_log_error_result = await db.query(update_log_error);
                logger_all.info("[update query response] : " + JSON.stringify(update_log_error_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Error occurred' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }

        } catch (err) {
            try {
                await client.destroy();
                logger_all.info(" Destroy client - " + sender_number)
            }
            catch (e) {
                logger_all.info(" Destroy client Error - " + e)
            }
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);

router.post(
    "/add_sender_id",
    validator.body(AddSenderValidation),
    valid_user_request_id,
    async function (req, res, next) {
        try {

            var logger = main.logger
            var logger_all = main.logger_all
            var user_master_id = req.body.user_master_id;

            var sender_id = req.body.mobile_number;
            var profile_name = req.body.profile_name ? req.body.profile_name : "-";
            var profile_image = req.body.profile_image ? req.body.profile_image : "-";

            var sender_id_master = 0;
            var user_id = req.body.user_id;
            var status_user = '';
            var response_json;
            var flag = false;

            // if (user_master_id == 3) {
                // zone_id = req.body.zone_id;

                // const check_number = `SELECT * from user_consti_details WHERE user_id = '${user_id}' AND mobile_number LIKE '%${sender_id}%' AND usr_consti_status = 'Y'`
                // logger_all.info(" [select query request] : " + check_number)
                // const check_number_result = await db.query(check_number);
                // logger_all.info(" [select query response] : " + JSON.stringify(check_number_result))
                // if (check_number_result.length == 0) {
                //     const update_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Enter sender ID which assigned to you.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                //     logger_all.info("[update query request] : " + update_log);
                //     const update_log_result = await db.query(update_log);
                //     logger_all.info("[update query response] : " + JSON.stringify(update_log_result))

                //     response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'Enter sender ID which assigned to you.' }
                //     logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                //     logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                //     return res.json(response_json)
                // }
            // }
            // else {
            //     const check_number = `SELECT * from user_consti_details WHERE mobile_number LIKE '%${sender_id}%' AND usr_consti_status = 'Y'`
            //     logger_all.info(" [select query request] : " + check_number)
            //     const check_number_result = await db.query(check_number);
            //     logger_all.info(" [select query response] : " + JSON.stringify(check_number_result))
            //     if (check_number_result.length != 0) {
            //         const update_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = "You can't use this sender ID." WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            //         logger_all.info("[update query request] : " + update_log);
            //         const update_log_result = await db.query(update_log);
            //         logger_all.info("[update query response] : " + JSON.stringify(update_log_result))

            //         response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: "You can't use this sender ID." }
            //         logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            //         logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

            //         return res.json(response_json)
            //     }
            // }

            const get_number = `SELECT * from senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status in ('L', 'P','Y')`
            logger_all.info(" [select query request] : " + get_number)
            const get_number_result = await db.query(get_number);
            logger_all.info(" [select query response] : " + JSON.stringify(get_number_result))

            Date.prototype.julianDate = function () {
                var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
                    i = 3 - j.length;
                while (i-- > 0) j = 0 + j;
                return j
            };

            if (get_number_result.length == 0) {

                if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                    fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
                }

                // initialize client with mobile number
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

                });
                // Event: Client is disconnected
                client.on('disconnect', async (reason) => {
                    if (reason === 'replaced' || reason === 'invalid-session' || reason === 'forced-logout') {
                        console.log(`Client logout with reason: ${reason}`);
                        // Perform logout logic here
                    } else {
                        console.log(`Client disconnected with reason: ${reason}`);
                        // Perform other cleanup or disconnection logic here
                    }
                    await client.destroy();
                });

                client.initialize();

                // get the QR code by socket
                client.on('qr', async (qr) => {
                    // Generate and scan this code with your phone
                    logger_all.info(" [get QR code success response] : " + qr);
                    qrcode.generate(qr, { small: true });

                    const qrOption = {
                        margin: 7,
                        width: 175
                    };
                    const qrString = qr;
                    const bufferImage = await qrcode_img.toDataURL(qrString, qrOption);

                    const get_number_status = `SELECT * from senderid_master WHERE mobile_no = '${sender_id}' ORDER BY sender_master_id DESC`
                    logger_all.info(" [select query request] : " + get_number_status)
                    const get_number_status_result = await db.query(get_number_status);
                    logger_all.info("existsSyncexistsSync [select query response] : " + JSON.stringify(get_number_status_result))

                    status_user = 'Y'

                    if (get_number_status_result.length == 0) {
                        const insert_new_sender = `INSERT INTO senderid_master VALUES(NULL,${user_id},${sender_id},'${profile_name}','${profile_image}','N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`
                        logger_all.info(" [insert query request] : " + insert_new_sender)
                        const insert_new_sender_result = await db.query(insert_new_sender);
                        logger_all.info(" [insert query response] : " + JSON.stringify(insert_new_sender_result))
                        sender_id_master = insert_new_sender_result.insertId;

                    }
                    else {

                        if (get_number_status_result[0].senderid_master_status == 'D') {
                            const insert_deleted_sender = `INSERT INTO senderid_master VALUES(NULL,${user_id},${sender_id},'${profile_name}','${profile_image}','N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`
                            logger_all.info(" [insert query request] : " + insert_deleted_sender)
                            const insert_deleted_sender_result = await db.query(insert_deleted_sender);
                            logger_all.info(" [insert query response] : " + JSON.stringify(insert_deleted_sender_result))
                            sender_id_master = insert_deleted_sender_result.insertId;

                        }
                        else {
                            sender_id_master = get_number_status_result[0].sender_master_id;
                        }
                    }
                    setTimeout(async function () {
                        if (!flag) {
                            await client.destroy();
                            logger_all.info("client destroyed")
                        }
                    }, 50000);

                    const update_log = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                    logger_all.info("[update query request] : " + update_log);
                    const update_log_result = await db.query(update_log);
                    logger_all.info("[update query response] : " + JSON.stringify(update_log_result))

                    response_json = { request_id: req.body.request_id, response_code: 1, response_status: 200, response_msg: 'Success', "qr_code": bufferImage }
                    logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                    logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                    return res.json(response_json)
                });

                client.on('ready', async () => {
                    flag = true;
                    logger_all.info(" Client is ready - " + sender_id)
                    var qr_number = client.info.wid.user;
                    if (profile_name == "-") {
                        profile_name = client.info.pushname
                    }

                    if (`${qr_number}` == `${sender_id}`) {

                        /* const update_active = `UPDATE senderid_master SET senderid_master_status = '${status_user}' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                         logger_all.info(" [update query request] : " + update_active)
                         const update_active_result = await db.query(update_active);
                         logger_all.info(" [update query response] : " + JSON.stringify(update_active_result)) */

                        const update_active_process = `UPDATE senderid_master SET senderid_master_status = 'P' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                        logger_all.info(" [update query request] : " + update_active_process)
                        const update_activeprocess_result = await db.query(update_active_process);
                        logger_all.info(" [update query response] : " + JSON.stringify(update_activeprocess_result))

                        if (fs.existsSync(`./.session_copy/session-${sender_id}`)) {
                            fs.rmdirSync(`./.session_copy/session-${sender_id}`, { recursive: true })
                        }
                        if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
                            try {
                                fse.copySync(`./.wwebjs_auth/session-${sender_id}`, `./session_copy/session-${sender_id}`, { overwrite: true | false })
                            } catch (err) {
                                console.error(err)
                            }
                        }

                        if (profile_name != "-") {
                            var set_profile_name = await client.setDisplayName(profile_name);
                            const update_profile = `UPDATE senderid_master SET profile_name = '${profile_name}' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                            logger_all.info(" [update query request] : " + update_profile)
                            const update_profile_result = await db.query(update_profile);
                            logger_all.info(" [update query response] : " + JSON.stringify(update_profile_result))

                        }
                        if (profile_image != "-") {
                            var media = await MessageMedia.fromUrl(profile_image);
                            var set_profile_image = await client.setProfilePicture(media);
                        }
                        const chats = await client.getChats();

                        const update_all_grp = `UPDATE group_master SET group_master_status = 'T'
                        WHERE sender_master_id = '${sender_id_master}' and group_master_status = 'Y'`
                        logger_all.info(" [get query request] : " + update_all_grp)
                        const update_all_grp_result = await db.query(update_all_grp);

                        for (var i = 0; i < chats.length; i++) {
                            if (chats[i].isGroup) {
                                logger_all.info(" [chats] : " + chats[i].isGroup)
                                logger_all.info(JSON.stringify(chats[i]))

                                var wtsp_grp_id = chats[i].id._serialized;
                                var latest_status = 'N'
                                var qr_path;
                                var another_number;
                                var admin_count = 0;

                                const get_frp = `SELECT * from group_master grp 
                                WHERE sender_master_id = '${sender_id_master}' AND wtsp_group_id = '${wtsp_grp_id}' and group_master_status = 'T'`
                                logger_all.info(" [get query request] : " + get_frp)
                                const get_frp_result = await db.query(get_frp);
                                var parti_length = chats[i].participants.length;

                                if (get_frp_result.length == 0) {

                                    const date = new Date(chats[i].timestamp * 1000); // Convert seconds to milliseconds
                                    logger_all.info(chats[i].timestamp);
                                    // Convert to Kolkata time (IST)
                                    // Format the date to IST (Indian Standard Time)
                                    const options = {
                                        timeZone: 'Asia/Kolkata',
                                        year: 'numeric',
                                        month: '2-digit',
                                        day: '2-digit',
                                        hour: '2-digit',
                                        minute: '2-digit',
                                        second: '2-digit'
                                    };

                                    const dateString = date.toLocaleString('en-IN', options);
                                    logger_all.info(dateString);

                                    const date1 = moment(dateString, 'DD/MM/YYYY, hh:mm:ss a').utcOffset('+05:30');

                                    const formattedDateTime = date1.format('YYYY-MM-DD HH:mm:ss');

                                    logger_all.info(formattedDateTime)
                                    try {
                                        var myGroup = await client.getChatById(wtsp_grp_id)

                                        if (myGroup || !myGroup.isReadOnly) {
                                            var grp_code = await myGroup.getInviteCode();
                                            logger_all.info(grp_code)
                                            var group_link = `${whatsapp_link + grp_code}`;
                                            // Generate QR code

                                            var randomNumber = Math.floor(Math.random() * 900) + 100;
                                            var now = new Date();

                                            // var qr_path = `/uploads/group_qr/${new Date().julianDate()}${now.getHours()}${now.getMinutes()}${now.getSeconds()}_${randomNumber}.png`

                                            // if (user_master_id == 3) {

                                            //     const get_qr_link = `SELECT qr_url,mobile_number FROM user_zone_details WHERE user_id = '${user_id}' AND usr_zone_status = 'Y'`
                                            //     logger_all.info("[select query request] : " + get_qr_link)
                                            //     const get_qr_link_result = await db.query(get_qr_link);
                                            //     logger_all.info("[select query response] : " + JSON.stringify(get_qr_link_result))
                                                latest_status = 'N'

                                            //     another_number = get_qr_link_result[0].mobile_number
                                            //     qr_path = get_qr_link_result[0].qr_url;
                                            // }
                                            // else {

                                                qr_path = `/uploads/group_qr/${new Date().julianDate()}${now.getHours()}${now.getMinutes()}${now.getSeconds()}_${randomNumber}.png`

                                                // Generate QR code
                                                qr.toFile(media_storage + `${qr_path}`, group_link, (err) => {
                                                    if (err) throw err;

                                                });
                                                logger_all.info("QR code generated successfully");
                                                qr_path = `${media_storage}${qr_path}`
                                            // }
                                            // qr.toFile(media_storage + qr_path, group_link, (err) => {
                                            //     if (err) throw err;

                                            // });
                                            // logger_all.info("QR code generated successfully");

                                            // if (user_master_id == 3) {
                                            //     const update_old_grp = `UPDATE group_master SET latest_group = 'N' WHERE user_id = '${user_id}' AND latest_group = 'L'`
                                            //     logger_all.info("[update query request] : " + update_old_grp);
                                            //     const update_old_grp_result = await db.query(update_old_grp);
                                            //     logger_all.info("[update query response] : " + JSON.stringify(update_old_grp_result))
                                            // }
                                            const insert_grp = `INSERT INTO group_master VALUES(NULL,'${user_id}','${sender_id_master}','${wtsp_grp_id}',NULL,NULL,'${chats[i].name}','${parti_length}','${parti_length}','0','Y','Y','${formattedDateTime}',CURRENT_TIMESTAMP,'${group_link}','${qr_path}',1,'${parti_length}','${latest_status}')`

                                            logger_all.info("[insert query request] : " + insert_grp);
                                            const insert_grp_result = await db.query(insert_grp);
                                            logger_all.info("[insert query response] : " + JSON.stringify(insert_grp_result))

                                            var insert_rights = `INSERT INTO group_rights VALUES(NULL,'${insert_grp_result.insertId}','1','N','Y',CURRENT_TIMESTAMP)`

                                            logger_all.info("[insert query request] : " + insert_rights);
                                            const insert_rights_result = await db.query(insert_rights);
                                            logger_all.info("[insert query response] : " + JSON.stringify(insert_rights_result))

                                            for (var k = 0; k < parti_length; k++) {

                                                logger_all.info(JSON.stringify(chats[i].participants[k]));
                                                var participant = chats[i].participants[k].id.user;

                                                const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}' AND group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y'`;
                                                logger_all.info("[update query request] : " + get_members);
                                                const get_members_result = await db.query(get_members);
                                                logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                                if (get_members_result.length == 0) {
                                                    const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${insert_grp_result.insertId}','cron_campaign','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                                    logger_all.info("[insert query request] : " + group_contacts);
                                                    const group_contacts_result = await db.query(group_contacts);
                                                    logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                                }

                                                // Check if the participant has admin privileges
                                                if (chats[i].participants[k].isAdmin) {
                                                    // const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and group_master_id = '${insert_grp_result.insertId}' and admin_status = 'Y'`;
                                                    // logger_all.info("[update query request] : " + get_admin);
                                                    // const get_admin_result = await db.query(get_admin);
                                                    // logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));
                                                    admin_count = admin_count + 1;
                                                    // if (get_members_result.length != 0) {
                                                    //     console.log(get_members_result[0].admin_status,participant)

                                                    //     if (get_members_result[0].admin_status != 'Y' && participant != sender_id) {
                                                    //         const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                    //         logger_all.info("[update query request] : " + update_group);
                                                    //         const update_group_result = await db.query(update_group);
                                                    //         logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                    //     }
                                                    // }
                                                    // else{
                                                        if (participant != sender_id) {
                                                            const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${insert_grp_result.insertId}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                            logger_all.info("[update query request] : " + update_group);
                                                            const update_group_result = await db.query(update_group);
                                                            logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                        }
                                                    // }
                                                }
                                            }
                                            const update_admin = `UPDATE group_master SET admin_count = ${admin_count}  WHERE group_master_id = '${insert_grp_result.insertId}' AND group_master_status = 'Y'`;
                                            logger_all.info("[update query request] : " + update_admin);
                                            const uupdate_admin_result = await db.query(update_admin);
                                            logger_all.info("[update query response] : " + JSON.stringify(uupdate_admin_result))

                                        }
                                        else {
                                            logger_all.info("grp not found")
                                        }
                                    }
                                    catch (e) {
                                        logger_all.info(e)
                                    }
                                }

                                else {

                                    var group_wtsp_name = chats[i].name
                                    const update_one_grp = `UPDATE group_master SET group_master_status = 'Y'
                                WHERE sender_master_id = '${sender_id_master}' AND wtsp_group_id = '${wtsp_grp_id}' and group_master_status = 'T'`
                                    logger_all.info(" [get query request] : " + update_one_grp)
                                    const update_one_grp_result = await db.query(update_one_grp);

                                    const update_grp = `UPDATE group_master SET members_count = '${parti_length}' , success_count = '${parti_length}' WHERE sender_master_id = '${sender_id_master}' AND wtsp_group_id = '${wtsp_grp_id}'`
                                    logger_all.info("[insert query request] : " + update_grp);
                                    const update_grp_result = await db.query(update_grp);
                                    logger_all.info("[insert query response] : " + JSON.stringify(update_grp_result))

                                    const update_all_contact = `UPDATE group_contacts SET group_contacts_status = 'T',admin_status = 'N'
                            WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status='Y'`
                                    logger_all.info(" [get query request] : " + update_all_contact)
                                    const update_all_contact_result = await db.query(update_all_contact);

                                    for (var k = 0; k < parti_length; k++) {

                                        logger_all.info(JSON.stringify(chats[i].participants[k]));
                                        var participant = chats[i].participants[k].id.user;

                                        const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'Y'
                                        WHERE group_master_id = '${get_frp_result[0].group_master_id}' and mobile_no = '${participant}' AND group_contacts_status='T'`
                                                logger_all.info(" [get query request] : " + update_one_contact)
                                                const update_one_contact_result = await db.query(update_one_contact);
        
                                        const get_members = `SELECT * FROM group_contacts where mobile_no = '${participant}' AND group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y'`;
                                        logger_all.info("[update query request] : " + get_members);
                                        const get_members_result = await db.query(get_members);
                                        logger_all.info("[update query response] : " + JSON.stringify(get_members_result));

                                        if (get_members_result.length == 0) {
                                            const group_contacts = `INSERT INTO group_contacts VALUES(NULL,'${user_id}','${get_frp_result[0].group_master_id}','cron_campaign','${participant}','${participant}','Success','Y',CURRENT_TIMESTAMP,NULL,NULL)`
                                            logger_all.info("[insert query request] : " + group_contacts);
                                            const group_contacts_result = await db.query(group_contacts);
                                            logger_all.info("[insert query response] : " + JSON.stringify(group_contacts_result))

                                        }

                                        // Check if the participant has admin privileges
                                        if (chats[i].participants[k].isAdmin) {
                                            // const get_admin = `SELECT admin_status FROM group_contacts where mobile_no = '${participant}' and admin_status = 'Y' AND group_master_id = '${get_frp_result[0].group_master_id}'`;
                                            // logger_all.info("[update query request] : " + get_admin);
                                            // const get_admin_result = await db.query(get_admin);
                                            // logger_all.info("[update query response] : " + JSON.stringify(get_admin_result));
                                            admin_count = admin_count + 1;
                                            if (get_members_result.length != 0) {
                                                console.log(get_members_result[0].admin_status,participant)
                                            
                                                if (get_members_result[0].admin_status != 'Y' && participant != sender_id) {
                                                    const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                    logger_all.info("[update query request] : " + update_group);
                                                    const update_group_result = await db.query(update_group);
                                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                }
                                            }
                                            else{
                                                if (participant != sender_id) {
                                                    const update_group = `UPDATE group_contacts SET admin_status = 'Y' WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status = 'Y' and mobile_no = '${participant}'`;
                                                    logger_all.info("[update query request] : " + update_group);
                                                    const update_group_result = await db.query(update_group);
                                                    logger_all.info("[update query response] : " + JSON.stringify(update_group_result))
                                                }
                                            }
                                        }
                                    }
                                    
                                    const update_one_contact = `UPDATE group_contacts SET group_contacts_status = 'L'
                                    WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_contacts_status='T'`
                                    logger_all.info(" [get query request] : " + update_one_contact)
                                    const update_one_contact_result = await db.query(update_one_contact);

                                    const update_admin = `UPDATE group_master SET admin_count = ${admin_count},group_name = '${group_wtsp_name}'  WHERE group_master_id = '${get_frp_result[0].group_master_id}' AND group_master_status = 'Y'`;
                                    logger_all.info("[update query request] : " + update_admin);
                                    const uupdate_admin_result = await db.query(update_admin);
                                    logger_all.info("[update query response] : " + JSON.stringify(uupdate_admin_result))


                                }
                            }
                        }

                        const update_one_grp = `UPDATE group_master SET group_master_status = 'D'
                        WHERE sender_master_id = '${sender_id_master}' and group_master_status = 'T'`
                        logger_all.info(" [get query request] : " + update_one_grp)
                        const update_one_grp_result = await db.query(update_one_grp);

                        const update_active = `UPDATE senderid_master SET senderid_master_status = '${status_user}' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                        logger_all.info(" [update query request] : " + update_active)
                        const update_active_result = await db.query(update_active);
                        logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))
                        await client.destroy();
                        logger_all.info("client destroyed")

                    }
                    else {
                        const update_mismatch = `UPDATE senderid_master SET senderid_master_status = 'M' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                        logger_all.info(" [update query request] : " + update_mismatch)
                        const update_mismatch_result = await db.query(update_mismatch);
                        logger_all.info(" [update query response] : " + JSON.stringify(update_mismatch_result))

                        const update_log_exists = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch Senderid' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_log_exists);
                        const update_log_exists_result = await db.query(update_log_exists);
                        logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'Mismatch Senderid' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }

                    if (status_user == '') {

                        const update_log_exists = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'User already exists' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                        logger_all.info("[update query request] : " + update_log_exists);
                        const update_log_exists_result = await db.query(update_log_exists);
                        logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_result))

                        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'User already exists' }
                        logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                        logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                        return res.json(response_json)
                    }
                });

                client.on('disconnected', async (reason) => {
                    const update_disconn = `UPDATE senderid_master SET senderid_master_status = 'X' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
                    logger_all.info(" [update query request] : " + update_disconn)
                    const update_disconn_result = await db.query(update_disconn);
                    logger_all.info(" [update query response] : " + JSON.stringify(update_disconn_result))

                    // Destroy and reinitialize the client when disconnected
                    await client.destroy();
                });
            }
            else {
                logger_all.info(" [Number already available] : " + sender_id)

                const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'QRcode already scanned.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger_all.info("[update query request] : " + update_log_exists_2);
                const update_log_exists_2_result = await db.query(update_log_exists_2);
                logger_all.info("[update query response] : " + JSON.stringify(update_log_exists_2_result))

                response_json = { request_id: req.body.request_id, response_code: 0, response_status: 202, response_msg: 'QRcode already scanned.' }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))

                return res.json(response_json)
            }


        } catch (err) {
            console.error(`Error while getting data`, err.message);
            next(err);
        }
    }
);
module.exports = router;
