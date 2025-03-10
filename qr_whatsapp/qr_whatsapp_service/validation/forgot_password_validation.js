const Joi = require("@hapi/joi");

const ForgotPass = Joi.object().keys({
  user_mobile: Joi.string().required().label("User Mobile"),
  user_password: Joi.string().required().label("User Password"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = ForgotPass


