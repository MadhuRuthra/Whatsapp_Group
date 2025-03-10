<?php
session_start();
error_reporting(0);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");

// Index Page Signin - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "signin") {
  // Get data
  $uname = htmlspecialchars(strip_tags(isset($_REQUEST['txt_username']) ? $conn->real_escape_string($_REQUEST['txt_username']) : ""));
  $password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_password']) ? $conn->real_escape_string($_REQUEST['txt_password']) : ""));
  $upass = md5($password);
  $ip_address = $_SERVER['REMOTE_ADDR'];
  site_log_generate("Index Page : Username => " . $uname . " trying to login on " . date("Y-m-d H:i:s"), '../');

  // $request_id = random_strings(8)."_".rand(10000000, 99999999);
  $request_id = rand(10000000, 99999999) . "_" . rand(10000000, 99999999);
  $replace_txt = '{
    "username" : "' . $uname . '",
    "password" : "' . $password . '",
    "request_id" : "' . $request_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/login',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Index Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $state1 = json_decode($response, false);
  site_log_generate("Index Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($state1->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? } else if ($state1->response_status == 200) {
    for ($indicator = 0; $indicator <= 1; $indicator++) {
      $_SESSION['yjwatsp_parent_id'] = $state1->parent_id;
      $_SESSION['yjwatsp_user_id'] = $state1->user_id;
      $_SESSION['yjwatsp_user_master_id'] = $state1->user_master_id;
      $_SESSION['yjwatsp_user_name'] = $state1->user_name;
      $_SESSION['yjwatsp_user_email'] = $state1->user_email;
      $_SESSION['yjwatsp_user_email'] = $state1->user_email;
      $_SESSION['yjwatsp_bearer_token'] = 'Bearer ' . $state1->bearer_token;
    }

    site_log_generate("Index Page : " . $uname . " logged in success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "info" => $result);

  } else {
    site_log_generate("Index Page : " . $uname . " logged in failed [$state1->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $state1->response_msg);
  }
}
// Index Page Signin - End

// Sign Up Page signup - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "signup") {
  // Get data
  $user_email = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_email']) ? $_REQUEST['txt_user_email'] : ""));
  $user_mobile = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_mobile']) ? $_REQUEST['txt_user_mobile'] : ""));
  $user_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_name']) ? $_REQUEST['txt_user_name'] : ""));
  $user_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_password']) ? $_REQUEST['txt_user_password'] : ""));
  $confirm_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_confirm_password']) ? $_REQUEST['txt_user_confirm_password'] : ""));
  site_log_generate("Sign Up Page : " . $loginid . " trying to create a new account in our site on " . date("Y-m-d H:i:s"), '../');
  $request_id = rand(10000000, 99999999) . "_" . rand(10000000, 99999999);
  $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "user_type" : "2",
    "user_name" : "' . $user_name . '",
    "user_email" : "' . $user_email . '",
    "user_mobile" : "' . $user_mobile . '",
    "user_password" : "' . $user_password . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/signup',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($header->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? } else if ($header->response_status == 200) {
    site_log_generate("Sign Up Page : " . $user_name . " account created successfully on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "New User created. Kindly login!!");
  } else {
    site_log_generate("Sign Up Page : " . $user_name . " account creation Failed [$header->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $header->response_msg);
  }
}
// Sign Up Page signup - End

// Index page Recovery password - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "resetpwd") {
  // Get data
  $txtfp_user_mobile = htmlspecialchars(strip_tags(isset($_REQUEST['txtfp_user_mobile']) ? $_REQUEST['txtfp_user_mobile'] : ""));
  $txt_user_password_rc = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_password_rc']) ? $_REQUEST['txt_user_password_rc'] : ""));
  $txt_confirm_password_rc = htmlspecialchars(strip_tags(isset($_REQUEST['txt_confirm_password_rc']) ? $_REQUEST['txt_confirm_password_rc'] : ""));
  $ip_address = $_SERVER['REMOTE_ADDR'];
  site_log_generate("Index Page : Username => " . $uname . " trying to Recovery password on " . date("Y-m-d H:i:s"), '../');

  $request_id = rand(10000000, 99999999) . "_" . rand(10000000, 99999999);
  $replace_txt = '{
    "user_mobile" : "' . $txtfp_user_mobile . '",
    "user_password" : "' . $txt_user_password_rc . '",
    "request_id" : "' . $request_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/password/forgot_password',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'PUT',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Index Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $state1 = json_decode($response, false);
  site_log_generate("Index Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($state1->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? } else if ($state1->response_status == 200) {
    site_log_generate("Index Page : " . $uname . " Recover Password in success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "info" => "New Password Change Successfully..!");
  } else {
    site_log_generate("Index Page : " . $uname . " Recover Password in failed [$state1->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $state1->response_msg);
  }
}
// Index Page Recovery password - End

// Change Password Page change_pwd - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $pwd_call_function == "change_pwd") {
  site_log_generate("Change Password Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"), '../');
  // Get data
  $ex_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_ex_password']) ? $_REQUEST['txt_ex_password'] : ""));
  $new_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_new_password']) ? $_REQUEST['txt_new_password'] : ""));
  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
    "old_password" : "' . $ex_password . '",
    "new_password" : "' . $new_password . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/password/change_password',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'PUT',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Change Password Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Change Password Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($header->response_status == 403) { ?>
    <script>
      window.location = "logout";
    </script>
  <? } else {
    site_log_generate("Index Page : " . $uname . " Change Password in failed [$state1->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => $header->response_code, "msg" => $header->response_msg);
  }
}
// Change Password Page change_pwd - End

