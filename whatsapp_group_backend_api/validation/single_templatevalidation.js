/*
It is used to one of which is user input validation.
getTemplateNumber function to validate the user.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare getTemplateNumber object
const getTemplateNumber = Joi.object().keys({
// Object Properties are define
  user_id: Joi.string().optional().label("User Id"),
  template_name: Joi.string().required().label("Tempalte Name"),
  template_lang: Joi.string().optional().label("Tempalate Lang"),
  mobile_number: Joi.string().required().label("Mobile No"),
}).options({abortEarly : false});
// To exports the getTemplateNumber module
module.exports = getTemplateNumber

