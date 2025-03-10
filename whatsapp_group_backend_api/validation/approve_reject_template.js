/*
It is used to one of which is user input validation.
approve_reject_template function to validate the user

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare approve_reject_template object
const approve_reject_template = Joi.object().keys({
  // Object Properties are define
  user_id: Joi.string().optional().label("User Id"),
  change_status: Joi.string().required().label("Change Status"),
  template_id: Joi.string().required().label("Template Id")
}).options({ abortEarly: false });
// To exports the approve_reject_template module
module.exports = approve_reject_template