// Manage Users Page Manage users  - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_users") {
  // Get data
  $user_email = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_email']) ? $_REQUEST['txt_user_email'] : ""));
  $user_mobile = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_mobile']) ? $_REQUEST['txt_user_mobile'] : ""));
  $user_name = htmlspecialchars(strip_tags(isset($_REQUEST['user_name']) ? $_REQUEST['user_name'] : ""));
  $user_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_password']) ? $_REQUEST['txt_user_password'] : ""));
  $confirm_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_confirm_password']) ? $_REQUEST['txt_user_confirm_password'] : ""));

  $assign_plan = htmlspecialchars(strip_tags(isset($_REQUEST['assign_plan']) ? $_REQUEST['assign_plan'] : ""));

  $select_plans = explode("~~", $assign_plan);
  $annual_monthly = $select_plans[0];
  $plan_master_id = $select_plans[1];
  $total_group_count = $select_plans[2];
  $total_whatsapp_count = $select_plans[3];
  $plan_price = $select_plans[4];
  $total_message_limit = $select_plans[5];

  // Get today's date
  $today = date("Y-m-d H:i:s");
  if ($annual_monthly == 'Monthly') {
    $validity_plan = date("Y-m-d H:i:s", strtotime("+1 month", strtotime($today)));
  } else {
    $validity_plan = date("Y-m-d H:i:s", strtotime("+1 year", strtotime($today)));
  }
  site_log_generate("Sign Up Page : " . $loginid . " trying to create a new account in our site on " . date("Y-m-d H:i:s"), '../');

  $request_id = rand(10000000, 99999999) . "_" . rand(10000000, 99999999);
  $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "user_type" : "2",
    "user_name" : "' . $user_name . '",
    "user_email" : "' . $user_email . '",
    "user_mobile" : "' . $user_mobile . '",
    "user_password" : "' . $user_password . '",
    "plan_master_id" : "' . $plan_master_id . '",
    "total_group_count" : "' . $total_group_count . '",
    "total_whatsapp_count" : "' . $total_whatsapp_count . '",
    "plan_amount" : "' . $plan_price . '",
    "total_message_limit" : "' . $total_message_limit . '",
    "expiry_date" : "' . $validity_plan . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/signup/user_creation',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $header = json_decode($response, false);
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($header->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? } else if ($header->response_status == 200) {
    site_log_generate("Sign Up Page : " . $user_name . " account created successfully on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "New User created. Kindly login!!");
  } else {
    site_log_generate("Sign Up Page : " . $user_name . " account creation Failed [$header->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $header->response_msg);
  }
}
// Manage Users Page Manage users - End

// Compose Whatsapp Page senderid_groupname - Start
if ($_SERVER["REQUEST_METHOD"] == "POST" and $tmpl_call_function == "senderid_groupname") {
  site_log_generate("Add Contact Group Page : User : " . $_SESSION["yjwatsp_user_name"] . " access the page on " . date("Y-m-d H:i:s"), "../");

  // Get data
  $sender_id = htmlspecialchars(
    strip_tags(
      isset($_REQUEST["sender_id"])
      ? strtolower($_REQUEST["sender_id"])
      : ""
    )
  );

  site_log_generate("Add Contact Group Page : User : " . $_SESSION["yjwatsp_user_name"] . " executed the query ($load_templates) on " . date("Y-m-d H:i:s"), "../");

  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $replace_txt = '{
    "sender_id" : "' . $sender_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/list/sender_id_groups',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'GET',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );

  site_log_generate("Add Contact Group Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $state1 = json_decode($response, false);
  site_log_generate("Add Contact Group Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($state1->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? }

  $rsmsg = '';
  if ($state1->response_status == 200) {
    $exgroup_name = '';
    for ($indicator = 0; $indicator < count($state1->group_list); $indicator++) {
      if ($exgroup_name != $state1->group_list[$indicator]->group_name) {
        $group_name = $state1->group_list[$indicator]->group_name;
        $rsmsg .= '<option value="' . $group_name . '">' . $group_name . '</option>';
      }
      $exgroup_name = $state1->group_list[$indicator]->group_name;
    }
  }

  $json = ["status" => 1, "msg" => '<option value= "" >Choose Group Name</option>' . $rsmsg];
}
// Compose Whatsapp Page senderid_groupname - End

// send otp - start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $otp_call_function == "mobile_otp") {

  site_log_generate("Mobile OTP - Mobile number OTP Page : User : " . $_SESSION['yjtsms_user_name'] . " access the page on " . date("Y-m-d H:i:s"), '../');
  $user_number = $_POST['txt_user_mobile'];
  $otp = rand(100000, 999999);
  $_SESSION['otp'] = $otp;
  $message = "Your OTP is " . $otp . "";
  $campaign_name = "testcmp";
  $api_adminpswd = 'SMS_api!@3';
  $api_adminuser = 'user_1';

  // ? add
  // echo 'http://115.243.200.60/sms_api/api/smsapi?process=compose_send_sms&username='.$api_adminuser.'&password='.$api_adminpswd.'&campaign_name='.$campaign_name.'&number='.$user_number.'&message=Your%20OTP%20is%20'.$otp;
  $curl = curl_init();

  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $message_url . 'process=compose_send_sms&username=' . $api_adminuser . '&password=' . $api_adminpswd . '&campaign_name=' . $campaign_name . '&number=' . $user_number . '&message=Your%20OTP%20is%20' . $otp,
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_HTTPHEADER => array(
        'Cookie: PHPSESSID=hp9jr2b7q5re7tt3qba2oipn6h'
      ),
    )
  );

  $response = curl_exec($curl);

  curl_close($curl);
  //echo $response;

  if ($response) {
    site_log_generate("Mobile OTP - Mobile number OTP Page : User : " . $_SESSION['yjtsms_user_name'] . " OTP Updated ($response) successfully on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "Success");
  }
}
// send otp - END

// Mobile OTP Check Page - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $otp_check_call_function == "mobile_check_otp") {
  site_log_generate("Mobile OTP - OTP Check Page : User : " . $_SESSION['yjtsms_user_name'] . " access the page on " . date("Y-m-d H:i:s"), '../');
  $user_otp = $_POST['txt_user_otp'];

  if ($_SESSION['otp'] == $user_otp) {
    $_SESSION['otp_status'] = 'Y';
    echo "Otp is valid";
    $json = array("status" => 1, "msg" => "Success");
  } else {
    $_SESSION['otp_status'] = 'N';
    $json = array("status" => 0, "msg" => "Invalid otp. Enter a correct OTP!");
    echo "Otp is not valid";
  }

}
// Mobile OTP Check Page - End

