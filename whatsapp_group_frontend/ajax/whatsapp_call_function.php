<?php
session_start(); // start session
error_reporting(E_ALL); // The error reporting function

include_once('../api/configuration.php'); // Include configuration.php
include_once('site_common_functions.php'); // Include site_common_functions.php

extract($_REQUEST); // Extract the request

$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // add bearer token
$current_date = date("Y-m-d H:i:s"); // to get the today date
$milliseconds = round(microtime(true) * 1000); // milliseconds in time
$default_variale_msg = '-'; // default msg

// Step 1: Get the current date
$todayDate = new DateTime();
// Step 2: Convert the date to Julian date
$baseDate = new DateTime($todayDate->format('Y-01-01'));
$julianDate = $todayDate->diff($baseDate)->format('%a') + 1; // Adding 1 since the day of the year starts from 0
// Step 3: Output the result in 3-digit format
// echo "Today's Julian date in 3-digit format: " . str_pad($julianDate, 3, '0', STR_PAD_LEFT);
$year = date("Y");
$julian_dates = str_pad($julianDate, 3, '0', STR_PAD_LEFT);
$hour_minutes_seconds = date("His");
$random_generate_three = rand(100, 999);

// Template List Page tmpl_call_function remove_template - Start
if (isset($_GET['tmpl_call_function']) == "remove_template") {
  // Get data
  $template_response_id = htmlspecialchars(strip_tags(isset($_REQUEST['template_response_id']) ? $conn->real_escape_string($_REQUEST['template_response_id']) : ""));
  $change_status = htmlspecialchars(strip_tags(isset($_REQUEST['change_status']) ? $conn->real_escape_string($_REQUEST['change_status']) : ""));
  // To Send the request  API
  $replace_txt = '{
    "template_id" : "' . $template_response_id . '",
    "request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
  }';
  // add bearertoken
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  // It will call "delete_template" API to verify, can we access for the delete_template
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/template/delete_template',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'DELETE',
      CURLOPT_POSTFIELDS => $replace_txt,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'

      ),
    )
  );
  // Send the data into API and execute 
  site_log_generate("Template List Page : User : " . $_SESSION['yjwatsp_user_name'] . " send it to Service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
  $response = curl_exec($curl);
  curl_close($curl);
  // After got response decode the JSON result
  $state1 = json_decode($response, false);
  site_log_generate("Template List Page : User : " . $_SESSION['yjwatsp_user_name'] . " get Service response [$response] on " . date("Y-m-d H:i:s"), '../');

  if ($state1->response_code == 1) {
    site_log_generate("Template List Page : User : " . $_SESSION['yjwatsp_user_name'] . " delete template success on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => $state1->response_msg);
  } else if ($state1->response_status == 204) {
    site_log_generate("Template List Page : " . $user_name . "get the Service response [$state1->response_status] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 2, "msg" => $state1->response_msg);
  } else {
    site_log_generate("Template List Page: " . $user_name . " Template List Page [Invalid Inputs] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => "Template delete failure.");
  }
}
// Template List Page remove_template - End

// Compose SMS Page getSingleTemplate_meta - Start
if (isset($_GET['getSingleTemplate_meta']) == "getSingleTemplate_meta") {

  // GET DATAS
  $tmpl_name = explode('!', $tmpl_name);
  $load_templates = '{
                                "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
                                 "template_name" : "' . $tmpl_name[0] . '"
                          }';

  //$load_templates = '{"user_id" : "' . $_SESSION['yjwatsp_user_id'] . '" ,"template_name" : "' . $tmpl_name[0] . '"}'; // Add user id

  site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " Execute the service ($load_templates) on " . date("Y-m-d H:i:s"));
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // Add Bearer Token  
  // It will call "message_templates" API to verify, can we access for the message_templates

  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/template/get_single_template',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'GET',
      CURLOPT_POSTFIELDS => $load_templates,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Content-Type: application/json'

      ),
    )
  );
  // Send the data into API and execute
  $response = curl_exec($curl);
  curl_close($curl);
  $yjresponseobj = json_decode($response, false);
  if (count($yjresponseobj->get_single_template) > 0) {
    echo count($yjresponseobj->get_single_template[0]->template_message);
    $stateData = '';
    $stateData_box = '';
    $hdr_type = '';
    // Looping the ii is less than the count of data.if the condition is true to continue the process.if the condition are false to stop the process
    for ($ii = 0; $ii < count($yjresponseobj->get_single_template[0]->template_message); $ii++) {
      if ($yjresponseobj->data[$ii]->components[0]->type == 'HEADER') {
        switch ($yjresponseobj->data[$ii]->components[0]->format) {
          case 'TEXT': // text
            $hdr_type .= "<input type='hidden' name='hid_txt_header_variable' id='hid_txt_header_variable' value='" . $yjresponseobj->data[$ii]->components[0]->text . "'>";

            $stateData_1 = '';
            $stateData_1 = $yjresponseobj->data[$ii]->components[0]->text;
            $stateData_2 = $stateData_1;

            $matches = null;
            $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[0]->text, $matches);
            $matches_a0 = $matches[0];
            rsort($matches_a0);
            sort($matches_a0);
            for ($ij = 0; $ij < count($matches_a0); $ij++) {
              // Looping the ii is less than the count of matches_a0.if the condition is true to continue the process.if the condition are false to stop the process
              $expl2 = explode("{{", $matches_a0[$ij]);
              $expl3 = explode("}}", $expl2[1]);
              $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly tabindex='10' name='txt_header_variable[$expl3[0]][]' id='txt_header_variable' placeholder='{{" . $expl3[0] . "}} Value' title='Header Text' maxlength='20' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
              $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
              $stateData_2 = $stateData_1;
            }

            if ($stateData_2 != '') {
              $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
            }
            break;

          case 'DOCUMENT': //document
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left'><input type='file' style='margin-left:10px;'  class='form-control' name='file_document_header' id='file_document_header' tabindex='11' accept='application/pdf' data-toggle='tooltip' onblur='validate_filesizes(this)' onfocus='disable_texbox(\"file_document_header\", \"file_document_header_url\")' data-placement='top' data-html='true' title='Upload Any PDF file, below or equal to 5 MB Size' data-original-title='Upload Any PDF file, below or equal to 5 MB Size'></div><div style='float:left'><span style='color:#FF0000 ;margin-left:20px;'>[OR]</span></div><div style='float:left'><div class='' style='margin-left:10px;' data-toggle='tooltip' data-placement='top' title='Enter Document URL' data-original-title='Enter Document URL'>
                <div class='input-group'>
                  <input class='form-control form-control-primary' type='url' name='file_document_header_url' id='file_document_header_url' maxlength='100' title='Enter Document URL' onfocus='disable_texbox(\"file_document_header_url\", \"file_document_header\")' tabindex='12' placeholder='Enter Document URL'>
                </div>
              </div>
              </div></div>";
            break;


          case 'IMAGE': // Image
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left'><input type='file' style='margin-left:10px;' class='form-control' name='file_image_header' id='file_image_header' tabindex='11' accept='image/png,image/jpg,image/jpeg' data-toggle='tooltip' onblur='validate_filesizes(this)' onfocus='disable_texbox(\"file_image_header\", \"file_image_header_url\")' data-placement='top' data-html='true' title='Upload Any PNG, JPG, JPEG files, below or equal to 5 MB Size' data-original-title='Upload Any PNG, JPG, JPEG files, below or equal to 5 MB Size'></div><div style='float:left'><span style='color:#FF0000;margin-left:20px;'>[OR]</span></div><div style='float:left'><div class='' style='margin-left:10px;' data-toggle='tooltip' data-placement='top' title='Enter Image URL' data-original-title='Enter Image URL'>
                <div class='input-group'>
                  <input class='form-control form-control-primary' type='url' name='file_image_header_url' id='file_image_header_url' maxlength='100' title='Enter Image URL' tabindex='12' onfocus='disable_texbox(\"file_image_header_url\", \"file_image_header\")' placeholder='Enter Image URL'>
                  <span class='input-group-addon'><i class='icofont icofont-ui-messaging'></i></span>
                </div>
              </div>
              </div></div>";
            break;


          case 'VIDEO':  // Video
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left'><input type='file' style='margin-left:10px;' class='form-control' name='file_video_header' id='file_video_header' tabindex='11' accept='video/mp4' data-toggle='tooltip' onblur='validate_filesizes(this)' onfocus='disable_texbox(\"file_video_header\", \"file_video_header_url\")' data-placement='top' data-html='true' title='Upload Any MP4 file, below or equal to 5 MB Size' data-original-title='Upload Any MP4, MPEG, WEBM file, below or equal to 5 MB Size'></div><div style='float:left'><span style='color:#FF0000;margin-left:20px;'>[OR]</span></div><div style='float:left'><div class='' style='margin-left:10px;'data-toggle='tooltip' data-placement='top' title='Enter Video URL' data-original-title='Enter Video URL'>
                <div class='input-group'>
                  <input class='form-control form-control-primary' type='url' name='file_video_header_url' id='file_video_header_url' maxlength='100' title='Enter Video URL' tabindex='12' onfocus='disable_texbox(\"file_video_header_url\", \"file_video_header\")' placeholder='Enter Video URL'>
                  <span class='input-group-addon'><i class='icofont icofont-ui-messaging'></i></span>
                </div>
              </div>
              </div></div>";
            break;
        }

      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'BODY') { // Body text
        $hdr_type .= "<input type='hidden' name='hid_txt_body_variable'  style='margin-left:10px;'  id='hid_txt_body_variable' value='" . $yjresponseobj->data[$ii]->components[1]->text . "'>";

        $stateData_1 = '';
        $stateData_1 = $yjresponseobj->data[$ii]->components[1]->text;
        $stateData_2 = $stateData_1;

        $matches = null;
        $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[1]->text, $matches);
        $matches_a1 = $matches[0];
        rsort($matches_a1);
        sort($matches_a1);
        for ($ij = 0; $ij < count($matches_a1); $ij++) {
          // Looping the ij is less than the count of matches_a1.if the condition is true to continue the process.if the condition are false to stop the process
          $expl2 = explode("{{", $matches_a1[$ij]);
          $expl3 = explode("}}", $expl2[1]);
          $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly name='txt_body_variable[$expl3[0]][]' id='txt_body_variable' placeholder='{{" . $expl3[0] . "}} Value' maxlength='20' title='Enter {{" . $expl3[0] . "}} Value' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
          $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
          $stateData_2 = $stateData_1;
        }

        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Body : </div><div style='float:left;margin-left:10px;'>" . $stateData_2 . "</div></div>";
        }

      }

      if ($yjresponseobj->data[$ii]->components[0]->type == 'BODY') { // Body text
        $hdr_type .= "<input type='hidden' style='margin-left:10px;' name='hid_txt_body_variable' id='hid_txt_body_variable' value='" . $yjresponseobj->data[$ii]->components[0]->text . "'>";

        $stateData_1 = '';
        $stateData_1 = $yjresponseobj->data[$ii]->components[0]->text;
        $stateData_2 = $stateData_1;

        $matches = null;
        $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[0]->text, $matches);
        $matches_a1 = $matches[0];
        rsort($matches_a1);
        sort($matches_a1);
        for ($ij = 0; $ij < count($matches_a1); $ij++) {
          // Looping the ij is less than the count of matches_a1.if the condition is true to continue the process.if the condition are false to stop the process
          $expl2 = explode("{{", $matches_a1[$ij]);
          $expl3 = explode("}}", $expl2[1]);
          $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly name='txt_body_variable[$expl3[0]][]' id='txt_body_variable' placeholder='{{" . $expl3[0] . "}} Value' maxlength='20' tabindex='12' title='Enter {{" . $expl3[0] . "}} Value' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
          $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
          $stateData_2 = $stateData_1;
        }
        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Body : </div><div style='float:left;margin-left:10px;'>" . $stateData_2 . "</div></div>";
        }
      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'BUTTONS') {  // B Buttons
        $stateData_2 = '';
        if ($yjresponseobj->data[$ii]->components[1]->buttons[0]->type == 'URL') {
          $stateData_2 .= "<a href='" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->url . "' target='_blank'>" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->text . "</a>";
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons URL : </div><div style='float:left'>" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->url . " - " . $stateData_2 . "</div></div>";
        }

        if ($yjresponseobj->data[$ii]->components[1]->buttons[0]->type == 'PHONE_NUMBER') { // Phone number
          $stateData_2 .= $yjresponseobj->data[$ii]->components[1]->buttons[0]->text . " - " . $yjresponseobj->data[$ii]->components[1]->buttons[0]->phone_number;
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Phone No. : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
        // Looping the kk is less than the count of buttons.if the condition is true to continue the process.if the condition are false to stop the process
        for ($kk = 0; $kk < count($yjresponseobj->data[$ii]->components[1]->buttons); $kk++) { // Quickreply
          if ($yjresponseobj->data[$ii]->components[1]->buttons[$kk]->type == 'QUICK_REPLY') {
            $stateData_2 .= $yjresponseobj->data[$ii]->components[1]->buttons[$kk]->text;
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Quick Reply : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
          }
        }
      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'FOOTER') { // Footer
        $hdr_type .= "<input type='hidden' name='hid_txt_footer_variable' id='hid_txt_footer_variable' value='" . $yjresponseobj->data[$ii]->components[1]->text . "'>";

        $stateData_2 = '';
        $stateData_2 = $yjresponseobj->data[$ii]->components[1]->text;

        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Footer : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
      }
      if ($yjresponseobj->data[$ii]->components[2]->type == 'BUTTONS') { // Buttons
        $stateData_2 = '';

        if ($yjresponseobj->data[$ii]->components[2]->buttons[0]->type == 'URL') {
          $stateData_2 .= "<a href='" . $yjresponseobj->data[$ii]->components[2]->buttons[0]->url . "' target='_blank'>" . $yjresponseobj->data[$ii]->components[2]->buttons[0]->text . "</a>";
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons URL : </div><div style='float:left'>" . $yjresponseobj->data[$ii]->components[2]->buttons[0]->url . " - " . $stateData_2 . "</div></div>";
        }

        if ($yjresponseobj->data[$ii]->components[2]->buttons[0]->type == 'PHONE_NUMBER') { // Phone Number
          $stateData_2 .= $yjresponseobj->data[$ii]->components[2]->buttons[0]->text . " - " . $yjresponseobj->data[$ii]->components[2]->buttons[0]->phone_number;
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Phone No. : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
        // Looping the kk is less than the count of buttons.if the condition is true to continue the process.if the condition are false to stop the process
        for ($kk = 0; $kk < count($yjresponseobj->data[$ii]->components[2]->buttons); $kk++) { //QUICK_REPLY
          if ($yjresponseobj->data[$ii]->components[2]->buttons[$kk]->type == 'QUICK_REPLY') {
            $stateData_2 .= $yjresponseobj->data[$ii]->components[2]->buttons[$kk]->text;
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Quick Reply : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
          }
        }
      }
    }
    site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Meta Message Template available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => $stateData . $hdr_type);
  } else {
    site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Message Template not available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => '-');
  }
}
// Compose SMS Page getSingleTemplate_meta - End

