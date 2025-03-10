<?php
session_start();
error_reporting(0);
// Include configuration.php
include_once('../api/configuration.php');
include_once('site_common_functions.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");
$milliseconds = round(microtime(true) * 1000);

// Add Contacts in Group Page validateMobno - Start
if (isset($_POST['validateMobno']) == "validateMobno") {
  $mobno = str_replace('"', '', htmlspecialchars(strip_tags(isset($_POST['mobno']) ? $conn->real_escape_string($_POST['mobno']) : "")));
  $dup = htmlspecialchars(strip_tags(isset($_POST['dup']) ? $conn->real_escape_string($_POST['dup']) : ""));
  $inv = htmlspecialchars(strip_tags(isset($_POST['inv']) ? $conn->real_escape_string($_POST['inv']) : ""));

  $mobno = str_replace('\n', ',', $mobno);
  $newline = explode('\n', $mobno);

  $correct_mobno_data = [];
  $return_mobno_data = '';
  $issu_mob = '';
  $cnt_vld_no = 0;
  $max_vld_no = 1000;
  for ($i = 0; $i < count($newline); $i++) {
    $expl = explode(",", $newline[$i]);

    for ($ij = 0; $ij < count($expl); $ij++) {

      if ($inv == 1) {
        $vlno = validate_phone_number($expl[$ij]);
      } else {
        $vlno = $newline[$i];
      }

      if ($vlno == true) {
        if ($dup == 1) {
          if (!in_array($expl[$ij], $correct_mobno_data)) {
            if ($expl[$ij] != '') {
              $cnt_vld_no++;
              if ($cnt_vld_no <= $max_vld_no) {
                $correct_mobno_data[] = $expl[$ij];
                $return_mobno_data .= $expl[$ij] . ",\n";
              } else {
                $issu_mob .= $expl[$ij] . ",";
              }
            } else {
              $issu_mob .= $expl[$ij] . ",";
            }
          } else {
            $issu_mob .= $expl[$ij] . ",";
          }
        } else {
          if ($expl[$ij] != '') {
            $cnt_vld_no++;
            if ($cnt_vld_no <= $max_vld_no) {
              $correct_mobno_data[] = $expl[$ij];
              $return_mobno_data .= $expl[$ij] . ",\n";
            } else {
              $issu_mob .= $expl[$ij] . ", ";
            }
          } else {
            $issu_mob .= $expl[$ij] . ", ";
          }
        }
      } else {
        $issu_mob .= $expl[$ij] . ",";
      }
    }
  }

  $return_mobno_data = rtrim($return_mobno_data, ",\n");
  site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " validated Mobile Nos ($return_mobno_data||$issu_mob) on " . date("Y-m-d H:i:s"), '../');
  $json = array("status" => 1, "msg" => $return_mobno_data . "||" . $issu_mob);
}
// Add Contacts in Group Page validateMobno - End

// Add Contacts in Group Page delete_senderid - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "delete_senderid") {
  $whatspp_config_id1 = htmlspecialchars(strip_tags(isset($_REQUEST['whatspp_config_id']) ? $conn->real_escape_string($_REQUEST['whatspp_config_id']) : ""));
  $approve_status1 = htmlspecialchars(strip_tags(isset($_REQUEST['approve_status']) ? $conn->real_escape_string($_REQUEST['approve_status']) : ""));

  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $replace_txt = '{
    "sender_id" : "' . $whatspp_config_id1 . '",
    "request_id":"' . $request_id . '"
  }';
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/sender_id/delete_sender_id',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'DELETE',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Add Contacts in Group Delete Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Add Contacts in Group Delete Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($header->response_status == 403) { ?>
    <script>window.location = "logout"</script>
  <? }

  if ($header->response_status == 200) {
    $json = array("status" => 1, "msg" => "Success");
  } else {
    $json = array("status" => 0, "msg" => "Failed. " . $header->response_msg);
  }
}
// Add Contacts in Group Page delete_senderid - Start

// Add Contacts in Group Page generate_contacts - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "generate_contacts") {
  $txt_list_mobno = htmlspecialchars(strip_tags(isset($_REQUEST['txt_list_mobno']) ? $conn->real_escape_string($_REQUEST['txt_list_mobno']) : ""));

  $expld = explode(",", $txt_list_mobno);
  $mblno = '';
  for ($i = 0; $i < count($expld); $i++) {
    $mblno .= '"' . $expld[$i] . '", ';
  }
  $mblno = rtrim($mblno, ", ");

  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

  $replace_txt = '{
    "mobile_number":[' . $mblno . '],
    "request_id":"' . $request_id . '"
  }';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/group/create_csv',
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
  site_log_generate("Add Contacts in Group Generate Contacts Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$bearer_token.$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);

  $header = json_decode($response, false);
  site_log_generate("Add Contacts in Group Generate Contacts Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($header->response_code == 1) {
    // $json = array("status" => 1, "msg" => "<a target='_blank' href='".$site_url.$header->file_location."' class='error_display'>Download Contacts CSV</a>");
    $json = array("status" => 1, "msg" => $site_url . $header->file_location);
  } else {
    $json = array("status" => 0, "msg" => "Failed to Generate Contact CSV. Kindly try again!!");
  }
}
// Add Contacts in Group Page generate_contacts - Start