// Compose Whatsapp Page senderid_template - Start
if (
  $_SERVER["REQUEST_METHOD"] == "POST" and
  $tmpl_call_function == "group_sender_ids"
) {

  // Get data
  $slt_whatsapp_group_id = htmlspecialchars(
    strip_tags(
      isset($_REQUEST["slt_whatsapp_group"])
      ? strtolower($_REQUEST["slt_whatsapp_group"])
      : ""
    )
  );


  $slt_whatsapp_group_id = explode("!", $slt_whatsapp_group_id);
  $group_master_id = $slt_whatsapp_group_id[2];
  site_log_generate(
    "Compose Whatsapp - Validate Campaign Page : User : " .
    $_SESSION["yjwatsp_user_name"] .
    " access the page on " .
    date("Y-m-d H:i:s"),
    "../"
  );

  // To Send the request API Load Templates
  $load_templates = '{
                                "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
                                "group_master_id" : "' . $group_master_id . '"
                          }';
  site_log_generate(
    "Compose Whatsapp - Validate Campaign Page : User : " .
    $_SESSION["yjwatsp_user_name"] .
    " executed the query ($load_templates) on " .
    date("Y-m-d H:i:s")
  );
  // Add bearer token
  $bearer_token = "Authorization: " . $_SESSION["yjwatsp_bearer_token"] . "";
  // It will call "p_get_template_numbers" API to verify, can we use the template details
  $curl = curl_init();
  curl_setopt_array($curl, [
    CURLOPT_URL => $api_url . "/list/group_senders_list",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => "",
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => "GET",
    CURLOPT_POSTFIELDS => $load_templates,
    CURLOPT_HTTPHEADER => [$bearer_token, "Content-Type: application/json"],
  ]);
  // Send the data into API and execute 
  $response = curl_exec($curl);
  curl_close($curl);
  // After got response decode the JSON result
  $state1 = json_decode($response, false);

  //generate the log file
  site_log_generate(
    "Compose Whatsapp - Validate Campaign Page : User : " .
    $_SESSION["yjwatsp_user_name"] .
    " executed the query response ($response) on " .
    date("Y-m-d H:i:s")
  );

  $rsmsg .= '<table style="width: 100%;">';

  if ($state1->response_code == 1) { // If the response is success to execute this condition
    for ($indicator = 0; $indicator < count($state1->group_list); $indicator++) {
      // Looping the indicator is less than the count of data.if the condition is true to continue the process.if the condition are false to stop the process
      // $cntmonth = 100;

      if ($indicator % 2 == 0) {
        $rsmsg .= "<tr>";
      }
      $rsmsg .= '<td><input type="radio" ';
      // Check conditions for radio button checked attribute
      if ($counter == 0 || $_REQUEST['sender'] == $state1->sender_id[$indicator]->mobile_no) {
        $firstid = $state1->sender_id[$indicator]->mobile_no;
        $rsmsg .= 'checked ';
      }
      $rsmsg .= 'class="cls_checkbox" id="txt_whatsapp_mobno" name="txt_whatsapp_mobno[]" tabindex="1" autofocus value="~~' .
        $state1->group_list[$indicator]->sender_master_id .
        '~~' .
        $state1->group_list[$indicator]->mobile_no .
        '~~">' .
        ' <label class="form-label">' .
        $state1->group_list[$indicator]->mobile_no . '</b></label></td>';
      if ($indicator % 2 == 1) {
        $rsmsg .= "</tr>";
      }
    }
  } else if ($state1->response_status == 204) {
    site_log_generate("Compose Whatsapp - Validate Campaign Page  : " . $user_name . "get the Service response [$state1->response_status] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 2, "msg" => $state1->response_msg);
  } else {
    site_log_generate("Compose Whatsapp - Validate Campaign Page : " . $user_name . " get the Service response [$state1->response_msg] on  " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $state1->response_msg);
  }

  $rsmsg .= "</table>";
  $json = ["status" => 1, "msg" => $rsmsg];
}
// Compose Whatsapp Page senderid_template - End


