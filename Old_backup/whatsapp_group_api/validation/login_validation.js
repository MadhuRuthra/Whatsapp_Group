const Joi = require("@hapi/joi");

const LoginSchema = Joi.object().keys({
  username: Joi.string().required().label("Username"),
  password: Joi.string().required().label("Password"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = LoginSchema