// Add Contacts in Group Page contact_group - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "contact_group") {
  site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');

  // Get data
  $txt_whatsapp_mobno = htmlspecialchars(strip_tags(isset($_REQUEST['txt_whatsapp_mobno']) ? $_REQUEST['txt_whatsapp_mobno'] : ""));
  $rdo_newex_group = htmlspecialchars(strip_tags(isset($_REQUEST['rdo_newex_group']) ? $_REQUEST['rdo_newex_group'] : ""));
  $slt_group = htmlspecialchars(strip_tags(isset($_REQUEST['slt_group']) ? $_REQUEST['slt_group'] : ""));
  $txt_group_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_group_name']) ? $_REQUEST['txt_group_name'] : ""));
  // $txt_list_mobno 		= htmlspecialchars(strip_tags(isset($_REQUEST['txt_list_mobno']) ? $_REQUEST['txt_list_mobno'] : ""));
  $upload_contact = htmlspecialchars(strip_tags(isset($_REQUEST['upload_contact']) ? $_REQUEST['upload_contact'] : ""));
  $txt_contact_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_contact_name']) ? $_REQUEST['txt_contact_name'] : ""));
  $txt_group_name_ex = htmlspecialchars(strip_tags(isset($_REQUEST['txt_group_name_ex']) ? $_REQUEST['txt_group_name_ex'] : ""));

  if ($txt_contact_name != '') {
    // Explode
    $str_arr = explode(",", $txt_contact_name);
    $entry_contact = '';
    for ($indicatori = 0; $indicatori < count($str_arr); $indicatori++) {
      $entry_contact .= '"' . $str_arr[$indicatori] . '", ';
    }
    $entry_contact = rtrim($entry_contact, ", ");

    $name_vrble = "[" . $entry_contact . "]";
    $number_vrble = "[" . $entry_contact . "]";
  }

  if ($_FILES["upload_contact"]["name"] != '') {
    $path_parts = pathinfo($_FILES["upload_contact"]["name"]);
    $extension = $path_parts['extension'];
    $filename = $_SESSION['yjwatsp_user_id'] . "_csv_" . $milliseconds . "." . $extension;
    /* Location */
    $location = "../uploads/group_contact/" . $filename;
    $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
    $imageFileType = strtolower($imageFileType);
    /* Valid extensions */
    $valid_extensions = array("csv");
    $response = 0;
    /* Check file extension */
    if (in_array(strtolower($imageFileType), $valid_extensions)) {
      /* Upload file */
      if (move_uploaded_file($_FILES['upload_contact']['tmp_name'], $location)) {
        $response = $location;
      }
    }

    $csvFile = fopen($location, 'r') or die("can't open file");
    // Skip the first line
    fgetcsv($csvFile);

    $name_vrble = '[';
    $number_vrble = '[';

    // Get row data
    $name_tmp = '';
    $number_tmp = '';

    // Parse data from CSV file line by line
    while (($line = fgetcsv($csvFile)) !== FALSE) {
      for ($txt_variable_counti = 0; $txt_variable_counti <= count($line); $txt_variable_counti++) {
        // echo "==".$txt_variable_counti."==".$line[$txt_variable_counti]."==<br>";
        if ($txt_variable_counti == 0) {
          $name_tmp .= '"' . $line[$txt_variable_counti] . '", ';
        }
        if ($txt_variable_counti == 4) {
          $number_tmp .= '"' . $line[$txt_variable_counti] . '", ';
        }
      }
    }
    $name_tmp = rtrim($name_tmp, ", ");
    $number_tmp = rtrim($number_tmp, ", ");

    $name_vrble = rtrim($name_vrble, ", ");
    $name_vrble = $name_vrble . $name_tmp . "]";

    $number_vrble = rtrim($number_vrble, ", ");
    $number_vrble = $number_vrble . $number_tmp . "]";

    // Close opened CSV file
    fclose($csvFile);
  }

  //   echo $number_vrble;
  // echo "===========";
  // echo $name_vrble;
  //  exit;

  if ($rdo_newex_group == 'N') { // Create a New Group
    $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

    $replace_txt = '{
      "group_name":"' . $txt_group_name . '",
      "sender_id" : "' . $txt_whatsapp_mobno . '",
      "participants":' . $name_vrble . ',
      "request_id":"' . $request_id . '"
    }';

    //print_r($replace_txt);
