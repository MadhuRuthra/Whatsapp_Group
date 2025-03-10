const Joi = require("@hapi/joi");

const SendMessageSchema = Joi.object().keys({
    user_id: Joi.string().optional().label("User Id"),
    sender_id: Joi.string().required().label("Sender ID"),
    group_name: Joi.string().required().label("Group Name"),
    message: Joi.string().required().label("Message"),

}).options({ abortEarly: false });

module.exports = SendMessageSchema

