const Joi = require("@hapi/joi");

const SenderIDSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
}).options({ abortEarly: false });

module.exports = SenderIDSchema
