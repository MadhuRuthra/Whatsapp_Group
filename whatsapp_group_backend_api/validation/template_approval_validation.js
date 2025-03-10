/*
It is used to one of which is user input validation.
TemplateApproval function to validate the user.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare TemplateApproval object
const TemplateApproval = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  user_id: Joi.string().optional().label("User Id"),
  language: Joi.string().required().label("Language"),
  category: Joi.string().required().label("Category"),
  media_url: Joi.string().optional().label("Media Url"),
  components: Joi.array().required().label("Components"),
  code: Joi.string().required().min(9).max(9).label("Code"),
}).options({ abortEarly: false });
// To exports the TemplateApproval module
module.exports = TemplateApproval