// Compose SMS Page PreviewTemplate - Start
if (isset($_GET['previewTemplate_meta']) == "previewTemplate_meta") {

  $tmpl_name = explode('!', $tmpl_name);
  // Get data
  $wht_tmpl_url = htmlspecialchars(strip_tags(isset($_REQUEST['wht_tmpl_url']) ? $conn->real_escape_string($_REQUEST['wht_tmpl_url']) : ""));
  $wht_bearer_token = htmlspecialchars(strip_tags(isset($_REQUEST['wht_bearer_token']) ? $conn->real_escape_string($_REQUEST['wht_bearer_token']) : ""));
  // To Get Api URL
  $curl_get = $wht_tmpl_url . "/message_templates?name=" . $tmpl_name[0] . "&language=" . $tmpl_name[1];
  // add bearertoken
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  // To Send the request  API
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $curl_get,
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_SSL_VERIFYPEER => 0,
      CURLOPT_CUSTOMREQUEST => 'GET',
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        'Authorization: Bearer ' . $wht_bearer_token
      ),
    )
  );

  $yjresponse = curl_exec($curl);
  //echo $yjresponse;
  curl_close($curl);
  $yjresponseobj = json_decode($yjresponse, false);

  if (count($yjresponseobj->data) > 0) {
    $stateData = '';
    $stateData_box = '';
    $hdr_type = '';
    // Looping the ii is less than the count of response data.if the condition is true to continue the process.if the condition are false to stop the process
    for ($ii = 0; $ii < count($yjresponseobj->data); $ii++) {
      if ($yjresponseobj->data[$ii]->components[0]->type == 'HEADER') { //header
        switch ($yjresponseobj->data[$ii]->components[0]->format) {
          case 'TEXT':
            $hdr_type .= "<input type='hidden' name='hid_txt_header_variable' id='hid_txt_header_variable' value='" . $yjresponseobj->data[$ii]->components[0]->text . "'>";

            $stateData_1 = '';
            $stateData_1 = $yjresponseobj->data[$ii]->components[0]->text;
            $stateData_2 = $stateData_1;

            $matches = null;
            $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[0]->text, $matches);
            $matches_a0 = $matches[0];
            rsort($matches_a0);
            sort($matches_a0);
            for ($ij = 0; $ij < count($matches_a0); $ij++) {
              // Looping the ij is less than the count of matches_a0.if the condition is true to continue the process.if the condition are false to stop the process
              $expl2 = explode("{{", $matches_a0[$ij]);
              $expl3 = explode("}}", $expl2[1]);
              $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly tabindex='10' name='txt_header_variable[$expl3[0]][]' id='txt_header_variable' placeholder='{{" . $expl3[0] . "}} Value' title='Header Text' maxlength='20' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
              $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
              $stateData_2 = $stateData_1;
            }

            if ($stateData_2 != '') {
              $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
            }
            break;
          case 'DOCUMENT': //document
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left;margin-left:10px;'><a href=" . $yjresponseobj->data[$ii]->components[0]->example->header_handle[0] . " target='_blank'>Document Link</a></div>";
            break;
          case 'IMAGE': // Image
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left;margin-left:10px;'><a href=" . $yjresponseobj->data[$ii]->components[0]->example->header_handle[0] . " target='_blank'><img src=" . $yjresponseobj->data[$ii]->components[0]->example->header_handle[0] . " alt='image' style='width:600px;height:700px' ></a></div>";
            break;
          case 'VIDEO':  // Video
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Header : </div><div style='float:left;margin-left:10px; '><a href=" . $yjresponseobj->data[$ii]->components[0]->example->header_handle[0] . " target='_blank'>Video Link</a></div>";
            break;
        }
      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'BODY') { //body
        $hdr_type .= "<input type='hidden' style='margin-left:10px;' name='hid_txt_body_variable' id='hid_txt_body_variable' value='" . $yjresponseobj->data[$ii]->components[1]->text . "'>";

        $stateData_1 = '';
        $stateData_1 = $yjresponseobj->data[$ii]->components[1]->text;
        $stateData_2 = $stateData_1;

        $matches = null;
        $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[1]->text, $matches);
        $matches_a1 = $matches[0];
        rsort($matches_a1);
        sort($matches_a1);
        for ($ij = 0; $ij < count($matches_a1); $ij++) {
          // Looping the ij is less than the count of matches_a1.if the condition is true to continue the process.if the condition are false to stop the process
          $expl2 = explode("{{", $matches_a1[$ij]);
          $expl3 = explode("}}", $expl2[1]);
          $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly name='txt_body_variable[$expl3[0]][]' id='txt_body_variable' placeholder='{{" . $expl3[0] . "}} Value' maxlength='20' title='Enter {{" . $expl3[0] . "}} Value' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
          $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
          $stateData_2 = $stateData_1;
        }

        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Body : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }


      }

      if ($yjresponseobj->data[$ii]->components[0]->type == 'BODY') { // body
        $hdr_type .= "<input type='hidden'  style='margin-left:10px;' name='hid_txt_body_variable' id='hid_txt_body_variable' value='" . $yjresponseobj->data[$ii]->components[0]->text . "'>";

        $stateData_1 = '';
        $stateData_1 = $yjresponseobj->data[$ii]->components[0]->text;
        $stateData_2 = $stateData_1;

        $matches = null;
        $prmt = preg_match_all("/{{[0-9]+}}/", $yjresponseobj->data[$ii]->components[0]->text, $matches);
        $matches_a1 = $matches[0];
        rsort($matches_a1);
        sort($matches_a1);
        for ($ij = 0; $ij < count($matches_a1); $ij++) {
          // Looping the ij is less than the count of matches_a1.if the condition is true to continue the process.if the condition are false to stop the process
          $expl2 = explode("{{", $matches_a1[$ij]);
          $expl3 = explode("}}", $expl2[1]);
          $stateData_box = "</div><div style='float:left; padding: 0 5px;'> <input type='text' readonly name='txt_body_variable[$expl3[0]][]' id='txt_body_variable' placeholder='{{" . $expl3[0] . "}} Value' maxlength='20' tabindex='12' title='Enter {{" . $expl3[0] . "}} Value' value='-' style='width:100px;height: 30px;cursor: not-allowed;margin-top:10px;' class='form-control required'> </div><div style='float: left;'>";
          $stateData_1 = str_replace("{{" . $expl3[0] . "}}", $stateData_box, $stateData_1);
          $stateData_2 = $stateData_1;
        }
        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Body : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'BUTTONS') { // buttons
        $stateData_2 = '';
        if ($yjresponseobj->data[$ii]->components[1]->buttons[0]->type == 'URL') {
          $stateData_2 .= "<a href='" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->url . "' target='_blank'>" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->text . "</a>";
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons URL : </div><div style='float:left'>" . $yjresponseobj->data[$ii]->components[1]->buttons[0]->url . " - " . $stateData_2 . "</div></div>";
        }
        if ($yjresponseobj->data[$ii]->components[1]->buttons[1]->type == 'URL') {
          $stateData_2 .= "<a href='" . $yjresponseobj->data[$ii]->components[1]->buttons[1]->url . "' target='_blank'>" . $yjresponseobj->data[$ii]->components[1]->buttons[1]->text . "</a>";
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons URL : </div><div style='float:left'>" . $yjresponseobj->data[$ii]->components[1]->buttons[1]->url . " - " . $stateData_2 . "</div></div>";
        }
        $stateData_2 = '';
        if ($yjresponseobj->data[$ii]->components[1]->buttons[0]->type == 'PHONE_NUMBER') { // PHONE_NUMBER
          $stateData_2 .= $yjresponseobj->data[$ii]->components[1]->buttons[0]->text . " - " . $yjresponseobj->data[$ii]->components[1]->buttons[0]->phone_number;
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Phone No : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
        // Looping the ij is less than the count of buttons.if the condition is true to continue the process.if the condition are false to stop the process
        for ($kk = 0; $kk < count($yjresponseobj->data[$ii]->components[1]->buttons); $kk++) { // QUICK_REPLY
          if ($yjresponseobj->data[$ii]->components[1]->buttons[$kk]->type == 'QUICK_REPLY') {
            $stateData_2 .= $yjresponseobj->data[$ii]->components[1]->buttons[$kk]->text;
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Quick Reply : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
          }
        }
      }

      if ($yjresponseobj->data[$ii]->components[1]->type == 'FOOTER') { // FOOTER
        $hdr_type .= "<input type='hidden' name='hid_txt_footer_variable' id='hid_txt_footer_variable' value='" . $yjresponseobj->data[$ii]->components[1]->text . "'>";

        $stateData_2 = '';
        $stateData_2 = $yjresponseobj->data[$ii]->components[1]->text;

        if ($stateData_2 != '') {
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Footer : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
      }

      if ($yjresponseobj->data[$ii]->components[2]->type == 'BUTTONS') { // BUTTONS
        $stateData_2 = '';

        if ($yjresponseobj->data[$ii]->components[2]->buttons[0]->type == 'URL') {
          $stateData_2 .= "<a href='" . $yjresponseobj->data[$ii]->components[2]->buttons[1]->url . "' target='_blank'>" . $yjresponseobj->data[$ii]->components[2]->buttons[0]->text . "</a>";
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons URL : </div><div style='float:left'>" . $yjresponseobj->data[$ii]->components[2]->buttons[0]->url . " - " . $stateData_2 . "</div></div>";
        }

        if ($yjresponseobj->data[$ii]->components[2]->buttons[0]->type == 'PHONE_NUMBER') { // PHONE_NUMBER
          $stateData_2 .= $yjresponseobj->data[$ii]->components[2]->buttons[0]->text . " - " . $yjresponseobj->data[$ii]->components[2]->buttons[0]->phone_number;
          $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'>Buttons Phone No. : </div><div style='float:left'>" . $stateData_2 . "</div></div>";
        }
        // Looping the kk is less than the count of buttons.if the condition is true to continue the process.if the condition are false to stop the process
        for ($kk = 0; $kk < count($yjresponseobj->data[$ii]->components[2]->buttons); $kk++) { // QUICK_REPLY
          if ($yjresponseobj->data[$ii]->components[2]->buttons[$kk]->type == 'QUICK_REPLY') {
            $stateData_2 .= $yjresponseobj->data[$ii]->components[2]->buttons[$kk]->text;
            $stateData .= "<div style='float:left; clear:both; line-height: 36px;'><div style='float:left; line-height: 36px;'><b>Buttons Quick Reply : </b></div><div style='float:left'>" . $stateData_2 . "</div></div>";
          }
        }
      }
    }
    site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Meta Message Template available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 1, "msg" => $stateData . $hdr_type);
  } else {
    site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Message Template not available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => '-');
  }
}
// Compose SMS Page PreviewTemplate - End