//exit;

    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/group/create_group', // Create a New Group
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
          "cache-control: no-cache",
          'Content-Type: application/json; charset=utf-8'
        ),
      )
    );
  } elseif ($rdo_newex_group == 'E') { // Add to Existing Group
    $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

    if ($txt_group_name_ex) {
      $slt_group = $txt_group_name_ex;
    }

    $replace_txt = '{
      "group_name":"' . $slt_group . '",
      "sender_id" : "' . $txt_whatsapp_mobno . '",
      "participants":' . $name_vrble . ',
      "request_id":"' . $request_id . '"
    }';
    //print_r($replace_txt);
//exit;
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/group/add_members', // Add to Existing Group
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
          "cache-control: no-cache",
          'Content-Type: application/json; charset=utf-8'
        ),
      )
    );
  }

  site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " api request [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $respobj = json_decode($response);

  site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " api response [$response] on " . date("Y-m-d H:i:s"), '../');
  $rsp_id = $respobj->response_status;
  if ($rsp_id == 403) {
    $json = array("status" => 2, "msg" => "Invalid User, Kindly try with valid User!!");
    site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Invalid User, Kindly try with valid User!!] on " . date("Y-m-d H:i:s"), '../');
  } elseif ($rsp_id == 201) {
    $json = array("status" => 0, "msg" => "Failure: " . $respobj->response_msg);
    site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Failure: $respobj->response_msg] on " . date("Y-m-d H:i:s"), '../');
  } elseif ($rsp_id == 200) {
    $json = array("status" => 1, "msg" => "Success");
    site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Success] on " . date("Y-m-d H:i:s"), '../');
  }
}
// Add Contacts in Group Page contact_group - End

// purchase_sms_credit Page purchase_sms_credit - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "purchase_sms_credit") {

  site_log_generate("Purchase SMS Credit Page : User : " . $_SESSION['yjwatsp_user_name'] . " Purchase SMS Credit - access this page on " . date("Y-m-d H:i:s"), '../');
  // Get data

  $price_plan = htmlspecialchars(strip_tags(isset($_REQUEST["price_plan_amount"]) ? $conn->real_escape_string($_REQUEST["price_plan_amount"]) : ""));
  $plan_master_id = htmlspecialchars(strip_tags(isset($_REQUEST["plan_master_id"]) ? $conn->real_escape_string($_REQUEST["plan_master_id"]) : ""));
  $validity_period = htmlspecialchars(strip_tags(isset($_REQUEST["validity_period"]) ? $conn->real_escape_string($_REQUEST["validity_period"]) : ""));

  $cnt_insrt = 0;
  $paid_status = 'W';
  $paid_status_cmnts = 'NULL';
  $plan_reference_id = '-';
  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $replace_txt = '{
