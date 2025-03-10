// Import the required packages and libraries
const Joi = require("@hapi/joi");
// To declare SendMessage object
const SendMessage = Joi.object().keys({
  // Object Properties are define
  request_id: Joi.string().required().label("Request ID"),
  user_id: Joi.string().optional().label("User Id"),
  group_name: Joi.string().required().label("Group Name"),
  sender_numbers: Joi.string().required().label("Sender Numbers"),
  message: Joi.string().optional().label("Message"),
  image_url: Joi.string().optional().label("Image Url"),
  video_url: Joi.string().optional().label("Video Url"),
}).options({ abortEarly: false });
// To exports the SendMessage module
module.exports = SendMessage