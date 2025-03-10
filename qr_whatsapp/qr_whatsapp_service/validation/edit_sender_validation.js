const Joi = require("@hapi/joi");

const EditSender = Joi.object().keys({
  sender_id: Joi.string().required().label("Sender ID"),
  profile_name: Joi.string().optional().label("Profile name"),
  profile_image: Joi.string().optional().label("Profile image"),
  request_id: Joi.string().required().label("Request ID"),

}).options({abortEarly : false});

module.exports = EditSender