// Compose SMS Page validateMobno - Start
if (isset($_POST['validateMobno']) == "validateMobno") {
  // Get data
  $mobno = str_replace('"', '', htmlspecialchars(strip_tags(isset($_POST['mobno']) ? $conn->real_escape_string($_POST['mobno']) : "")));
  $dup = htmlspecialchars(strip_tags(isset($_POST['dup']) ? $conn->real_escape_string($_POST['dup']) : ""));
  $inv = htmlspecialchars(strip_tags(isset($_POST['inv']) ? $conn->real_escape_string($_POST['inv']) : ""));
  // To validate the mobile number
  $mobno = str_replace('\n', ',', $mobno);
  $newline = explode('\n', $mobno);
  $correct_mobno_data = [];
  $return_mobno_data = '';
  $issu_mob = '';
  $cnt_vld_no = 0;
  $max_vld_no = 1000;
  for ($i = 0; $i < count($newline); $i++) {
    // Looping the i is less than the count of newline.if the condition is true to continue the process.if the condition are false to stop the process
    $expl = explode(",", $newline[$i]);
    // Looping  with in the looping the ij is less than the count of expl.if the condition is true to continue the process.if the condition are false to stop the process
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
  $json = array("status" => 1, "msg" => $return_mobno_data . "||" . $issu_mob);
}
// Compose SMS Page validateMobno - End



// Compose Whatsapp Page compose_whatsapp - Start
if ($_SERVER['REQUEST_METHOD'] == "GET" and $tmpl_call_function == "compose_whatsapp") {
  site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " Compose Whatsapp failed [GET NOT ALLOWED] on " . date("Y-m-d H:i:s"), '../');
  $json = array("status" => 0, "msg" => "Get Method not allowed here!");
}

