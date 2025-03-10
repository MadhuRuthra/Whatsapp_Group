const Joi = require("@hapi/joi");

const AddGroup = Joi.object().keys({
  group_name: Joi.string().required().label("Group Name"),
  user_id: Joi.string().optional().label("User ID"),
  sender_id: Joi.string().required().label("Sender ID"),
  participants_name: Joi.array().required().label("Participants"),
  request_id: Joi.string().required().label("Request ID"),
 participants_number: Joi.array().required().label("Participants Number"),
}).options({abortEarly : false});

module.exports = AddGroup