"slt_user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
"request_id" : "' . $request_id . '",
"plan_amount" : "' . $price_plan . '",
"plan_master_id" : "' . $plan_master_id . '",
"plan_comments" : "' . $paid_status_cmnts . '",
"plan_reference_id": "' . $plan_reference_id . '"
}';
  // To Get Api URL
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/plan/user_plans_purchase',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Approve Whatsappno Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service (user_sms_credit_raise) [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $sms = json_decode($response, false);
  site_log_generate("Approve Whatsappno Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response (user_sms_credit_raise) [$response] on " . date("Y-m-d H:i:s"), '../');
  if ($sms->response_status == 200) {
    $cnt_insrt++;
  }

  if ($cnt_insrt > 0) {
    site_log_generate("Purchase SMS Credit Page : User : " . $_SESSION['yjwatsp_user_name'] . " Purchase SMS Credit Success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "Success");
  } else {
    site_log_generate("Purchase SMS Credit Page : User : " . $_SESSION['yjwatsp_user_name'] . " Purchase SMS Credit failed [Data not inserted] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $sms->response_msg);
  }
}
// purchase_sms_credit Page purchase_sms_credit - End

//Remove participants (USERS) in the Whatsapp Group - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "send_remove_campaign_wastp") {
  site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');
  // Get data
  $select_user_id = htmlspecialchars(strip_tags(isset($_REQUEST['select_user_id']) ? $conn->real_escape_string($_REQUEST['select_user_id']) : ""));
  $reason = htmlspecialchars(strip_tags(isset($_REQUEST['reason']) ? $_REQUEST['reason'] : ""));
  $group_name = htmlspecialchars(strip_tags(isset($_REQUEST['group_name']) ? $conn->real_escape_string($_REQUEST['group_name']) : ""));
  $select_user_id = htmlspecialchars(strip_tags(isset($_REQUEST['select_user_id']) ? $conn->real_escape_string($_REQUEST['select_user_id']) : ""));
  $mobile_numbers = htmlspecialchars(strip_tags(isset($_REQUEST['mobile_numbers']) ? $_REQUEST['mobile_numbers'] : ""));
  $group_contacts_ids = htmlspecialchars(strip_tags(isset($_REQUEST['group_contacts_ids']) ? $_REQUEST['group_contacts_ids'] : ""));
  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $sender_no = htmlspecialchars(strip_tags(isset($_REQUEST['sender_no']) ? $conn->real_escape_string($_REQUEST['sender_no']) : ""));

  $group_contact_id = str_replace(',', '","', $group_contacts_ids);
  $mobile_number = str_replace(',', '","', $mobile_numbers);

  $replace_txt = '{
      "request_id":"' . $request_id . '",
      "user_id":"' . $_SESSION['yjwatsp_user_id'] . '",
      "group_name":"' . $group_name . '",
       "sender_id" : "' . $sender_no . '",
      "participants" : ["' . $mobile_number . '"],
      "remove_comments" : "' . $reason . '",
      "group_contacts_ids" : ["' . $group_contact_id . '"],
      "selected_user_id":"' . $select_user_id . '"
    }';

  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/group/remove_members', // Remove a User From this Group
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
        'Content-Type: application/json; charset=utf-8'
      ),
    )
  );

  site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " api request [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  if ($response == '') { ?>
    <script>window.location = "logout"</script>
  <? }
  $respobj = json_decode($response);

  site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " api response [$response] on " . date("Y-m-d H:i:s"), '../');
  $rsp_id = $respobj->response_status;
  if ($rsp_id == 403) {
    ?>
    <script>window.location = "logout"</script>
    <?
    $json = array("status" => 2, "msg" => $respobj->response_msg);
    site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Invalid User, Kindly try with valid User!!] on " . date("Y-m-d H:i:s"), '../');
  } elseif ($rsp_id == 201) {
    $json = array("status" => 0, "msg" => "Failure: " . $respobj->response_msg);
    site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Failure: $respobj->response_msg] on " . date("Y-m-d H:i:s"), '../');
  } elseif ($rsp_id == 200) {
    $json = array("status" => 1, "msg" => "Success");
    site_log_generate("Remove participants (USERS) Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Success] on " . date("Y-m-d H:i:s"), '../');
  }
}
//Remove participants (USERS) in the Whatsapp Group - End

// Delete Plan Page delete_plan - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "delete_plan") {

  $whatspp_config_id1 = htmlspecialchars(strip_tags(isset($_REQUEST['plan_master_id']) ? $conn->real_escape_string($_REQUEST['plan_master_id']) : ""));

  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  $replace_txt = '{
    "plan_master_id" : "' . $plan_master_id . '",
    "request_id":"' . $request_id . '"
  }';
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/plan/delete_plan',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'DELETE',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'
      ),
    )
  );
  site_log_generate("Add Contacts in Group Delete Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  $header = json_decode($response, false);
  site_log_generate("Add Contacts in Group Delete Sender ID Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($header->response_status == 403) { ?>
    <script>window.location = "logout"</script>
  <? }

  if ($header->response_status == 200) {
    $json = array("status" => 1, "msg" => "Success");
  } else {
    $json = array("status" => 0, "msg" => "Failed. " . $header->response_msg);
  }
}
// Delete Plan Page delete_plan - Start


