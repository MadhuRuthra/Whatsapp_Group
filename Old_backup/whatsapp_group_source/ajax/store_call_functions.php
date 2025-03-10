<?php
session_start();
error_reporting(E_ALL);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");
$milliseconds = round(microtime(true) * 1000);

// Mobile number sending - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $store_call_function == "mobile_qrcode") {
  $mobile_number = htmlspecialchars(strip_tags(isset($_REQUEST['mobile_number']) ? $conn->real_escape_string($_REQUEST['mobile_number']) : ""));
  $txt_country_code = htmlspecialchars(strip_tags(isset($_REQUEST['txt_country_code']) ? $conn->real_escape_string($_REQUEST['txt_country_code']) : ""));

  $exp1 = explode("||", $txt_country_code);
  $country_code = $exp1[1];
  $country_id = $exp1[0];

  $request_id = $_SESSION['yjwatsp_user_id']."_".date("Y")."".date('z', strtotime(date("d-m-Y")))."".date("His")."_".rand(1000, 9999);
  $bearer_token = 'Authorization: '.$_SESSION['yjwatsp_bearer_token'].''; 
  $curl1 = curl_init();
  curl_setopt_array($curl1, array(
    CURLOPT_URL => $api_url . '/get_qrcode',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_SSL_VERIFYPEER => 0,
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_POSTFIELDS => '{
          "mobile_number":"' . $country_code.$mobile_number . '",
          "request_id":"' . $request_id . '"
        }',
    CURLOPT_HTTPHEADER => array(
      $bearer_token,
      'Content-Type: application/json'
    ),
  )
  );

  $response1 = curl_exec($curl1);
  curl_close($curl1);

  site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 [{
      \"mobile_number\":" . $mobile_number . ",
      \"request_id\":" . $request_id . "
    }] on " . date("Y-m-d H:i:s"), '../');

  $obj1 = json_decode($response1);

  site_log_generate("Mobile number QR Code Scan Page : Username => " . $_SESSION['yjwatsp_user_name'] . " executed the query2 response [$response1] on " . date("Y-m-d H:i:s"), '../');

  $_SESSION['qrcode'] = $obj1->qr_code;

  if ($obj1->response_status == '200') {
    $json = array("status" => 1, "msg" => $obj1->response_msg, "qrcode" => $obj1->qr_code);
  } else if ($obj1->response_status == '201') {
    $json = array("status" => 0, "msg" => 'Error generating QR Code');
  } else if ($obj1->response_status == '204') {
    $json = array("status" => 0, "msg" => 'No Data Available');
  } else if ($obj1->response_status == '403') {
    $json = array("status" => 0, "msg" => "Token Expired");
  } else {
    $json = array("status" => 2, "msg" => "loading");
  }
}

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
