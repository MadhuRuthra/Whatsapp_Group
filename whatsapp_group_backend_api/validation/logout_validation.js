const Joi = require("@hapi/joi");

const LogoutSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
  request_id: Joi.string().required().label("Request ID"),

}).options({ abortEarly: false });

module.exports = LogoutSchema