// creation_plan Page creation_plan - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $temp_function == "creation_plan") {

  site_log_generate("Purchase SMS Credit Page : User : " . $_SESSION['yjwatsp_user_name'] . " Purchase SMS Credit - access this page on " . date("Y-m-d H:i:s"), '../');
  // Get data

  $plan_master_id = htmlspecialchars(strip_tags(isset($_REQUEST["plan_master_id"]) ? $conn->real_escape_string($_REQUEST["plan_master_id"]) : ""));
  $plan_name = htmlspecialchars(strip_tags(isset($_REQUEST["plan_name"]) ? $conn->real_escape_string($_REQUEST["plan_name"]) : ""));
  $annual_price = htmlspecialchars(strip_tags(isset($_REQUEST["annual_price"]) ? $conn->real_escape_string($_REQUEST["annual_price"]) : ""));
  $month_price = htmlspecialchars(strip_tags(isset($_REQUEST["month_price"]) ? $conn->real_escape_string($_REQUEST["month_price"]) : ""));
  $no_of_whatsapps_month = htmlspecialchars(strip_tags(isset($_REQUEST["no_of_whatsapps_month"]) ? $conn->real_escape_string($_REQUEST["no_of_whatsapps_month"]) : ""));
  $no_of_groups_month = htmlspecialchars(strip_tags(isset($_REQUEST["no_of_groups_month"]) ? $conn->real_escape_string($_REQUEST["no_of_groups_month"]) : ""));
  $no_of_whatsapps_annual = htmlspecialchars(strip_tags(isset($_REQUEST["no_of_whatsapps_annual"]) ? $conn->real_escape_string($_REQUEST["no_of_whatsapps_annual"]) : ""));
  $no_of_groups_annual = htmlspecialchars(strip_tags(isset($_REQUEST["no_of_groups_annual"]) ? $conn->real_escape_string($_REQUEST["no_of_groups_annual"]) : ""));

  $request_id = $_SESSION['yjwatsp_user_id'] . "_" . date("Y") . "" . date('z', strtotime(date("d-m-Y"))) . "" . date("His") . "_" . rand(1000, 9999);
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';


  if ($plan_master_id && $month_price) {
    $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "plan_master_id" : "' . $plan_master_id . '",
    "plan_title" : "' . $plan_name . '",
    "whatsapp_no_max_count_month" : "' . $no_of_whatsapps_month . '",
    "group_no_max_count_month": "' . $no_of_groups_month . '",
    "message_limit": "' . $no_of_messages . '",
    "month_price":"' . $month_price . '"
    }';

    // To Get Api URL
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/plan/update_plans',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'PUT',
        CURLOPT_POSTFIELDS => $replace_txt,
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'
        ),
      )
    );
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service (user_sms_credit_raise) [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
    $response = curl_exec($curl);
    curl_close($curl);
    $sms = json_decode($response, false);
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response (user_sms_credit_raise) [$response] on " . date("Y-m-d H:i:s"), '../');
    if ($sms->response_status == 200) {
      $cnt_insrt++;
    }

  } else if ($plan_master_id && $annual_price) {
    $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "plan_title" : "' . $plan_name . '",
    "plan_master_id" : "' . $plan_master_id . '",
    "whatsapp_no_max_count_annual" : "' . $no_of_whatsapps_annual . '",
    "group_no_max_count_annual": "' . $no_of_groups_annual . '",
    "message_limit": "' . $no_of_messages . '",
    "annual_price":"' . $annual_price . '"
    }';
    // To Get Api URL
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/plan/update_plans',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'PUT',
        CURLOPT_POSTFIELDS => $replace_txt,
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'
        ),
      )
    );
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service (user_sms_credit_raise) [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
    $response = curl_exec($curl);
    curl_close($curl);
    $sms = json_decode($response, false);
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response (user_sms_credit_raise) [$response] on " . date("Y-m-d H:i:s"), '../');
    if ($sms->response_status == 200) {
      $cnt_insrt++;
    }

  } else {
    $replace_txt = '{
    "request_id" : "' . $request_id . '",
    "plan_title" : "' . $plan_name . '",
    "whatsapp_no_max_count_month" : "' . $no_of_whatsapps_month . '",
    "group_no_max_count_month": "' . $no_of_groups_month . '",
    "whatsapp_no_max_count_annual" : "' . $no_of_whatsapps_annual . '",
    "group_no_max_count_annual": "' . $no_of_groups_annual . '",
    "annual_price":"' . $annual_price . '",
    "month_price":"' . $month_price . '"
    }';
    // To Get Api URL
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $api_url . '/plan/create_plans',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS => $replace_txt,
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'
        ),
      )
    );
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service (user_sms_credit_raise) [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
    $response = curl_exec($curl);
    curl_close($curl);
    $sms = json_decode($response, false);
    site_log_generate("creation_plan Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response (user_sms_credit_raise) [$response] on " . date("Y-m-d H:i:s"), '../');
    if ($sms->response_status == 200) {
      $cnt_insrt++;
    }

  }

  if ($cnt_insrt > 0) {
    site_log_generate("creation_plan Page : User : " . $_SESSION['yjwatsp_user_name'] . " creation_plan Success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => "Success");
  } else {
    site_log_generate("creation_plan Page : User : " . $_SESSION['yjwatsp_user_name'] . " creation_plan failed [Data not inserted] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => $sms->response_msg);
  }
}
// creation_plan Page creation_plan - End


// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
