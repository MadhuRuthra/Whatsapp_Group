<?php
session_start();
error_reporting(E_ALL);
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
  $request_id = rand(10000000, 99999999)."_".rand(10000000, 99999999);
  $replace_txt = '{
    "username" : "' . $uname . '",
    "password" : "' . $password . '",
    "request_id" : "' . $request_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array($curl, array(
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
  ));
  site_log_generate("Index Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $state1 = json_decode($response, false);
  site_log_generate("Index Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($state1->response_status == 403) { ?>
    <script>
      window.location = "logout"
    </script>
  <? }

  // print_r($state1);
  if ($state1->response_status == 200) {
    for ($indicator = 0; $indicator <= 1; $indicator++) {
      $_SESSION['yjwatsp_parent_id']       = $state1->parent_id;
      $_SESSION['yjwatsp_user_id']         = $state1->user_id;
      $_SESSION['yjwatsp_user_master_id']  = $state1->user_master_id;
      $_SESSION['yjwatsp_user_name']       = $state1->user_name;
      $_SESSION['yjwatsp_bearer_token']   = 'Bearer ' . $state1->bearer_token;
    }

    site_log_generate("Index Page : " . $uname . " logged in success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "info" => $result);
  } else {
    site_log_generate("Index Page : " . $uname . " logged in failed [Sign in Failed] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => 'Sign in Failed');
  }
}
// Index Page Signin - End

// Manage Users Page signup - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "signup") {
  // Get data
  $user_type           = htmlspecialchars(strip_tags(isset($_REQUEST['slt_user_type']) ? $_REQUEST['slt_user_type'] : ""));
  $user_name           = htmlspecialchars(strip_tags(isset($_REQUEST['txt_loginid']) ? $_REQUEST['txt_loginid'] : ""));
  $user_email         = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_email']) ? $_REQUEST['txt_user_email'] : ""));
  $user_mobile         = htmlspecialchars(strip_tags(isset($_REQUEST['txt_user_mobile']) ? $_REQUEST['txt_user_mobile'] : ""));

  $slt_super_admin     = htmlspecialchars(strip_tags(isset($_REQUEST['slt_super_admin']) ? $_REQUEST['slt_super_admin'] : ""));
  $slt_dept_admin     = htmlspecialchars(strip_tags(isset($_REQUEST['slt_dept_admin']) ? $_REQUEST['slt_dept_admin'] : ""));

  $loginid             = htmlspecialchars(strip_tags(isset($_REQUEST['txt_loginid']) ? $_REQUEST['txt_loginid'] : ""));
  $txt_login_shortname = htmlspecialchars(strip_tags(isset($_REQUEST['txt_login_shortname']) ? $_REQUEST['txt_login_shortname'] : ""));
  $user_password       = 'Password@123';
  $confirm_password   = htmlspecialchars(strip_tags(isset($_REQUEST['txt_confirm_password']) ? $_REQUEST['txt_confirm_password'] : ""));
  $user_permission     = htmlspecialchars(strip_tags(isset($_REQUEST['user_permission']) ? $_REQUEST['user_permission'] : "3"));
  site_log_generate("Manage Users Page : " . $loginid . " trying to create a new account in our site on " . date("Y-m-d H:i:s"), '../');
  $user_short_name  = $txt_login_shortname;

  $replace_txt = '{
    "api_key" : "' . $_SESSION['yjwatsp_api_key'] . '",
    "user_type" : "' . $user_type . '",
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
  site_log_generate("Manage Users Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Manage Users Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($header->num_of_rows > 0) {
    site_log_generate("Manage Users Page : " . $user_name . " account created successfully on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "New User created. Kindly login!!");
  } else {
    site_log_generate("Manage Users Page : " . $user_name . " account creation Failed [$header->response_msg] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $header->response_msg);
  }
}
// Manage Users Page signup - End

// Change Password Page change_pwd - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $pwd_call_function == "change_pwd") {
  site_log_generate("Change Password Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"), '../');
  // Get data
  $ex_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_ex_password']) ? $_REQUEST['txt_ex_password'] : ""));
  $new_password = htmlspecialchars(strip_tags(isset($_REQUEST['txt_new_password']) ? $_REQUEST['txt_new_password'] : ""));
  $ex_pass = md5($ex_password);
  $upass = md5($new_password);

  $replace_txt = '{
    "api_key" : "' . $_SESSION['yjwatsp_api_key'] . '",
    "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
    "ex_password" : "' . $ex_pass . '",
    "new_password" : "' . $upass . '"
  }';
  $curl = curl_init();
  curl_setopt_array($curl, array(
    CURLOPT_URL => $api_url . '/list/change_password',
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
  ));
  site_log_generate("Change Password Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Change Password Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  $json = array("status" => $header->response_code, "msg" => $header->response_msg);
}
// Change Password Page change_pwd - End

// Compose Whatsapp Page senderid_groupname - Start
if ($_SERVER["REQUEST_METHOD"] == "POST" and $tmpl_call_function == "senderid_groupname") {
  site_log_generate("Add Contact Group Page : User : " . $_SESSION["yjwatsp_user_name"] . " access the page on " .date("Y-m-d H:i:s"), "../");

  // Get data
  $sender_id = htmlspecialchars(
    strip_tags(
      isset($_REQUEST["sender_id"])
        ? strtolower($_REQUEST["sender_id"])
        : ""
    )
  );

  site_log_generate("Add Contact Group Page : User : " . $_SESSION["yjwatsp_user_name"] . " executed the query ($load_templates) on " .date("Y-m-d H:i:s"), "../");

  $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
  $replace_txt = '{
    "sender_id" : "'.$sender_id.'"
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
        $rsmsg .= '<option value="'.$group_name.'" selected>'.$group_name.'</option>';
      }
      $exgroup_name = $state1->group_list[$indicator]->group_name;
    }
  }

  $json = ["status" => 1, "msg" => $rsmsg];
}
// Compose Whatsapp Page senderid_groupname - End

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
