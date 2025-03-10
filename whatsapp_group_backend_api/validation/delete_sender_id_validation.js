const Joi = require("@hapi/joi");

const DeleteSender = Joi.object().keys({
  user_id: Joi.string().optional().label("User ID"),
  sender_id: Joi.string().required().label("Sender ID"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = DeleteSender


