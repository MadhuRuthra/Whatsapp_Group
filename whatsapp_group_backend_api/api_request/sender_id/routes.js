const express = require("express");
const { Client, LocalAuth, Buttons, MessageMedia, Location, List } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const qrcode_img = require('qrcode');
const moment = require("moment")
const fse = require('fs-extra');
const fs = require('fs');
const env = process.env

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

      var sender_id = req.body.mobile_number;
      var profile_name = req.body.profile_name;
      var profile_image = req.body.profile_image;

      var user_id = req.body.user_id;
      var status_user = '';
      var response_json;
      var whatsapp_no_avail_count = 0;
      var whatsapp_no_max_count = 0;
      var one_month_before_day = moment(new Date()).subtract(30, 'days').format("YYYY-MM-DD HH:mm:ss");

      //   const get_user_credits = `Select plnmas.whatsapp_no_max_count from user_management usr 
      // LEFT JOIN user_plans plan ON plan.user_id = usr.user_id
      // LEFT JOIN plan_master plnmas ON plnmas.plan_master_id = plan.plan_master_id
      // WHERE usr.user_id ='${user_id}' and usr.usr_mgt_status = 'Y' AND plan.user_plans_entdate BETWEEN '${one_month_before_day}' AND CURRENT_TIMESTAMP ORDER BY plan.user_plans_entdate;`
      //   logger_all.info("[Select query request] : " + get_user_credits);
      //   const get_user_credits_result = await db.query(get_user_credits);
      //   logger_all.info("[Select query response] : " + JSON.stringify(get_user_credits_result))

      //   if (get_user_credits_result.length != 0) {
      //     whatsapp_no_max_count = get_user_credits_result[0].whatsapp_no_max_count;
      //   }


      const get_plan = `SELECT * FROM plans_update where plan_status = 'Y' and user_id = '${user_id}' and plan_expiry_date > CURRENT_TIMESTAMP`;
      logger_all.info("[Select query request] : " + get_plan);
      logger_all.info("[Select query request] : " + get_plan);
      const get_plan_result = await db.query(get_plan);
      logger_all.info("[Select query response] : " + JSON.stringify(get_plan_result))

      if (get_plan_result.length > 0) {
        available_group_count = get_plan_result[0].available_group_count;
      }

      if (available_group_count <= 0) {
        const update_api_log = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'No available credit to Add Senderid.' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
        logger_all.info("[update query request] : " + update_api_log);
        const update_api_log_result = await db.query(update_api_log);
        logger_all.info("[update query response] : " + JSON.stringify(update_api_log_result))

        response_json = { request_id: req.body.request_id, response_code: 0, response_status: 201, response_msg: 'No available credit to Add Senderid.' }
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
      }

      
      const get_number = `SELECT * from senderid_master WHERE mobile_no = '${sender_id}' AND senderid_master_status in ('L', 'Y')`
      logger_all.info(" [select query request] : " + get_number)
      const get_number_result = await db.query(get_number);
      logger_all.info(" [select query response] : " + JSON.stringify(get_number_result))

      if (get_number_result.length == 0) {

        if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
          fs.rmdirSync(`./.wwebjs_auth/session-${sender_id}`, { recursive: true })
        }

        // initialize client with mobile number
        const client = new Client({
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
          logger_all.info(" [select query response] : " + JSON.stringify(get_number_status_result))

          status_user = 'Y'

          if (get_number_status_result.length == 0) {
            const insert_new_sender = `INSERT INTO senderid_master VALUES(NULL,${user_id},${sender_id},'${profile_name}','${profile_image}','N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`
            logger_all.info(" [insert query request] : " + insert_new_sender)
            const insert_new_sender_result = await db.query(insert_new_sender);
            logger_all.info(" [insert query response] : " + JSON.stringify(insert_new_sender_result))

          }
          else {

            if (get_number_status_result[0].senderid_master_status == 'D') {
              const insert_deleted_sender = `INSERT INTO senderid_master VALUES(NULL,${user_id},${sender_id},'${profile_name}','${profile_image}','N',CURRENT_TIMESTAMP,'0000-00-00 00:00:00')`
              logger_all.info(" [insert query request] : " + insert_deleted_sender)
              const insert_deleted_sender_result = await db.query(insert_deleted_sender);
              logger_all.info(" [insert query response] : " + JSON.stringify(insert_deleted_sender_result))

            }
          }

          setTimeout(async function () {
            await client.destroy();
            logger_all.info("client destroyed")

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
          logger_all.info(" Client is ready - " + sender_id)
          var qr_number = client.info.wid.user;
          if (`${qr_number}` == `${sender_id}`) {

            const update_active = `UPDATE senderid_master SET senderid_master_status = '${status_user}' WHERE mobile_no = '${sender_id}' AND senderid_master_status != 'D'`
            logger_all.info(" [update query request] : " + update_active)
            const update_active_result = await db.query(update_active);
            logger_all.info(" [update query response] : " + JSON.stringify(update_active_result))

            // Update plans_update table
            const plans_update = ` UPDATE plans_update SET available_whatsapp_count = available_whatsapp_count - 1,used_whatsapp_count = used_whatsapp_count + 1 WHERE user_id = user_id_param AND plan_status = 'Y'`;

            logger_all.info("[update query request] : " + plans_update);
            const plans_update_result = await db.query(plans_update);
            logger_all.info("[update query response] : " + JSON.stringify(plans_update_result))


            if (fs.existsSync(`./.session_copy/session-${sender_id}`)) {
              fs.rmdirSync(`./.session_copy/session-${sender_id}`, { recursive: true })
            }
            if (fs.existsSync(`./.wwebjs_auth/session-${sender_id}`)) {
              // fs.rmdirSync(`./.wwebjs_auth/session-${sender_numbers[c]}`, { recursive: true })

              try {
                fse.copySync(`./.wwebjs_auth/session-${sender_id}`, `./session_copy/session-${sender_id}`, { overwrite: true | false })
              } catch (err) {
                console.error(err)
              }
            }

            var set_profile_name = await client.setDisplayName(profile_name);
            var media = await MessageMedia.fromUrl(profile_image);
            var set_profile_image = await client.setProfilePicture(media);
            logger_all.info(" Set profile name and image : " + profile_name + " - " + profile_image)
            logger_all.info(" Set profile name and image : " + set_profile_name + " - " + set_profile_image)

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

          await client.destroy();

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

        const update_log_exists_2 = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'QRcode already scanned' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
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
