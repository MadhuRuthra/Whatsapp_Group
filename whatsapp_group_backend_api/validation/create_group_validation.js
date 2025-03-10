const Joi = require("@hapi/joi");

const AddGroup = Joi.object().keys({
  group_name: Joi.string().required().label("Group Name"),
  user_id: Joi.string().optional().label("User ID"),
  sender_id: Joi.string().required().label("Sender ID"),
  participants: Joi.array().optional().label("Participants"),
  group_docs: Joi.string().optional().label("Group Docs"),
  request_id: Joi.string().required().label("Request ID"),
}).options({abortEarly : false});

module.exports = AddGroup


