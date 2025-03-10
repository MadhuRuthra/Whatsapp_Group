const express = require("express");
const router = express.Router();
require("dotenv").config();
// Import the report functions page
const Template = require("./template_api");
const TemplateNumbers = require("./template_number_api");
const deleteTemplate = require("./delete_template");
const getSingleTemplate = require("./single_template");
const single_template = require("./single_template");
// Import the validation page
const getTemplateValidation = require("../../validation/get_template_validation");
const getTemplateNumberValidation = require("../../validation/get_template_number_validation");
const createTemplateValidation = require("../../validation/template_approval_validation");
const single_templatevalidation = require("../../validation/single_templatevalidation");
const deleteTemplateValidation = require("../../validation/delete_template_validation");
const getSingleTemplateValidation = require("../../validation/get_single_template_validation")
const ApproveRejectTemplateValidation = require("../../validation/approve_reject_template")
const valid_user_reqID = require("../../validation/valid_user_middleware_with_request");

// Import the default validation middleware

const validator = require('../../validation/middleware')
const valid_user = require("../../validation/valid_user_middleware");
const commonValidation = require("../../validation/common_validation");
const main = require('../../logger');
const db = require("../../db_connect/connect");

router.get(
  "/get_template",
  validator.body(commonValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var result = await Template.getTemplate(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);


router.get(
  "/get_single_template",
  validator.body(getSingleTemplateValidation),
  valid_user,
  async function (req, res, next) {
    try {
      var logger = main.logger
      var result = await getSingleTemplate.getSingleTemplate(req);

      logger.info("[API RESPONSE] " + JSON.stringify(result))

      res.json(result);

    } catch (err) {
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);


// p_get_template_numbers - start
router.post(
  "/p_get_template_numbers",
  validator.body(getTemplateNumberValidation),
  valid_user,
  async function (req, res, next) {
    try {// access the CampaignReport function
      var logger = main.logger
      var result = await TemplateNumbers.PgetTemplateNumber(req);
      logger.info("[API RESPONSE] " + JSON.stringify(result))
      res.json(result);
    } catch (err) {// any error occurres send error response to client
      console.error(`Error while getting data`, err.message);
      next(err);
    }
  }
);
// p_get_template_numbers - end

// create_template - start
router.post(
  "/create_template",
  validator.body(createTemplateValidation),
  valid_user_reqID,
  valid_user,
  async function (req, res, next) {

    try {
      var logger = main.logger
      var logger_all = main.logger_all;
      var day = new Date();
      // get current_year to generate a template name
      var current_year = day.getFullYear().toString();

      // get today's julian date to generate template name
      Date.prototype.julianDate = function () {
        var j = parseInt((this.getTime() - new Date('Dec 30,' + (this.getFullYear() - 1) + ' 23:00:00').getTime()) / 86400000).toString(),
          i = 3 - j.length;
        while (i-- > 0) j = 0 + j;
        return j
      };

      // get all the data from the api body and headers
      let language = req.body.language;
      let temp_category = req.body.category;
      let temp_components = req.body.components;
      let temp_details = req.body.code;
      let media_url = req.body.media_url;
      let user_id = req.body.user_id;
      var user_short_name;
      var insert_template_id;
      //  initialize required variable and arrays.
      var succ_array = [];
      var error_array = [];
      var count = 0;
      var variable_count = 0;
      var user_short_name;
      var parent_id;
      var parent_user_name;
      var parent_short_name;
      var full_short_name;
      var user_master_id;
      var unique_id;
      var h_file;
      var media_type;
      var response_json;

      // get the given user's master short name 
      var get_user_details = `SELECT * FROM user_management WHERE user_id = '${user_id}' AND usr_mgt_status = 'Y'`;
      logger_all.info("[select query request] : " + get_user_details)
      const get_user_details_result = await db.query(get_user_details);
      logger_all.info("[select query response] : " + JSON.stringify(get_user_details_result))

      if (get_user_details_result.length > 0) {
        user_master_id = get_user_details_result[0].user_master_id;
        user_name = get_user_details_result[0].user_name;
        user_short_name = user_name.slice(0, 3);
        parent_id = get_user_details_result[0].parent_id;

        if (user_master_id == 1 || user_master_id == '1') {
          full_short_name = user_short_name;
        }
        else {
          var get_parent_details = `SELECT * FROM user_management WHERE user_id = '${parent_id}' AND usr_mgt_status = 'Y'`;
          logger_all.info("[select query request] : " + get_parent_details)
          const get_parent_details_result = await db.query(get_parent_details);
          logger_all.info("[select query response] : " + JSON.stringify(get_parent_details_result))

          parent_user_name = get_parent_details_result[0].user_name;
          parent_short_name = parent_user_name.slice(0, 3);
          full_short_name = `${parent_short_name}_${user_short_name}`;
        }
      }

      // get the unique_serial_number to generate unique template name
      var get_template_id = `SELECT unique_template_id FROM template_master ORDER BY template_master_id DESC limit 1`;
      logger_all.info("[select query request] : " + get_template_id)
      const get_unique_id = await db.query(get_template_id);
      logger_all.info("[select query response] : " + JSON.stringify(get_unique_id))

      // if nothing returns this is going to be a first template so make it as 001
      if (get_unique_id.length == 0) {
        unique_id = '001'
      }
      else {
        // get the serial_number of the latest template
        var serial_id = get_unique_id[0].unique_template_id.substr(get_unique_id[0].unique_template_id.length - 3)
        var temp_id = parseInt(serial_id) + 1;

        // add 0 as per our need
        if (temp_id.toString().length == 1) {
          unique_id = '00' + temp_id;
        }
        if (temp_id.toString().length == 2) {
          unique_id = '0' + temp_id;
        }
        if (temp_id.toString().length == 3) {
          unique_id = temp_id;
        }
      }

      var tmp_details;
      var tmp_details_test;

      // if receive media_url get the media type of the media
      if (media_url) {
        h_file = await getHeaderFile.getHeaderFile(media_url);
      }

      // check the template code is received to make the pld code work
      if (!temp_details) {

        // initialize the code 
        tmp_details = '000000000';

        // function to set the character ina string at a specific position
        function setCharAt(index, chr) {
          if (index > tmp_details.length - 1) return tmp_details;
          tmp_details = tmp_details.substring(0, index) + chr + tmp_details.substring(index + 1);
          return tmp_details.substring(0, index) + chr + tmp_details.substring(index + 1);
        }

        // check the template have english text or other language, media or not, buttons - to validate the template have all of the components as mentioned in the template_code.
        // if it is not same, then something is missing we send a error response to client
        for (var p = 0; p < temp_components.length; p++) {
          // check the body have variables and the template language is english or not
          if (temp_components[p]['type'] == 'body' || temp_components[p]['type'] == 'BODY') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            if (temp_components[p]['example']) {
              variable_count = temp_components[p]['example']['body_text'][0].length
            }
            if (language == 'en_US' || language == 'en_GB') {
              setCharAt(0, "t");
            }
            else {
              setCharAt(0, "l");
            }
          }

          // check the header has text
          if (temp_components[p]['type'] == 'HEADER') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            setCharAt(1, "h");
          }

          // check the template has footer
          if (temp_components[p]['type'] == 'FOOTER') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            setCharAt(8, "f");
          }

          // check the template has button, and which type of buttons they have.
          if (temp_components[p]['type'] == 'BUTTONS') {
            for (var b = 0; b < temp_components[p]['buttons'].length; b++) {
              if (temp_components[p]['buttons'][b]['type'] == 'URL') {
                setCharAt(6, "u");
              }
              if (temp_components[p]['buttons'][b]['type'] == 'QUICK_REPLY') {
                setCharAt(7, "r");
              }

              if (temp_components[p]['buttons'][b]['type'] == 'PHONE_NUMBER') {
                setCharAt(5, "c");
              }

            }

          }

          // check the template has which type of media
          if (media_url) {
            //h_file = await getHeaderFile.getHeaderFile(media_url);
            if (h_file[2] == 'IMAGE') {
              setCharAt(2, "i");
              media_type = 'IMAGE'
            }

            else if (h_file[2] == 'VIDEO') {
              setCharAt(3, "v");
              media_type = 'VIDEO'
            }

            else if (h_file[2] == 'DOCUMENT') {
              setCharAt(4, "d");
              media_type = 'DOCUMENT'
            }

          }
        }
      }
      // this block doing the same work as the previos block
      else {

        tmp_details_test = '000000000';
        function setCharAtTest(index, chr) {
          if (index > tmp_details_test.length - 1) return tmp_details_test;
          tmp_details_test = tmp_details_test.substring(0, index) + chr + tmp_details_test.substring(index + 1);
          return tmp_details_test.substring(0, index) + chr + tmp_details_test.substring(index + 1);
        }

        if (temp_details[2].toString() == 'i') {
          if (temp_details[3].toString() != '0' || temp_details[4].toString() != '0') {

            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger.silly("[update query request] : " + log_update);
            const log_update_result = await db.query(log_update);
            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

            response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)
          }
          media_type = 'IMAGE'
          setCharAtTest(2, "i");
        }

        else if (temp_details[3].toString() == 'v') {
          if (temp_details[2].toString() != '0' || temp_details[4].toString() != '0') {

            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger.silly("[update query request] : " + log_update);
            const log_update_result = await db.query(log_update);
            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

            response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)
          }
          media_type = 'VIDEO'
          setCharAtTest(3, "v");
        }

        else if (temp_details[4].toString() == 'd') {
          if (temp_details[3].toString() != '0' || temp_details[2].toString() != '0') {
            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger.silly("[update query request] : " + log_update);
            const log_update_result = await db.query(log_update);
            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

            response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)
          }
          media_type = 'DOCUMENT'
          setCharAtTest(4, "d");
        }

        for (var p = 0; p < temp_components.length; p++) {
          if (temp_components[p]['type'] == 'body' || temp_components[p]['type'] == 'BODY') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            if (temp_components[p]['example']) {
              variable_count = temp_components[p]['example']['body_text'][0].length
            }
            if (language == 'en_US' || language == 'en_GB') {
              setCharAtTest(0, "t");
            }
            else {
              setCharAtTest(0, "l");
            }
          }
          if (temp_components[p]['type'] == 'HEADER') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            setCharAtTest(1, "h");
          }

          if (temp_components[p]['type'] == 'FOOTER') {
            temp_components[p]['text'] = temp_components[p]['text'].replace(/&amp;/g, "&")
            setCharAtTest(8, "f");
          }
          if (temp_components[p]['type'] == 'BUTTONS') {
            for (var b = 0; b < temp_components[p]['buttons'].length; b++) {
              if (temp_components[p]['buttons'][b]['type'] == 'URL') {
                setCharAtTest(6, "u");
              }
              if (temp_components[p]['buttons'][b]['type'] == 'QUICK_REPLY') {
                setCharAtTest(7, "r");
              }

              if (temp_components[p]['buttons'][b]['type'] == 'PHONE_NUMBER') {
                setCharAtTest(5, "c");
              }

            }

          }
        }

        // if media found in the component
        if (media_type) {
          // if media type found but media url not in request media is required. so we send error response to the client
          if (!media_url) {

            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger.silly("[update query request] : " + log_update);
            const log_update_result = await db.query(log_update);
            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

            response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)

          }
          // if media_url is in the request
          else {
            // check the type of media. if we receive .mp4 file and media_type image, it is not going to work. Checked here and send error response to the client
            if (media_type == 'IMAGE' || media_type == 'VIDEO') {
              if (media_type != h_file[2]) {

                var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch media type' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
                logger.silly("[update query request] : " + log_update);
                const log_update_result = await db.query(log_update);
                logger.silly("[update query response] : " + JSON.stringify(log_update_result))

                response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch media type.', request_id: req.body.request_id }
                logger.info("[API RESPONSE] " + JSON.stringify(response_json))
                logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
                return res.json(response_json)
              }
            }
          }
        }

        else {
          // if media_type not found but we recieve media_url we send error response to the client
          if (media_url) {
            var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
            logger.silly("[update query request] : " + log_update);
            const log_update_result = await db.query(log_update);
            logger.silly("[update query response] : " + JSON.stringify(log_update_result))

            response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
            logger.info("[API RESPONSE] " + JSON.stringify(response_json))
            logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
            return res.json(response_json)
          }
        }

        // if both our template code and request template code are not same, send error response to the client
        if (tmp_details_test != temp_details) {
          var log_update = `UPDATE api_log SET response_status = 'F',response_date = CURRENT_TIMESTAMP, response_comments = 'Mismatch code' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
          logger.silly("[update query request] : " + log_update);
          const log_update_result = await db.query(log_update);
          logger.silly("[update query response] : " + JSON.stringify(log_update_result))

          response_json = { response_code: 0, response_status: 201, response_msg: 'Mismatch code', request_id: req.body.request_id }
          logger.info("[API RESPONSE] " + JSON.stringify(response_json))
          logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
          return res.json(response_json)
        }

        // if everything fine assign the recieved template code in one variable
        tmp_details = temp_details;
      }
      logger_all.info("*****************");
      // generate unique template name 
      let temp_name = `te_${full_short_name}_${tmp_details}_${current_year.substring(2)}${day.getMonth() + 1}${day.getDate()}_${unique_id}`;
      let unique_template_id = `tmplt_${full_short_name}_${new Date().julianDate()}_${unique_id}`;

      // check if the language is in our db 
      logger_all.info("[select query request] : " + `SELECT * from master_language WHERE language_code = '${language}' AND language_status = 'Y'`)
      const select_lang = await db.query(`SELECT * from master_language WHERE language_code = '${language}' AND language_status = 'Y'`);
      logger_all.info("[select query response] : " + JSON.stringify(select_lang))

      if (select_lang.length != 0) {

        // get the whatsapp business id, bearer token for the sender number from db
        var insert_msg_tmp = `INSERT INTO template_master VALUES(NULL,'${user_id}','${unique_template_id}','${temp_name}',${select_lang[0].language_id},'${temp_category}','${JSON.stringify(temp_components)}','N',CURRENT_TIMESTAMP)`;
        logger_all.info("[insert query request] : " + insert_msg_tmp)

        const insert_template = await db.query(insert_msg_tmp);

        logger_all.info("[insert query response] : " + JSON.stringify(insert_template))

        temp_lang = select_lang[0].language_id;
        insert_template_id = insert_template.insertId;
      }
      else {
        error_array.push({ reason: 'Language not available' })
      }

      // if media is in template
      if (media_url) {
        // add media json block in components
        temp_components.push({
          "type": "HEADER",
          "format": media_type,
          "example": { "header_handle": [curl_output.h] }
        })

        fs.unlinkSync(h_file[1]);

        // json for request template
        var data = {
          name: temp_name,
          language: language,
          category: temp_category,
          components: temp_components
        };

        // push the success template in succ_template
        succ_array.push({ template_id: unique_template_id, template_name: temp_name })

        // if successfully requested, then update the template status and template id
        var update_message = `UPDATE template_master SET template_status = 'Y',template_message = '${JSON.stringify(temp_components)}' WHERE template_master_id = '${insert_template_id}'`;

        logger_all.info("[update query request] : " + update_message)

        const update_succ = await db.query(update_message);
        logger_all.info("[update query response] : " + JSON.stringify(update_succ))

        // push the failed template in failed_template array
        error_array.push({ reason: error.message })

        // if any error or failure, update the template status as F
        logger_all.info("[update query request] : " + `UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`)
        const update_fail = await db.query(`UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`);
        logger_all.info("[update query response] : " + JSON.stringify(update_fail))
        // if got error when get header_handle, all template request will fail. push the all number in failed_array
        if (error !== null) {
          logger_all.info("[upload file failed number] : " + error)

          logger_all.info("[update query request] : " + `UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`)
          const update_fail = await db.query(`UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`);
          logger_all.info("[update query response] : " + JSON.stringify(update_fail))
          error_array.push({ reason: 'Image upload failed' })
        }
      }
      // if media is not in template  media finish
      else {

        // push the success template in succ_template
        succ_array.push({ template_id: unique_template_id, template_name: temp_name })

        var update_msg_tmp = `UPDATE template_master SET template_status = 'Y',template_message = '${JSON.stringify(temp_components)}' WHERE template_master_id = '${insert_template_id}'`;
        // if successfully requested, then update the template status and template id
        logger_all.info("[update query request] : " + update_msg_tmp)

        const update_succ = await db.query(update_msg_tmp);
        logger_all.info("[update query response] : " + JSON.stringify(update_succ))


        if (!update_succ.affectedRows) {

          error_array.push({ reason: "Not Affected Rows" })

          logger_all.info("[update query request] : " + `UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`)

          const update_fail = await db.query(`UPDATE template_master SET template_status = 'F' WHERE template_master_id = '${insert_template_id}'`);
          logger_all.info("[update query response] : " + JSON.stringify(update_fail))

        } else {
          var log_update = `UPDATE api_log SET response_status = 'S',response_date = CURRENT_TIMESTAMP, response_comments = 'Success' WHERE request_id = '${req.body.request_id}' AND response_status = 'N'`
          logger.silly("[update query request] : " + log_update);
          const log_update_result = await db.query(log_update);
          logger.silly("[update query response] : " + JSON.stringify(log_update_result))

          response_json = { response_code: 1, response_status: 200, response_msg: 'Success ', success: succ_array, failure: error_array, request_id: req.body.request_id }
          logger.info("[API RESPONSE] " + JSON.stringify(response_json))
          logger_all.info("[API RESPONSE] " + JSON.stringify(response_json))
          return res.json(response_json)
        }
      }
    }
    catch (e) {
      logger_all.info(e);
      // if error occurred send error response to the client
      logger_all.info("[template approval failed response] : " + e)
      next(err);
    }
  });

module.exports = router;