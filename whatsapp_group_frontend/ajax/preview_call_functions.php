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

    if (isset($_FILES['upload_image']['name']) && !empty($_FILES['upload_image']['name'])) {
        $image_size = $_FILES['upload_image']['size'];
        $image_type = $_FILES['upload_image']['type'];
        $file_type = explode("/", $image_type);
        $filename = $_SESSION['yjwatsp_user_id'] . "_" . $milliseconds . "." . $file_type[1];

        /* Location */
        $location_1 = $full_pathurl . "uploads/whatsapp_images/" . $filename;
        $img_location = $site_url . "uploads/whatsapp_images/" . $filename;

        $imageFileType = pathinfo($location_1, PATHINFO_EXTENSION);
        $imageFileType = strtolower($imageFileType);
        $rspns = '';
        /* Check file extension */
        if (strtolower($imageFileType)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['upload_image']['tmp_name'], $location_1)) {
                $rspns = $location_1;
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
        $location_2 = $full_pathurl . "uploads/whatsapp_videos/" . $filename;
        $video_location = $site_url . "uploads/whatsapp_videos/" . $filename;

        $imageFileType = pathinfo($location_2, PATHINFO_EXTENSION);
        $imageFileType = strtolower($imageFileType);

        /* Valid extensions */
        $valid_extensions = array("mp4");

        $rspns = '';
        /* Check file extension */
        if (strtolower($imageFileType)) {
            /* Upload file */
            if (move_uploaded_file($_FILES['upload_video']['tmp_name'], $location_2)) {
                $rspns = $location_2;
                site_log_generate("Create Template Page : User : " . $_SESSION['yjwatsp_user_name'] . " whatsapp_videos file moved into Folder on " . date("Y-m-d H:i:s"), '../');
            }

        }
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
}
//Create Template Preview Page - END  


// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with HTML Response
header('Content-type: text/html');
echo $result_value;
