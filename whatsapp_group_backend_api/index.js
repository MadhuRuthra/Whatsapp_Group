// Import the required packages and libraries
const https = require("http");
const express = require("express");
const dotenv = require('dotenv');
dotenv.config();
var cors = require("cors");
const { logger, logger_all } = require('./logger')
const cron = require('node-cron');
// Database Connections
const app = express();
const port = 10015;

const Login = require("./login/route");
const Signup = require("./signup/route");
const Logout = require("./logout/route");
const SenderID = require("./api_request/sender_id/route");
const ListApi = require("./api_request/list/route");
const Report = require("./api_request/report/route");
const Passwords = require("./api_request/passwords/route");
const User = require("./api_request/user/route");
const Plans = require("./api_request/plans/route");
const Group = require("./api_request/group/route");
const Template = require("./api_request/template/route");
const Compose = require("./api_request/compose/route");
const cronfolder = require("./api_request/cron/route");

const bodyParser = require('body-parser');

// var today = new Date().toLocaleString("en-IN", {timeZone: "Asia/Kolkata"});
app.use(cors());
app.use(express.json());
app.use(
  express.urlencoded({
    extended: true,
  })
);

app.get("/", (req, res) => {
  res.json({ message: "ok" });
});

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));

// parse application/json
app.use(bodyParser.json());

app.use("/login", Login);
app.use("/signup", Signup);
app.use("/password", Passwords);
app.use("/logout", Logout);
app.use("/sender_id", SenderID);
app.use("/list", ListApi);
app.use("/report", Report);
app.use("/user", User);
app.use("/plan", Plans);
app.use("/group", Group);
app.use("/template", Template);
app.use("/compose_message", Compose);

// Schedule a cron job to run every 5 seconds
cron.schedule('0 * * * *', async () => {
  logger_all.info("Cron Running ");

  try {
    // cronfolder(); // Call the function defined in the route.js file
  } catch (error) {
    logger_all.info("Error in cron job:", error);
    console.error("Error in cron job:", error);
  }
});

//  const options = {
//    key: fs.readFileSync("/etc/letsencrypt/live/yjtec.in/privkey.pem"),
//    cert: fs.readFileSync("/etc/letsencrypt/live/yjtec.in/cert.pem")
//  };

https.createServer(app)
  .listen(port, function (req, res) {
    logger.info("Server started at port " + port);
  });