if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "compose_whatsapp") {
  site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');

  // Send Whatsapp Message - Start
  $tmpl_name1 = explode('!', $slt_whatsapp_template);
  $template_name = $tmpl_name1[0];

  $wht_group = explode('!', $slt_whatsapp_group);
  $Whatsapp_group = $wht_group[0];

  $sendto_api = '{
                        "sender_numbers":[' . $sender_mobile_nos . '],
                        "template_name" : "' . $template_name . '",
                        "group_name" : "' . $Whatsapp_group . '",
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
                      }';


  site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " api send text [$sendto_api] on " . date("Y-m-d H:i:s"), '../');
  // add bearer token
  $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
  // It will call "compose_whatsapp_message" API to verify, can we access for thecompose_whatsapp_message
  $curl = curl_init();
  curl_setopt_array(
    $curl,
    array(
      CURLOPT_URL => $api_url . '/compose_whatsapp_message',
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_ENCODING => '',
      CURLOPT_MAXREDIRS => 10,
      CURLOPT_TIMEOUT => 0,
      CURLOPT_FOLLOWLOCATION => true,
      CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
      CURLOPT_CUSTOMREQUEST => 'POST',
      CURLOPT_POSTFIELDS => $sendto_api,
      CURLOPT_HTTPHEADER => array(
        $bearer_token,
        "cache-control: no-cache",
        'Content-Type: application/json; charset=utf-8'

      ),
    )
  );
  // Send the data into API and execute 
  $response = curl_exec($curl);
  curl_close($curl);
  // After got response decode the JSON result
  $respobj = json_decode($response);
  if($respobj == ''){
    header("location: ../index");
  }
  site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " api send text - Response [$response] on " . date("Y-m-d H:i:s"), '../');

  $rsp_id = $respobj->response_status;

  $rsp_msg = strtoupper($respobj->response_msg);
  if ($rsp_id == 203) {
    $json = array("status" => 2, "msg" => "Invalid User, Kindly try again with Valid User!!");
    site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Invalid User, Kindly try again with Valid User!!] on " . date("Y-m-d H:i:s"), '../');
  } else if ($rsp_id == 201) {
    $json = array("status" => 0, "msg" => "Failure - $rsp_msg");
    site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Failure - $rsp_msg] on " . date("Y-m-d H:i:s"), '../');
  } else {
    $json = array("status" => 1, "msg" => "Campaign Name Created Successfully!!");
    site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " [Success] on " . date("Y-m-d H:i:s"), '../');
  }
  site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " newconn new db connection closed on " . date("Y-m-d H:i:s"), '../');
}

