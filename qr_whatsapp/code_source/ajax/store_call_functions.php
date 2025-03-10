<?php
session_start();
error_reporting(0);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");
$milliseconds = round(microtime(true) * 1000);

// Mobile number sending - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $store_call_function == "senderid_status_check") {
  $mobile_number = htmlspecialchars(strip_tags(isset($_REQUEST['mobile_number']) ? $conn->real_escape_string($_REQUEST['mobile_number']) : ""));
  $txt_country_code = htmlspecialchars(strip_tags(isset($_REQUEST['txt_country_code']) ? $conn->real_escape_string($_REQUEST['txt_country_code']) : ""));

  $exp1 = explode("||", $txt_country_code);
  $country_code = $exp1[1];
  $country_id = $exp1[0];

  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $curl1 = curl_init();
  curl_setopt_array(
    $curl1,
    array(
      CURLOPT_URL => $api_url . '/sender_id/check_sender_status',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'GET',
      CURLOPT_POSTFIELDS => '{
          "mobile_no":"' . $country_code . $mobile_number . '"
        }',
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );

  $response = curl_exec($curl1);
  curl_close($curl1);
  $obj = json_decode($response);
  if ($response == '') { ?>
    <script>
      window.location = "index"
    </script>
  <? } else if ($obj->response_status == 403) { ?>
      <script>
        window.location = "index"
      </script>
  <? }
  site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 response [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($obj->response_code == 0) {
    site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 response [Mobile number already exists.] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => "Mobile number already exists.");
  } else {
    site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 response [Mobile number Not exists.] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "success");

  }

}



// Mobile number sending - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $store_call_function == "mobile_qrcode") {
  $exp1 = htmlspecialchars(strip_tags(isset($_REQUEST['txt_country_code']) ? $conn->real_escape_string($_REQUEST['txt_country_code']) : "101"));
  $mobile_number = htmlspecialchars(strip_tags(isset($_REQUEST['mobile_number']) ? $conn->real_escape_string($_REQUEST['mobile_number']) : ""));
  $txt_display_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_display_name']) ? $conn->real_escape_string($_REQUEST['txt_display_name']) : ""));
  site_log_generate("Manage Sender ID Page : Username => " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');

  $exp2 = explode("~~", $exp1);
  $txt_country_code = $exp2[0];
  $country_code = $exp2[1];

  $filename = '';
  if ($_FILES['file']['name'] != '') {
    $path_parts = pathinfo($_FILES["file"]["name"]);
    $extension = $path_parts['extension'];

    $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $extension;

    /* Location */
    $location = "../uploads/whatsapp_images/" . $filename;
    $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
    $imageFileType = strtolower($imageFileType);
    $profile_image = $site_url . "uploads/whatsapp_images/" . $filename;
    switch ($imageFileType) {
      case 'jpg':
      case 'jpeg':
        $mime_type = "image/jpeg";
        break;
      case 'png':
        $mime_type = "image/png";
        break;
    }

    /* Valid extensions */
    $valid_extensions = array("jpg", "jpeg", "png");

    $rspns = '';
    if (move_uploaded_file($_FILES['file']['tmp_name'], $location)) {
      site_log_generate("Manage Sender ID Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_images file moved into Folder on " . date("Y-m-d H:i:s"), '../');
    }
  }
  //  else {
  // $profile_image = $_SESSION['img_name'];
  // }

  $replace_txt = '{';
  $replace_txt .= '"user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
    "mobile_number":"' . $country_code . $mobile_number . '",';

  if ($txt_display_name) {
    $replace_txt .= '"profile_name" : "' . $txt_display_name . '",';
  }
  if ($profile_image) {
    $replace_txt .= '"profile_image" : "' . $profile_image . '",';
  }

  $replace_txt .= '
  "request_id":"' . $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999) . '"
}';

  // print_r($replace_txt);
// exit();

  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $curl1 = curl_init();
  curl_setopt_array(
    $curl1,
    array(
      CURLOPT_URL => $api_url . '/sender_id/add_sender_id',
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
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );

  $response1 = curl_exec($curl1);
  curl_close($curl1);

  site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 [" . $replace_txt . "] on " . date("Y-m-d H:i:s"), '../');

  $obj1 = json_decode($response1);
  if ($response1 == '') { ?>
    <script>
      window.location = "index"
    </script>
  <? } else if ($obj1->response_status == 403) { ?>
      <script>
        window.location = "index"
      </script>
  <? }
  site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 response [$response1] on " . date("Y-m-d H:i:s"), '../');

  $_SESSION['qrcode'] = $obj1->qr_code;

  if ($obj1->response_status == '200') {
    $json = array("status" => 1, "msg" => $obj1->response_msg, "qrcode" => $obj1->qr_code);
  } else if ($obj1->response_status == '201') {
    $json = array("status" => 0, "msg" => $obj1->response_msg);
  } else if ($obj1->response_status == '204') {
    $json = array("status" => 0, "msg" => $obj1->response_msg);
  } else if ($obj1->response_status == '403') {
    $json = array("status" => 0, "msg" => $obj1->response_msg);
  } else if ($obj1->response_status == '202') {
    $json = array("status" => 2, "msg" => $obj1->response_msg);
    // To clear the session variable
    unset($_SESSION['img_name']);
  } else {
    $json = array("status" => 2, "msg" => "loading");
  }
}

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
