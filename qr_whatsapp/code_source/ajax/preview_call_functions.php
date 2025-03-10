<?php
/*
This page has some functions which is access from Frontend.
This page is act as a Backend page which is connect with Node JS API and PHP Frontend.
It will collect the form details and send it to API.
After get the response from API, send it back to Frontend.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 01-Jul-2023
*/
session_start(); //start session
error_reporting(0); // The error reporting function
include_once('../api/configuration.php'); // Include configuration.php
include_once('site_common_functions.php');
extract($_REQUEST); // Extract the request
$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // To get bearertoken
$current_date = date("Y-m-d H:i:s"); // To get currentdate function
$milliseconds = round(microtime(true) * 1000);

// Create Template Preview Page - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $preview_functions == "preview_template") {

    // $textarea_txt = htmlspecialchars(strip_tags(isset($_REQUEST['textarea_new']) ? $conn->real_escape_string($_REQUEST['textarea_new']) : ""));

    $textarea_txt = isset($_REQUEST['textarea_new']) ? $_REQUEST['textarea_new'] : "";
    explode("<b>", $textarea_txt);
     
    // To get the one by one data from the array
    foreach ($lang as $lang_id) {
        $langid .= $lang_id . "";
    }
    $language = explode("-", $langid);
    $language_code = $language[0];
    $language_id = $language[1];
    ?>
    <table class="table table-striped table-bordered m-0"
        style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
        <tbody>
            <? if ($language_code != '') { ?>
                <tr>
                    <th scope="row">Language Code</th>
                    <td style="white-space: inherit !important;">
                        <?= $language_code ?>
                    </td>
                </tr>
            <? } ?>
            <? if ($textarea_txt != '') { ?>
                <tr>
                    <th scope="row">Message Content</th>
                    <td style="white-space: inherit !important;">
                        <?= $textarea_txt ?>
                    </td>
                </tr>
            <? } ?>
            <? if ($location_1 != '') { ?>
                <tr>
                    <th scope="row">Upload Media</th>
                    <td style="white-space: inherit !important;"><a href="<?= $location_1 ?>" target='_blank'>Media Link</a>
                    </td>
                </tr>
            <? } ?>
            <? if ($group_contact != '') { ?>
                <tr>
                    <th scope="row">Upload Mobile Numbers</th>
                    <td style="white-space: inherit !important;"><a href="<?= $group_contact ?>" target='_blank'>Download Mobile
                            Numbers</a></td>
                </tr>
            <? } ?>
        </tbody>
    </table>

    <? site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Template available on " . date("Y-m-d H:i:s"), '../');
    site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . $stateData . $hdr_type . date("Y-m-d H:i:s"), '../');

    $json = array("status" => 1, "msg" => $stateData . $hdr_type);
    // otherwise
    site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Template not available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => '-');
}
//Create Template Preview Page - END  


// Compose Page Preview Page - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $preview_functions == "preview_compose") {

    $groups = htmlspecialchars(strip_tags(isset($_REQUEST['groups']) ? $conn->real_escape_string($_REQUEST['groups']) : ""));
    $textarea = htmlspecialchars(strip_tags(isset($_REQUEST['textarea']) ? $conn->real_escape_string($_REQUEST['textarea']) : ""));
    $slt_whatsapp_sender = htmlspecialchars(strip_tags(isset($_REQUEST['slt_whatsapp_sender']) ? $conn->real_escape_string($_REQUEST['slt_whatsapp_sender']) : ""));
    // print_r($_REQUEST);
    // exit();
    // if ($txt_whatsapp_mobno > 0) {
    //     // Sender Mobile Numbers
    //     $sender_mobile_nos = '';
    //     for ($i1 = 0; $i1 < count($txt_whatsapp_mobno); $i1++) {
    //         // Looping the i1 is less than the count of txt_whatsapp_mobno.if the condition is true to continue the process.if the condition are false to stop the process
    //         $ex1 = explode('~~', $txt_whatsapp_mobno[$i1]);
    //         $sender_mobile_nos .= $ex1[2] . ',';
    //     }
    //     $sender_mobile_nos = rtrim($sender_mobile_nos, ",");

    // }

    // Send Whatsapp Message - Start
    // $tmpl_name1 = explode('!', $slt_whatsapp_template);
    // $template_name = $tmpl_name1[0];
    // $template_language = $tmpl_name1[1];

    // $wht_group = explode('!', $slt_whatsapp_group);
    // $Whatsapp_group = $wht_group[0];

    ?>
    <table class="table table-striped table-bordered m-0"
        style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
        <tbody>
            <? if ($slt_whatsapp_sender != '') { ?>
                <tr>
                    <th scope="row">Sender ID</th>
                    <td style="white-space: inherit !important;">
                        <?= $slt_whatsapp_sender ?>
                    </td>
                </tr>
            <? } ?>
            <? if ($groups != '') { ?>
                <tr>
                    <th scope="row">Whatsapp Groups</th>
                    <td style="white-space: inherit !important;">
                        <?= $groups ?>
                    </td>
                </tr>
            <? } ?>
            <? if ($textarea != '') { ?>
                <tr>
                    <th scope="row">Message Content</th>
                    <td style="white-space: inherit !important;">
                        <?= $textarea ?>
                    </td>
                </tr>
            <? } ?>
            
            <? if ($location_1 != '') { ?>
                <tr>
                    <th scope="row">Upload Media</th>
                    <td style="white-space: inherit !important;"><a href="<?= $location_1 ?>" target='_blank'>Media Link</a>
                    </td>
                </tr>
            <? } ?>
            <? if ($group_contact != '') { ?>
                <tr>
                    <th scope="row">Upload Mobile Numbers</th>
                    <td style="white-space: inherit !important;"><a href="<?= $group_contact ?>" target='_blank'>Download Mobile
                            Numbers</a></td>
                </tr>
            <? } ?>
        </tbody>
    </table>

    <? site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Template available on " . date("Y-m-d H:i:s"), '../');
    site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . $stateData . $hdr_type . date("Y-m-d H:i:s"), '../');

    $json = array("status" => 1, "msg" => $stateData . $hdr_type);
    // otherwise
    site_log_generate("Template Create Preview Page : User : " . $_SESSION['yjwatsp_user_name'] . " Get Template not available on " . date("Y-m-d H:i:s"), '../');
    $json = array("status" => 0, "msg" => '-');
}
//Compose Page Preview Page - END  

// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with HTML Response
header('Content-type: text/html');
echo $result_value;