// Compose Whatsapp Page compose_whatsapp - End

// Create Template create_template - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $temp_call_function == "create_template") {
  // Get data
  $categories = htmlspecialchars(strip_tags(isset($_REQUEST['categories']) ? $conn->real_escape_string($_REQUEST['categories']) : ""));

  // $textarea_txt = htmlspecialchars(strip_tags(isset($_REQUEST['textarea_new']) ? $conn->real_escape_string($_REQUEST['textarea_new']) : ""));
  $textarea_html = isset($_REQUEST['textarea_new']) ? $_REQUEST['textarea_new'] : "";

  // Define the allowed tags
  $allowedTags = ['br', 'b', 'p', 'a'];
  $cleanedHtml = strip_tags($textarea_html, '<' . implode('><', $allowedTags) . '>');

  // echo $cleanedHtml;  // Output the cleaned HTML content

  $hrefValue = '';
  $element_url_content = '';
  $message_content = '';
  $message_content_body = '';
  $message_content_a = '';

  // Use DOMDocument only if you need to manipulate the HTML further
  $dom = new DOMDocument;
  $dom->loadHTML($cleanedHtml);

  $xpath = new DOMXPath($dom);

  // Change <b> to bold
  $bold_nodes = $xpath->query('//b//span');
  foreach ($bold_nodes as $bold_node) {
    $bold_content = $bold_node->textContent;
    // Create a new text node with the desired format
    $formatted_text = $dom->createTextNode('*' . $bold_content . '*');
    // Replace the <b> tag with the formatted text node
    $bold_node->parentNode->replaceChild($formatted_text, $bold_node);
  }

  // Get the updated HTML content
  $boldupdated_html = $dom->saveHTML();
  // echo $boldupdated_html;
  $dom = new DOMDocument;
  $dom->loadHTML($boldupdated_html);
  $xpath = new DOMXPath($dom);

  $query = "//body//p";  // XPath query to select <p> tags within <body>
  $p_elements = $xpath->query($query);

  foreach ($p_elements as $p_element) {
    // echo "p tag";
    // Get the innerHTML of the <p> tag (including HTML tags)
    $inner_html = $dom->saveHTML($p_element);
    // Remove the <p> tags, if needed
    $message_content_body .= str_replace(['<p>', '</p>'], '', $inner_html);
  }

  $anchor_tag = $dom->getElementsByTagName('a');
  foreach ($anchor_tag as $element) {

    $hrefValue = $element->getAttribute('href');
    $element_url_content = $element->textContent;
  }

  if ($message_content_body) {
    $message_content_a .= strip_tags($message_content_body, '<br>');
    // Use a regular expression to remove the last <br> tag
    $message_content_a = preg_replace('/<br>(?=(?:[^<]*<\/br>)*[^<]*$)/', '', $message_content_a);
    $message_content = str_replace($element_url_content, '', $message_content_a);
  }

  // Output or use $hrefValue and $element_url_content as needed
  $message_content = str_replace("'", "\'", $message_content);
  $message_content = str_replace('"', '\"', $message_content);
  $message_content = str_replace("\\r\\n", '\n', $message_content);

  $txt_header_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_header_name']) ? $conn->real_escape_string($_REQUEST['txt_header_name']) : ""));
  $txt_footer_name = htmlspecialchars(strip_tags(isset($_REQUEST['txt_footer_name']) ? $conn->real_escape_string($_REQUEST['txt_footer_name']) : ""));
  $media_category = htmlspecialchars(strip_tags(isset($_REQUEST['media_category']) ? $conn->real_escape_string($_REQUEST['media_category']) : ""));
  $txt_header_variable = htmlspecialchars(strip_tags(isset($_REQUEST['txt_header_variable']) ? $conn->real_escape_string($_REQUEST['txt_header_variable']) : ""));
  // To get the one by one data from the array
  foreach ($lang as $lang_id) {
    $langid .= $lang_id . "";
  }
  $language = explode("-", $langid);
  $language_code = $language[0];
  $language_id = $language[1];
  if ($language_code == 'en_GB' || $language_code == 'en_US') {
    $code .= "t";
  } else {
    $code .= "l";
  }
  $user_id = $_SESSION['yjwatsp_user_id'];
  /*foreach ($select_action1 as $slt_action1) {
    $slt_action_1 .= '"' . $slt_action1 . '"';
  }
  foreach ($select_action4 as $slt_action4) {
    $slt_action_4 .= '"' . $slt_action4 . '"';
  }
  foreach ($select_action5 as $slt_action5) {
    $slt_action_5 .= '"' . $slt_action5 . '"';
  }
  foreach ($select_action3 as $slt_action3) {
    $slt_action_3 .= '"' . $slt_action3 . '"';
  }
  foreach ($website_url as $web_url) {
    $web_url_link .= $web_url;

  }
  foreach ($button_url_text as $btn_txt_url) {
    $btn_txt_url_name .= $btn_txt_url;

  }
  foreach ($button_txt_phone_no as $btn_txt_phn) {
    $btn_txt_phn_no .= $btn_txt_phn;

  }
  foreach ($button_text as $btn_txt) {
    $btn_txt_name .= $btn_txt;

  }
  foreach ($txt_sample as $txt_variable) {
    $txt_sample_variable .= '"' . $txt_variable . '"' . ',';

  }
  $txt_variable = rtrim($txt_sample_variable, ",");
  foreach ($button_quickreply_text as $txt_button_qr_txt) {
    $txt_button_qr_text1 .= '"' . $txt_button_qr_txt . '"' . ',';
  }
  $txt_button_qr_text = explode(",", $txt_button_qr_text1);
  $txt_button_qr_text_1 = $txt_button_qr_text[0];
  $txt_button_qr_text_2 = $txt_button_qr_text[1];
  $txt_button_qr_text_3 = $txt_button_qr_text[2];
  $reply_arr = array();
  if ($txt_button_qr_text_1) {
    $reply_array .= '
  {"type":"QUICK_REPLY","text":' . $txt_button_qr_text_1 . '}';
    array_push($reply_arr, $reply_array);

  }
  if ($txt_button_qr_text_2) {
    $reply_array .= ',
  {"type":"QUICK_REPLY", "text":' . $txt_button_qr_text_2 . '}';
    array_push($reply_arr, $reply_array);
  }
  if ($txt_button_qr_text_3) {
    $reply_array .= ',
  {"type":"QUICK_REPLY", "text": ' . $txt_button_qr_text_3 . '}';
    array_push($reply_arr, $reply_array);
  }
  foreach ($reply_arr as $reply_arr1) {
    $reply_array_content = $reply_arr1;
  }*/

  // select option to get the value
  $selectOption = $_POST['header'];
  $select_action = $_POST['select_action'];
  $select_action1 = $_POST['select_action1'];
  $select_action2 = $_POST['select_action2'];
  $select_action3 = $_POST['select_action3'];
  $select_action4 = $_POST['select_action4'];
  $select_action5 = $_POST['select_action5'];
  $country_code = $_POST['country_code'];
  // define the value
  $whtsap_send = '';
  $add_url_btn = '';
  $add_phoneno_btn = '';

  if ($message_content && $txt_variable) { // TextArea with Body Variable
    $whtsap_send .= '[
    {
      "type":"BODY", 
      "text":"' . $message_content . '",
      "example":{"body_text":[[' . $txt_variable . ']]}
  }';
  }
  if ($message_content && !$txt_variable) { // Only Textarea

    $whtsap_send .= '[ { 
                          "type": "BODY",
                          "text": "' . $message_content . '"
                        }';

    if ($hrefValue && $element_url_content) {

      $whtsap_send .= ',
            {
              "type":"BUTTONS",
                  "buttons":[{"type":"URL", "text": "' . $element_url_content . '","url":"' . $hrefValue . '"}
                    ]
                    }';
    }

  }

  if ($selectOption == 'TEXT') { // Text using Header Text
    switch ($selectOption == 'TEXT') {

      case $txt_header_name && !$txt_header_variable:
        $code .= "h";
        $whtsap_send .= ', 
        {
            "type":"HEADER", 
            "format":"TEXT",
            "text":"' . $txt_header_name . '"
        }';
        break;
      case $txt_header_name && $txt_header_variable: // Using Header Variable
        $code .= "h";
        $whtsap_send .= ', 
        {
            "type":"HEADER", 
            "format":"TEXT",
            "text":"' . $txt_header_name . '",
            "example":{"header_text":["' . $txt_header_variable . '"]}
        }';
        break;
      default:
        # code...
        break;
    }
  } else {

    $code .= "0";
  }

  if ($selectOption == 'MEDIA') { // Media
    switch ($media_category) {
      case 'image':
        $code .= "i00";
        break;
      case 'video':
        $code .= "0v0";
        break;
      case 'document':
        $code .= "00d";
        break;
      default:
        # code...
        break;
    }
  } else {
    $code .= "000";
  }
  // VISIT_URL
  if ($select_action5 == "VISIT_URL" && $btn_txt_url_name && $web_url_link) {
    $add_url_btn .= ',
                                      {
                                              "type":"URL", "text": "' . $btn_txt_url_name . '","url":"' . $web_url_link . '"
                                      }';

  } // PHONE_NUMBER
  if ($select_action4 == "PHONE_NUMBER" && $btn_txt_name && $btn_txt_phn_no && $country_code) {
    $add_phoneno_btn .= ',
                                        {"type":"PHONE_NUMBER","text":"' . $btn_txt_name . '","phone_number":"' . $country_code . '' . $btn_txt_phn_no . '" }';

  }
  // PHONE_NUMBER with add anothor button 
  if ($select_action1 == "PHONE_NUMBER" && $btn_txt_name && $btn_txt_phn_no && $country_code && $add_url_btn) {

    $code .= "cu"; // PHONE_NUMBER
  } else if ($select_action1 == "PHONE_NUMBER" && $btn_txt_name && $btn_txt_phn_no && $country_code) {
    $code .= "c0"; // VISIT_URL
  } else if ($select_action1 == "VISIT_URL" && $btn_txt_url_name && $web_url_link && $add_phoneno_btn) {
    $code .= "cu";
  } // VISIT_URL
  else if ($element_url_content && $hrefValue) {
    $code .= "0u";
  } else {

    $code .= "00";
  } // quickreply
  if ($select_action == "QUICK_REPLY") {
    if ($txt_button_qr_text_1) {
      $code .= "r";
    }
  } else {

    $code .= "0";
  }
  if ($txt_footer_name) { // footer
    $code .= "f";
    $whtsap_send .= ', 							
                      {
                        "type":"FOOTER", 
                        "text":"' . $txt_footer_name . '"
                    }';

  } else {

    $code .= "0";
  } // PHONE_NUMBER and add url button
  if ($select_action1 == "PHONE_NUMBER" && $btn_txt_name && $btn_txt_phn_no && $country_code && $add_url_btn) {

    $whtsap_send .= ',
                                    {
                                      "type":"BUTTONS",
                                      "buttons":[{"type":"PHONE_NUMBER","text":"' . $btn_txt_name . '","phone_number":"' . $country_code . '' . $btn_txt_phn_no . '"} ' . $add_url_btn . ' ]
                                  
                                   }';
    // PHONE_NUMBER 
  } else if ($select_action1 == "PHONE_NUMBER" && $btn_txt_name && $btn_txt_phn_no && $country_code) {

    $whtsap_send .= ',
                                      {
                                        "type":"BUTTONS",
                                        "buttons":[{"type":"PHONE_NUMBER","text":"' . $btn_txt_name . '","phone_number":"' . $country_code . '' . $btn_txt_phn_no . '"}]
                                    
                                      }';
  }
  // VISIT_URL and add phone number button
  if ($select_action1 == "VISIT_URL" && $btn_txt_url_name && $web_url_link && $add_phoneno_btn) {

    $whtsap_send .= ',
                                    {
                                      "type":"BUTTONS",
                                          "buttons":[{"type":"URL", "text": "' . $btn_txt_url_name . '","url":"' . $web_url_link . '"}
                                          ' . $add_phoneno_btn . '	]	
                                          }';
    // VISIT_URL button
  } else if ($select_action1 == "VISIT_URL" && $btn_txt_url_name && $web_url_link) {

    $whtsap_send .= ',
                                            {
                                              "type":"BUTTONS",
                                                  "buttons":[{"type":"URL", "text": "' . $btn_txt_url_name . '","url":"' . $web_url_link . '"}
                                                    ]
                                                    }';
  } // QUICK_REPLY button
  if ($select_action == "QUICK_REPLY") {
    if ($txt_button_qr_text_1) {
      $whtsap_send .= ',
                                      {
                                        "type":"BUTTONS",
                      "buttons":[' . $reply_array_content . ']
                                      }';


    }
  }

  $whtsap_send .= '
                                    ]';

  // MEDIA select option
  if ($selectOption == 'MEDIA') {
    switch ($media_category) {
      case 'image':  // Image
        if (isset($_FILES['file_image_header']['name'])) {
          /* Location */
          $image_size = $_FILES['file_image_header']['size'];
          $image_type = $_FILES['file_image_header']['type'];
          $file_type = explode("/", $image_type);

          $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];
          $location = $full_pathurl . "uploads/whatsapp_images/" . $filename;
          $location_1 = $site_url . "uploads/whatsapp_images/" . $filename;
          $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
          $imageFileType = strtolower($imageFileType);
          //$location = $site_url . "uploads/whatsapp_images/" . $filename;
          /* Valid extensions */
          $valid_extensions = array("png", "jpg", "jpeg");

          $rspns = '';
          /* Check file extension */
          // if (in_array(strtolower($imageFileType), $valid_extensions)) {
          /* Upload file */
          if (move_uploaded_file($_FILES['file_image_header']['tmp_name'], $location)) {
            $rspns = $location;
            site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_images file moved into Folder on " . date("Y-m-d H:i:s"), '../');
          }
        }
        // add bearer token
        $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
        // It will call "template_get_url" API to verify, can we access for the template_get_url
        $curl = curl_init();
        curl_setopt_array(
          $curl,
          array(
            CURLOPT_URL => $template_get_url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS => '{
      "language" : "' . $language_code . '",
      "category" : "' . $categories . '",
 "code" : "' . $code . '",
      "media_url": "' . $location_1 . '",
      "components" : ' . $whtsap_send . ',
 "request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
    }',
            CURLOPT_HTTPHEADER => array(
              $bearer_token,
              'Content-Type: application/json'

            ),
          )
        );

        $log_1 = '{
			"language" : "' . $language_code . '",
			"category" : "' . $categories . '",
 "code" : "' . $code . '",
			"media_url": "' . $location_1 . '",
			"components" : ' . $whtsap_send . ',
  "request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
	}';
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the log ($log_1) on " . date("Y-m-d H:i:s"), '../');
        // Send the data into API and execute 
        $response = curl_exec($curl);
        curl_close($curl);
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the response ($response) on " . date("Y-m-d H:i:s"), '../');
        // After got response decode the JSON result
        $obj = json_decode($response);
        if ($obj->response_status == 200) { //success
          $json = array("status" => 1, "msg" => $obj->response_msg);
        } else {
          $json = array("status" => 0, "msg" => $obj->response_msg);
        }

        break;
      case 'document':   // Document
        if (isset($_FILES['file_image_header']['name'])) {

          $image_size = $_FILES['file_image_header']['size'];
          $image_type = $_FILES['file_image_header']['type'];
          $file_type = explode("/", $image_type);

          $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];
          $location = $full_pathurl . "uploads/whatsapp_docs/" . $filename;
          $location_1 = $site_url . "uploads/whatsapp_docs/" . $filename;
          $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
          $imageFileType = strtolower($imageFileType);
          //$location = $site_url . "uploads/whatsapp_docs/" . $filename;
          /* Valid extensions */
          $valid_extensions = array("pdf");

          $rspns = '';
          /* Check file extension */
          if (in_array(strtolower($imageFileType), $valid_extensions)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['file_image_header']['tmp_name'], $location)) {
              $rspns = $location;
              site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_docs file moved into Folder on " . date("Y-m-d H:i:s"), '../');
            }
          }
        }
        // Add bearertoken
        $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
        // It will call "template_get_url" API to verify, can we access for the template_get_url
        $curl = curl_init();
        curl_setopt_array(
          $curl,
          array(
            CURLOPT_URL => $template_get_url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS => '{
"language" : "' . $language_code . '",
"category" : "' . $categories . '",
"code" : "' . $code . '",
"media_url": "' . $location_1 . '",
"components" : ' . $whtsap_send . ',
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
}',
            CURLOPT_HTTPHEADER => array(
              $bearer_token,
              'Content-Type: application/json'
            ),
          )
        );

        $log_2 = '{
			"language" : "' . $language_code . '",
			"category" : "' . $categories . '",
 "code" : "' . $code . '",
			"media_url": "' . $location_1 . '",
			"components" : ' . $whtsap_send . ',
      "request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
	}';
        // Send the data into API and execute 
        $response = curl_exec($curl);
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the log ($log_2) on " . date("Y-m-d H:i:s"), '../');
        // After got response decode the JSON result
        curl_close($curl);
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the response ($response) on " . date("Y-m-d H:i:s"), '../');
        $obj = json_decode($response);
        if ($obj->response_status == 200) { //success
          $json = array("status" => 1, "msg" => $obj->response_msg);
        } else {
          $json = array("status" => 0, "msg" => $obj->response_msg);
        }

        break;
      case 'video': // video
        if (isset($_FILES['file_image_header']['name'])) {

          $image_size = $_FILES['file_image_header']['size'];
          $image_type = $_FILES['file_image_header']['type'];
          $file_type = explode("/", $image_type);
          $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];

          /* Location */
          $location = $full_pathurl . "uploads/whatsapp_videos/" . $filename;
          $location_1 = $site_url . "uploads/whatsapp_videos/" . $filename;

          $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
          $imageFileType = strtolower($imageFileType);
          $image_size = $_FILES['file_image_header']['size'];
          $image_type = $_FILES['file_image_header']['type'];
          //$location = $site_url . "uploads/whatsapp_videos/" . $filename;
          /* Valid extensions */
          $valid_extensions = array("mp4");

          $rspns = '';
          /* Check file extension */
          if (in_array(strtolower($imageFileType), $valid_extensions)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['file_image_header']['tmp_name'], $location)) {
              $rspns = $location;
              site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_videos file moved into Folder on " . date("Y-m-d H:i:s"), '../');
            }
          }
        }
        // Add Bearertoken
        $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
        // It will call "template_get_url" API to verify, can we access for the template_get_url
        $curl = curl_init();
        curl_setopt_array(
          $curl,
          array(
            CURLOPT_URL => $template_get_url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => '',
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 0,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => 'POST',
            CURLOPT_POSTFIELDS => '{
"language" : "' . $language_code . '",
"category" : "' . $categories . '",
"code" : "' . $code . '",
"media_url": "' . $location_1 . '",
"components" : ' . $whtsap_send . ',
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
}',
            CURLOPT_HTTPHEADER => array(
              $bearer_token,
              'Content-Type: application/json'

            ),
          )
        );

        $log_3 = '{
			"language" : "' . $language_code . '",
			"category" : "' . $categories . '",
 "code" : "' . $code . '",
			"media_url": "' . $location_1 . '",
			"components" : ' . $whtsap_send . ',
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
	}';  // Send the data into API and execute 
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the log ($log_3) on " . date("Y-m-d H:i:s"), '../');
        $response = curl_exec($curl);
        curl_close($curl);
        site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the response ($response) on " . date("Y-m-d H:i:s"), '../');
        // After got response decode the JSON result
        $obj = json_decode($response);
        if ($obj->response_status == 200) { //success
          $json = array("status" => 1, "msg" => $obj->response_msg);
        } else {
          $json = array("status" => 0, "msg" => $obj->response_msg);
        }
        break;
      default:
        # code...
        break;
    }
  } else {
    // Add Bearer token
    $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
    // It will call "messenger_view_response" API to verify, can we access for the messenger view response
    $curl = curl_init();
    curl_setopt_array(
      $curl,
      array(
        CURLOPT_URL => $template_get_url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_ENCODING => '',
        CURLOPT_MAXREDIRS => 10,
        CURLOPT_TIMEOUT => 0,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS => '{
"language" : "' . $language_code . '",
"code" : "' . $code . '",
"category" : "' . $categories . '",
"components" : ' . $whtsap_send . ',
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
}',
        CURLOPT_HTTPHEADER => array(
          $bearer_token,
          'Content-Type: application/json'

        ),
      )
    );

    $log_4 = '{
"language" : "' . $language_code . '",
 "code" : "' . $code . '",
"category" : "' . $categories . '",
"components" : ' . $whtsap_send . ',
"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
}'; // Send the data into API and execute 
    site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the log ($log_4) on " . date("Y-m-d H:i:s"), '../');
    $response = curl_exec($curl);
    curl_close($curl);
    site_log_generate("Create Template Page : " . $_SESSION['yjwatsp_user_name'] . " executed the response ($response) on " . date("Y-m-d H:i:s"), '../');
    // After got response decode the JSON result
    $obj = json_decode($response);
    if ($obj->response_status == 200) { //success
      $json = array("status" => 1, "msg" => $obj->response_msg);
    } else {
      $json = array("status" => 0, "msg" => $obj->response_msg);
    }
  }

}
// Create Template create_template - End

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