// edit_onboarding Page signup - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "edit_onboarding") {
  // Get data
  $user_email = htmlspecialchars(strip_tags(isset($_REQUEST['email_id_contact']) ? $_REQUEST['email_id_contact'] : ""));
  $login_id = htmlspecialchars(strip_tags(isset($_REQUEST['login_id_txt']) ? $_REQUEST['login_id_txt'] : ""));
  $user_mobile = htmlspecialchars(strip_tags(isset($_REQUEST['mobile_no_txt']) ? $_REQUEST['mobile_no_txt'] : ""));
  $user_name = htmlspecialchars(strip_tags(isset($_REQUEST['clientname_txt']) ? $_REQUEST['clientname_txt'] : ""));
  site_log_generate("Sign Up Page : " . $loginid . " trying to create a new account in our site on " . date("Y-m-d H:i:s"), '../');
  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);

  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

  $replace_txt = '{
    "user_id":"' . $_SESSION['yjwatsp_user_id'] . '",
    "user_name" : "' . $user_name . '",
    "user_email" : "' . $user_email . '",
    "user_mobile" : "' . $user_mobile . '",
    "request_id":"' . $request_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/user/update_details',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'PUT',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  echo $response;
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Sign Up Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($header->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? }
  if ($header->response_status == 200) {
    site_log_generate("Sign Up Page : " . $user_name . " account created successfully on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "User detailes updated successfully!");
  } else {
    site_log_generate("Sign Up Page : " . $user_name . " account creation Failed [$header->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $header->response_msg);
  }
}
//edit_onboarding Page signup - End

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);