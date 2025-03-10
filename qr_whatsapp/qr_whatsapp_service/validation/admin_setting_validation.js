// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const admin_setting = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  user_id: Joi.string().optional().label("User Id"),
  group_id: Joi.string().required().label("Group ID"),
  remove_participants: Joi.string().optional().label("Sender Id"),
  remove_participants_docs: Joi.string().optional().label("Participants Number"),
  add_participants: Joi.string().optional().label("Group Docs"),
  add_participants_docs: Joi.string().optional().label("Remove Comments"),
  promote_participants: Joi.string().optional().label("Group Docs"),
  demote_participants: Joi.string().optional().label("Remove Comments"),
  message_setting: Joi.string().optional().label("Remove Comments"),

}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = admin_setting