/*
It is used to one of which is user input validation.
deleteTemplate function to validate the user.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/
// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare deleteTemplate object
const deleteTemplate = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  template_id: Joi.string().required().label("Template Id"),
}).options({ abortEarly: false });
// To exports the deleteTemplate module
module.exports = deleteTemplate

