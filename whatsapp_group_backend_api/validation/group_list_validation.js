const Joi = require("@hapi/joi");

const SenderGroupListSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
    sender_id: Joi.string().required().label("Sender ID"),
}).options({ abortEarly: false });

module.exports = SenderGroupListSchema


