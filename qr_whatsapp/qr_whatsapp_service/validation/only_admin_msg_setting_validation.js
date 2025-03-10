// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const only_admin_msg = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  user_id: Joi.string().optional().label("User Id"),
  group_name: Joi.string().required().label("Group Name"),
  sender_id: Joi.string().required().label("Sender Id"),
}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = only_admin_msg