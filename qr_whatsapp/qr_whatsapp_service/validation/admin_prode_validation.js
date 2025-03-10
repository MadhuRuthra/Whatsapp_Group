// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const admin_promotion_demotion = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  user_id: Joi.string().optional().label("User Id"),
  group_name: Joi.string().required().label("Group Name"),
  sender_id: Joi.string().required().label("Sender Id"),
  participants: Joi.array().optional().label("Participants Number"),
  group_docs: Joi.string().optional().label("Group Docs"),
  remove_comments: Joi.string().optional().label("Remove Comments"),
}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = admin_promotion_demotion