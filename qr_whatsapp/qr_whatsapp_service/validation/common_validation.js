const Joi = require("@hapi/joi");

const Common = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),

}).options({ abortEarly: false });

module.exports = Common
