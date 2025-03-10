const Joi = require("@hapi/joi");

const ChangePass = Joi.object().keys({
  user_id: Joi.string().optional().label("User ID"),
  new_password: Joi.string().required().label("User New Password"),
  old_password: Joi.string().required().label("User Old Password"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = ChangePass


