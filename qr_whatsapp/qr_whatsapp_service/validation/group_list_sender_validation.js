// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const group_list_sender = Joi.object().keys({
  // Object Properties are define
  sender_id: Joi.string().required().label("Sender ID"),
  user_id: Joi.string().optional().label("User Id"),
}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = group_list_sender