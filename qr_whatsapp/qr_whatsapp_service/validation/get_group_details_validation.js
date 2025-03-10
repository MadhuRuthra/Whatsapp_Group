// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const get_group_details = Joi.object().keys({
  user_id: Joi.string().optional().label("User Id"),
  group_id: Joi.string().required().label("Group Name")
}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = get_group_details