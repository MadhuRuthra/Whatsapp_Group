<?php
session_start(); // start session
error_reporting(0); // The error reporting function

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
    if ($response == '') { ?>
		<script>
			window.location = "index"
		</script>
	<? }else if ($state1->response_code == 1) {
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

// Compose SMS Page Compose Message - End
if ($_SERVER['REQUEST_METHOD'] == "GET" and $tmpl_call_function == "compose_whatsapp") {
    site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " Compose Whatsapp failed [GET NOT ALLOWED] on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => "Get Method not allowed here!");
}

if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "compose_whatsapp") {
    site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');

    $rdo_media = htmlspecialchars(strip_tags(isset($_REQUEST['rdo_media']) ? $conn->real_escape_string($_REQUEST['rdo_media']) : ""));
    $message = htmlspecialchars(strip_tags(isset($_REQUEST['textarea']) ? $conn->real_escape_string($_REQUEST['textarea']) : ""));
    $sender_mobile_nos = htmlspecialchars(strip_tags(isset($_REQUEST['slt_whatsapp_sender']) ? $conn->real_escape_string($_REQUEST['slt_whatsapp_sender']) : ""));
    $Whatsapp_group = htmlspecialchars(strip_tags(isset($_REQUEST['groups']) ? $conn->real_escape_string($_REQUEST['groups']) : ""));

    if (isset($_FILES['upload_image']['name']) && !empty($_FILES['upload_image']['name'])) {
        $image_size = $_FILES['upload_image']['size'];
        $image_type = $_FILES['upload_image']['type'];
        $file_type = explode("/", $image_type);
        $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];

        /* Location */
        $location = $full_pathurl . "uploads/whatsapp_images/" . $filename;
        $img_location = $site_url . "uploads/whatsapp_images/" . $filename;

        $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
        $imageFileType = strtolower($imageFileType);
        $rspns = '';
        /* Check file extension */
        if (strtolower($imageFileType)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['upload_image']['tmp_name'], $location)) {
                $rspns = $location;
                site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_videos file moved into Folder on " . date("Y-m-d H:i:s"), '../');
            }
        }
    }

    if (isset($_FILES['upload_video']['name']) && !empty($_FILES['upload_video']['name'])) {
        $image_size = $_FILES['upload_video']['size'];
        $image_type = $_FILES['upload_video']['type'];
        $file_type = explode("/", $image_type);
        $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];
        /* Location */
        $location = $full_pathurl . "uploads/whatsapp_videos/" . $filename;
        $video_location = $site_url . "uploads/whatsapp_videos/" . $filename;

        $imageFileType = pathinfo($location, PATHINFO_EXTENSION);
        $imageFileType = strtolower($imageFileType);

        /* Valid extensions */
        $valid_extensions = array("mp4");

        $rspns = '';
        /* Check file extension */
        if (strtolower($imageFileType)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['upload_video']['tmp_name'], $location)) {
                $rspns = $location;
                site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_videos file moved into Folder on " . date("Y-m-d H:i:s"), '../');
            }
        }
    }

        $sendto_api .= '{
            "user_id":"' . $_SESSION['yjwatsp_user_id'] . '",
             "sender_numbers": "' . $sender_mobile_nos . '",
             "message": "' . $message . '",
             "group_name" : "' . $Whatsapp_group . '",';

     
        if ($video_location) {

            $sendto_api .= '"video_url" : "' . $video_location . '",';
        }
        if ($img_location) {
            $sendto_api .= '"image_url" : "' . $img_location . '",';
        }

        $sendto_api .= '"request_id" : "' . $_SESSION["yjwatsp_user_short_name"] . "_" . $year . $julian_dates . $hour_minutes_seconds . "_" . $random_generate_three . '"
           }';

        site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " api send text [$sendto_api] on " . date("Y-m-d H:i:s"), '../');
        // add bearer token
        $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
        // print_r($sendto_api);
        // exit();

        // It will call "compose_whatsapp_message" API to verify, can we access for thecompose_whatsapp_message
        $curl = curl_init();
        curl_setopt_array(
            $curl,
            array(
                CURLOPT_URL => $api_url . '/group/send_message',
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
    if ($respobj == '') {
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

    $message_content = isset($_REQUEST['textarea_new']) ? $_REQUEST['textarea_new'] : "";

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

    // Regular expression pattern to match <a> tags
    $pattern = '/<a\s+(?:[^"\'>]+|"[^"]*"|\'[^\']*\')*>((?:.|\s)*?)<\/a>/';
    // Replace <a> tags with formatted URLs
    $message_content = preg_replace_callback($pattern, function ($matches) {
        // Extract URL and anchor text from matched <a> tag
        preg_match('/href=\\"([^\\"]+)\\"/', $matches[0], $url_match);
        $url = $url_match[1];
        $anchor_text = $matches[1];
        // Check if URL starts with "http://" or "https://", if not add "http://"
        if (!preg_match("~^(?:f|ht)tps?://~i", $url)) {
            $code .= "0u00000";
            $url = "http://" . $url;
        }
        // Format the URL and anchor text
        return "$anchor_text : $url";
    }, $message_content);

    if (strlen($code) != 9) {
        $code .= "00000000";
    }

    $message_content = str_replace("'", "\'", $message_content);
    $message_content = str_replace('"', '\"', $message_content);
    $message_content = str_replace("\\r\\n", '\n', $message_content);
    $message_content = str_replace('&amp;', '&', $message_content);
    $message_content = str_replace(PHP_EOL, '\n', $message_content);
    $message_content = str_replace('\\&quot;', '"', $message_content);
    $message_content = str_replace('"', '\"', $message_content);
    // $message_content = str_replace('<br>', '\n', $message_content);
    $message_content = preg_replace('#<(/)?p>#', '', $message_content);
    $message_content = preg_replace('#<(/)?b>#', '*', $message_content);
    $message_content = preg_replace('/<span[^>]*>(.*?)<\/span>/', '*$1*', $message_content);


    $user_id = $_SESSION['yjwatsp_user_id'];

    // define the value
    $whtsap_send = '';

    if ($message_content) { // Only Textarea

        $whtsap_send .= '[ { 
                          "type": "BODY",
                          "text": "' . $message_content . '"
                        }]';
    }


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
// Create Template create_template - End

// Compose SMS Page getSingleTemplate_meta - Start
if (isset($_GET['getSingleTemplate_meta']) == "getSingleTemplate_meta") {

    // GET DATAS
    $tmpl_name = explode('!', $tmpl_name);
    $load_templates = '{
                                   "template_name" : "' . $tmpl_name[0] . '"
                            }';

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
    $yjresponseobj = json_decode($response); // Assuming $response contains the JSON string
    if ($response == '') { ?>
		<script>
			window.location = "index"
		</script>
	<? } else if ($yjresponseobj->response_status == 403) { ?>
			<script>
				window.location = "index"
			</script>
	<? }else if ($yjresponseobj->get_single_template) {
        foreach ($yjresponseobj->get_single_template as $template) {
            $template_message = $template->template_message;
            $template_message_array = json_decode($template_message);

            // Output the template message
            foreach ($template_message_array as $message_part) {
                // Check if the message part is of type "BODY"
                if ($message_part->type === "BODY") {
                    // Output the body text
                    $stateData = $message_part->text;
                }
            }
        }
        site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Meta Message Template available on " . date("Y-m-d H:i:s"), '../');
        $json = array("status" => 1, "msg" => $stateData);

    } else {

        site_log_generate("Compose Whatsapp Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Message Template not available on " . date("Y-m-d H:i:s"), '../');
        $json = array("status" => 0, "msg" => '-');

    }
}
// Compose SMS Page getSingleTemplate_meta - End

// Finally Close all Opened Mysql DB Connection
$conn->close();
// Output header with JSON Response
header('Content-type: application/json');
echo json_encode($json);
