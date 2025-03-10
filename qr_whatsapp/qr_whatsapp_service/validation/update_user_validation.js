const Joi = require("@hapi/joi");

const updateUser = Joi.object().keys({
  user_id: Joi.string().optional().label("User ID"),
  user_name: Joi.string().optional().label("User Name"),
  user_email: Joi.string().optional().label("User Email"),
  user_mobile: Joi.string().optional().label("User Mobile Number"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = updateUser
