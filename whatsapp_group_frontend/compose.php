<?php
/*
Authendicated users only allow to view this Compose Whatsapp page.
This page is used to Compose Whatsapp messages.
It will send the form to API service and send it to the Whatsapp Facebook
and get the response from them and store into our DB.

Version : 1.0
Author : Madhubala (YJ0009)
Date : 05-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once('api/configuration.php'); // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Compose Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Compose Whatsapp ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/custom.css">
  <link rel="stylesheet" href="assets/css/components.css">

  <!-- style include in css -->
  <style>
    textarea {
      resize: none;
    }

    .btn-warning,
    .btn-warning.disabled {
      width: 100% !important;
    }

    .theme-loader {
      display: block;
      position: absolute;
      top: 0;
      left: 0;
      z-index: 100;
      width: 100%;
      height: 100%;
      background-color: rgba(192, 192, 192, 0.5);
      background-image: url("assets/img/loader.gif");
      background-repeat: no-repeat;
      background-position: center;
    }
  </style>
</head>

<body>
  <div class="theme-loader"></div>
  <div id="app">
    <div class="main-wrapper main-wrapper-1">
      <div class="navbar-bg"></div>

      <!-- include header function adding -->
      <? include("libraries/site_header.php"); ?>

      <!-- include sitemenu function adding -->
      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <!-- Title and Breadcrumbs -->
          <div class="section-header">
            <h1>Compose Whatsapp</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="template_whatsapp_list">Whatsapp List</a></div>
              <div class="breadcrumb-item">Compose Whatsapp</div>
            </div>
          </div>

          <!-- Title and Breadcrumb -->
          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-12 col-lg-12">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_compose_whatsapp" name="frm_compose_whatsapp"
                    action="#" method="post" enctype="multipart/form-data">
                    <!-- Select Whatsapp Template -->
                    <div class="card-body">
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Select Whatsapp Template <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="slt_whatsapp_template" id='slt_whatsapp_template' class="form-control"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Template" tabindex="1" autofocus
                            onchange="call_getsingletemplate()">
                            <option value="" selected>Choose Whatsapp Template</option>
                            <? // To using the select template 
                            $load_templates = '{
                                "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                          }'; // Add user id
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " Execute the service ($load_templates) on " . date("Y-m-d H:i:s"));

                            $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // Add Bearer Token  
                            $curl = curl_init();
                            curl_setopt_array(
                              $curl,
                              array(
                                CURLOPT_URL => $api_url . '/template/get_template',
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
                            $state1 = json_decode($response, false);
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " get the Service response ($response) on " . date("Y-m-d H:i:s"));
                            // After got response decode the JSON result
                            if ($state1->response_code == 1) {
                              // Looping the indicator is less than the count of templates.if the condition is true to continue the process and to get the details.if the condition are false to stop the process
                              for ($indicator = 0; $indicator < count($state1->templates); $indicator++) { // Set the response details into Option ?>
                                <option
                                  value="<?= $state1->templates[$indicator]->template_name ?>!<?= $state1->templates[$indicator]->language_code ?>!<?= $state1->templates[$indicator]->template_master_id ?>">
                                  <?= $state1->templates[$indicator]->template_name ?>
                                  [
                                  <?= $state1->templates[$indicator]->language_code ?>]
                                </option>
                              <? }
                            }
                            ?>
                            </table>
                          </select>

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <!-- Choose Group -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label"> Select Whatsapp Group <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="slt_whatsapp_group" id='slt_whatsapp_group' class="form-control"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Template" tabindex="1" autofocus required=""
                            onchange="func_template_senderid()" onfocus="func_template_senderid()">
                            <option value="" selected>Choose Group</option>
                            <? // To using the select template 
                            $load_templates = '{
                                "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
                          }'; // Add user id
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " Execute the service ($load_templates) on " . date("Y-m-d H:i:s"));

                            $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // Add Bearer Token  
                            $curl = curl_init();
                            curl_setopt_array(
                              $curl,
                              array(
                                CURLOPT_URL => $api_url . '/list/group_list',
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
                            $state1 = json_decode($response, false);
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " get the Service response ($response) on " . date("Y-m-d H:i:s"));
                            // After got response decode the JSON result
                            if ($state1->response_code == 1) {
                              // Looping the indicator is less than the count of templates.if the condition is true to continue the process and to get the details.if the condition are false to stop the process
                              for ($indicator = 0; $indicator < count($state1->group_list); $indicator++) { // Set the response details into Option ?>
                                <option
                                  value="<?= $state1->group_list[$indicator]->group_name ?>!<?= $state1->group_list[$indicator]->total_count ?>!<?= $state1->group_list[$indicator]->group_master_id ?>">
                                  <?= $state1->group_list[$indicator]->group_name ?>
                                  [
                                  <?= $state1->group_list[$indicator]->total_count ?>]
                                </option>
                              <? }
                            }
                            ?>
                            </table>
                          </select>

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- Whatsapp Sender ID -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Whatsapp Sender ID <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Avl. Credits - Available Credits">[?]</span></label>
                        <div class="col-sm-7">
                          <div id='id_own_senderid'>
                          </div>

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- Scheduled sms -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Schedule SMS <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Campaign Name allowed maximum 30 Characters. Unique values only allowed">[?]</span></label>
                        <div class="col-sm-2">
                          <label>
                            <input type="radio" name="schedule_date_code" id="schedule_date_code" checked="checked"
                              value='NOW' tabindex="16" onclick="call_schedule_date(1)">
                            <i class="helper"></i> Send Now
                          </label>
                          <label>
                            <input type="radio" name="schedule_date_code" id="schedule_date_code" value='LATER'
                              tabindex="17" onclick="call_schedule_date(2)">
                            <i class="helper"></i> Send Later
                          </label>

                        </div>
                        <div class="col-sm-3" id="id_txt_schedule_date" style="display: none;">
                          <input type='datetime-local' name="txt_schedule_date" style="margin-right:30px;"
                            id="txt_schedule_date" class="form-control" value="<?= date("Y-m-d H:i:s") ?>" step="1">
                        </div>
                        <div class="col-sm-4"></div>
                      </div>
                      <!-- To upload check the Image -->
                      <div class="form-group mb-3 row">
                        <label class="col-sm-3 col-form-label" style="float: left">Upload Image <span
                            data-toggle="tooltip"
                            data-original-title="Upload image below or equal to 5 MB Size file.Upload Only the JPG, PNG,JPEG file">[?]</span></label>
                        <div class="col-sm-7" style="float: left">
                          <input type="file" class="form-control mb-1" name="upload_image" id="upload_image"
                            tabindex="4" accept="image/jpeg,image/jpg,image/png" data-toggle="tooltip"
                            onchange="validate_imagesize(this)" data-placement="top" data-html="true"
                            title="Upload image below or equal to 5 MB Size file.Upload Only the JPG, PNG,JPEG file">

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- To upload check the videos -->

                      <div class="form-group mb-3 row">
                        <label class="col-sm-3 col-form-label" style="float: left">Upload Video <span
                            data-toggle="tooltip"
                            data-original-title="Upload video below or equal to 5 MB Size - Upload Only the Video MP4 ,webm,m4v,mpeg,mpeg4,h263 file - Video duration below 30 seconds">[?]</span></label>
                        <div class="col-sm-7" style="float: left">
                          <input type="file" class="form-control mb-1" name="upload_video" id="upload_video"
                            tabindex="4" accept="video/h263,video/m4v,video/mp4,video/mpeg,video/mpeg4,video/webm"
                            data-toggle="tooltip" onchange="validate_video_size(this)" data-placement="top"
                            data-html="true" title=""
                            data-original-title="Upload video below or equal to 5 MB Size - Upload Only the Video MP4 ,webm,m4v,mpeg,mpeg4,h263 file - Video duration below 30 seconds ">
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <!-- To upload the Customized Template -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">&nbsp;</label>
                        <div class="col-sm-7">
                          <div style="clear: both; word-wrap: break-word; word-break: break-word;"
                            id="slt_whatsapp_template_single"></div>
                          <input type="hidden" id="txt_sms_content" name="txt_sms_content">

                          <div id="id_show_variable_csv" style="clear: both; display: none">
                            <label class="error_display"><b>Customized Template</b></label>
                            <input type="file" class="form-control" name="fle_variable_csv" id='fle_variable_csv'
                              accept="text/csv" data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Upload the Mobile Numbers via CSV Files" tabindex="8">
                            <input type="hidden" id="txt_variable_count" name="txt_variable_count" value="0">
                            <label class="j-label mt-1"><a href="uploads/imports/sample_variables.csv" download
                                class="btn btn-info alert-ajax btn-outline-info"><i class="fas fa-download"></i>
                                Download Sample CSV File</a></label>
                          </div>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- if the url button is select to visible the url Button -->
                      <div class="form-group mb-2 row" id="id_open_url" style="display: none;">
                        <div class="form-group mb-2 row">
                          <label class="col-sm-3 col-form-label">URL Button</label>
                          <div class="col-sm-7">
                            <table class="table table-striped table-bordered m-0"
                              style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
                              <tbody>
                                <tr>
                                  <td class="col-md-6" style="width: 50%;">
                                    <input class="form-control" type="url" name="txt_open_url" tabindex="8"
                                      id="txt_open_url" maxlength="100" placeholder="URL [https://www.google.com]"
                                      onchange="return validate_url('txt_open_url')">
                                  </td>
                                  <td class="col-md-6" style="width: 50%;">
                                    <input class="form-control" type="text" name="txt_open_url_data" tabindex="8"
                                      id="txt_open_url_data" maxlength="25" placeholder="Button Name"
                                      title="Button Name">
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div>
                          <div class="col-sm-2">
                          </div>
                        </div>
                        <!-- if the url button is select to visible the call Button -->
                        <div class="form-group mb-2 row">
                          <label class="col-sm-3 col-form-label">Call Button</label>
                          <div class="col-sm-7">
                            <table class="table table-striped table-bordered m-0"
                              style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
                              <tbody>
                                <tr>
                                  <td class="col-md-6" style="width: 40%;">
                                    <input class="form-control" type="text" name="txt_call_button" tabindex="9"
                                      id="txt_call_button" maxlength="10"
                                      onkeypress="return (event.charCode !=8 && event.charCode ==0 || ( event.charCode == 46 || (event.charCode >= 48 && event.charCode <= 57)))"
                                      placeholder="Mobile Number" title="Mobile Number">
                                  </td>
                                  <td class="col-md-6" style="width: 40%;">
                                    <input class="form-control" type="text" name="txt_call_button_data" tabindex="9"
                                      id="txt_call_button_data" maxlength="50" placeholder="Button Name"
                                      title="Button Name">
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div>
                          <div class="col-sm-2">
                          </div>
                        </div>
                      </div>
                      <!-- if the url button is select to visible the Reply Buttons-->
                      <div class="form-group mb-2 row" id="id_reply_button" style="display: none;">
                        <label class="col-sm-3 col-form-label">Reply Buttons <br>(Maximum 3 Allowed)</label>
                        <div class="col-sm-7">
                          <table class="table table-striped table-bordered m-0"
                            style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
                            <tbody>
                              <tr>
                                <td class="col-md-5" style="width: 40%;">
                                  <input class="form-control" type="text" tabindex="10" name="txt_reply_buttons[]"
                                    id="txt_reply_buttons_1" maxlength="25" placeholder="Reply" title="Reply">
                                </td>
                                <td class="col-md-5" style="width: 40%;">
                                  <input class="form-control" type="text" tabindex="10" name="txt_reply_buttons_data[]"
                                    id="txt_reply_buttons_data_1" maxlength="25" placeholder="Reply Button"
                                    title="Reply Button">
                                </td>
                                <td class="col-md-2" style="width: 20%; padding: 5px !important;">
                                  <input type="button" class="btn btn-success" value="+ Add Reply"
                                    onclick="add_column('text_suggested_replies')">
                                  <input type="hidden" name="hidcnt_text_suggested_replies"
                                    id="hidcnt_text_suggested_replies" value="1">
                                </td>
                              </tr>

                              <tr>
                                <td colspan="3" style="padding: 0px;">
                                  <table id="id_text_suggested_replies" style="width: 100% !important;">
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- Product List  -->
                      <div class="form-group mb-2 row" id="id_option_list" style="display: none;">
                        <label class="col-sm-3 col-form-label">Product List <br>(Maximum 4 Allowed)</label>
                        <div class="col-sm-7">
                          <table class="table table-striped table-bordered m-0"
                            style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
                            <tbody>
                              <tr>
                                <td class="col-md-8" style="width: 80%;">
                                  <input class="form-control" type="text" tabindex="10" name="txt_option_list[]"
                                    id="txt_option_list_1" maxlength="25" placeholder="Product" title="Product">
                                </td>
                              </tr>
                              <tr>
                                <td class="col-md-8" style="width: 80%;">
                                  <input class="form-control" type="text" tabindex="10" name="txt_option_list[]"
                                    id="txt_option_list_2" maxlength="25" placeholder="Product" title="Product">
                                </td>
                                <td class="col-md-3" style="width: 20%;">
                                  <input type="button" class="btn btn-success" value="+ Add Products"
                                    onclick="add_column('option_list')">
                                  <input type="hidden" name="hidcnt_text_option_list" id="hidcnt_text_option_list"
                                    value="1">
                                </td>
                              </tr>

                              <tr>
                                <td colspan="3" style="padding: 0px;">
                                  <table id="id_text_option_list" style="width: 100% !important;">
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                    </div>

                    <!-- submit button and error display -->
                    <div class="error_display" id='id_error_display'></div>
                    <div class="card-footer text-center">
                      <input type="hidden" name="txt_sms_count" id="txt_sms_count" value="<?= $sms_ttl_chars ?>">
                      <input type="hidden" name="txt_char_count" id="txt_char_count" value="<?= $cnt_ttl_chars ?>">
                      <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                        value='compose_whatsapp' />
                      <a href="#!" onclick="preview_compose_template()" name="preview_submit" id="preview_submit"
                        tabindex="11" value="" class="btn btn-info">Preview</a>
                      <input type="submit" name="compose_submit" id="compose_submit" tabindex="12" value="Submit"
                        class="btn btn-success">
                      <a href="compose" name="cancel_submit" id="cancel_submit" tabindex="13" value=""
                        class="btn btn-danger">Cancel</a>
                    </div>

                  </form>
                </div>
              </div>
            </div>
          </div>
        </section>

      </div>
      <!-- include site footer -->
      <? include("libraries/site_footer.php"); ?>

    </div>
  </div>

  <!-- Modal content-->
  <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" style=" max-width: 75% !important;">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Preview Template</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" id="id_modal_display" style=" word-wrap: break-word; word-break: break-word;">
          <h5>Welcome</h5>
          <p>Waiting for load Data..</p>
        </div>
      </div>
    </div>
  </div>

  <!-- General JS Scripts -->
  <script src="assets/modules/jquery.min.js"></script>
  <script src="assets/modules/popper.js"></script>
  <script src="assets/modules/tooltip.js"></script>
  <script src="assets/modules/bootstrap/js/bootstrap.min.js"></script>
  <script src="assets/modules/nicescroll/jquery.nicescroll.min.js"></script>
  <script src="assets/modules/moment.min.js"></script>
  <script src="assets/js/stisla.js"></script>
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>
  <script src="assets/js/xlsx.core.min.js"></script>
  <script src="assets/js/xls.core.min.js"></script>

  <script>
    // start function document
    $(function () {
      $('.theme-loader').fadeOut("slow");
    });
    document.body.addEventListener("click", function (evt) {
      //note evt.target can be a nested element, not the body element, resulting in misfires
      $("#id_error_display").html("");
      $("#file_document_header").prop('disabled', false);
      $("#file_document_header_url").prop('disabled', false);
    });

    // FORM preview value
    function preview_compose_template() {
      var txt_campaign_name = $('#txt_campaign_name').val();

      var form = $("#frm_compose_whatsapp")[0]; // Get the HTMLFormElement from the jQuery selector
      var fd = new FormData(form); // Use the form element in the FormData constructor
      var slt_whatsapp_template_single = $('#slt_whatsapp_template_single').html();
      fd.append('slt_whatsapp_template_single', slt_whatsapp_template_single);

      $.ajax({
        type: 'post',
        url: "ajax/preview_call_functions.php?preview_functions=preview_compose",
        data: fd,
        processData: false, // Important: Prevent jQuery from processing the data
        contentType: false, // Important: Let the browser set the content type
        success: function (response) { // Success
          $("#id_modal_display").html(response);
          console.log(response.status);
          $('#default-Modal').modal({ show: true }); // Open in a Modal Popup window
        },
        error: function (response, status, error) { // Error
          console.log("error");
          $("#id_modal_display").html(response.status);
          $('#default-Modal').modal({ show: true });
        }
      });
    }

    // func_template_senderid func
    function func_template_senderid(admin_user) {
      var slt_whatsapp_group = $("#slt_whatsapp_group").val();
      var send_code = "&slt_whatsapp_group=" + slt_whatsapp_group;
      $('#txt_variable_count').val(0);
      $("#fle_variable_csv").attr("required", false);
      $('#id_show_variable_csv').css('display', 'none');
      $('#txt_list_mobno').attr('readonly', false);
      $("#id_mobupload").css('display', 'block');
      $("#id_mobupload_sub").css('display', 'none');
      console.log("!!!FALSE");

      $.ajax({
        type: 'post',
        url: "ajax/call_functions.php?tmpl_call_function=group_sender_ids" + send_code,
        dataType: 'json',
        beforeSend: function () {
          $('.theme-loader').show();
        },
        complete: function () {
          $('.theme-loader').hide();
        },
        success: function (response) {
          $('#id_own_senderid').html(response.msg);
          $('.theme-loader').hide();
        },
        error: function (response, status, error) { }
      });
    }


    // func_validate_campaign_name funct
    function func_validate_campaign_name() {
      var txt_campaign_name = $("#txt_campaign_name").val();
      $("#id_error_display").html('');
      $('#txt_campaign_name').css('border-color', '#e4e6fc');

      if (txt_campaign_name != '') {
        var send_code = "&txt_campaign_name=" + txt_campaign_name;
        $.ajax({
          type: 'post',
          url: "ajax/call_functions.php?tmpl_call_function=validate_campaign_name" + send_code,
          dataType: 'json',
          beforeSend: function () {
            $('.theme-loader').show();
          },
          complete: function () {
            $('.theme-loader').hide();
          },
          success: function (response) {
            if (response.status == 0) {
              $('#txt_campaign_name').val('');
              $('#txt_campaign_name').focus();
              $("#txt_campaign_name").attr('data-original-title', response.msg);
              $("#txt_campaign_name").attr('title', response.msg);
              $('#txt_campaign_name').css('border-color', 'red');
              $('#id_error_display').html(response.msg);
            } else {

            }
            $('.theme-loader').hide();
          },
          error: function (response, status, error) { }
        });
      }
    }


    function preview_open_url() {
      $("#txt_open_url").prop('required', true);
      $("#txt_open_url_data").prop('required', true);
      $("#txt_call_button").prop('required', true);
      $("#txt_call_button_data").prop('required', true);
      $('#id_open_url').toggle("display", "block");
    }
    function preview_call_button() {
      $("#txt_call_button").prop('required', true);
      $("#txt_call_button_data").prop('required', true);
      $('#id_call_button').toggle("display", "block");
    }
    function preview_reply_button() {
      $("#txt_reply_buttons_1").prop('required', true);
      $("#txt_reply_buttons_data_1").prop('required', true);
      $('#id_reply_button').toggle("display", "block");
    }
    function preview_option_list() {
      $("#txt_option_list_1").prop('required', true);
      $("#txt_option_list_2").prop('required', true);
      $('#id_option_list').toggle("display", "block");
    }

    function validate_url(url_site) {
      $('#compose_submit').prop('disabled', false);
      $("#id_error_display").html("");
      var url = $("#" + url_site).val();
      var pattern = /(http|https):\/\/(\w+:{0,1}\w*)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%!\-\/]))?/;
      if (!pattern.test(url)) {
        $("#id_error_display").html("Invalid URL");
        $('#compose_submit').prop('disabled', true);
        return false;
      } else {
        $('#compose_submit').prop('disabled', false);
        return true;
      }
    }

    // call_getsingletemplate funtc
    function call_getsingletemplate() {
      $("#slt_whatsapp_template_single").html("");
      var tmpl_name = $("#slt_whatsapp_template").val();
      $.ajax({
        type: 'post',
        url: "ajax/whatsapp_call_functions.php?getSingleTemplate_meta=getSingleTemplate_meta&tmpl_name=" + tmpl_name,
        beforeSend: function () {
          $("#id_error_display").html("");
          $('.theme-loader').show();
        },
        complete: function () {
          $("#id_error_display").html("");
          $('.theme-loader').hide();
        },
        success: function (response_msg) {
          $('#slt_whatsapp_template_single').html(response_msg.msg);
          // $("#txt_sms_content").val(response_msg.msg);
          $('.theme-loader').hide();
          $("#id_error_display").html("");
        },
        error: function (response_msg, status, error) {
          $("#slt_whatsapp_template_single").html(response_msg.msg);
          $('.theme-loader').hide();
          $("#id_error_display").html("");
        }
      });
    }

    // function call_composesms() {
    $(document).on("submit", "form#frm_compose_whatsapp", function (e) {
      e.preventDefault();
      $("#id_error_display").html("");
      $('#txt_list_mobno').css('border-color', '#a0a0a0');
      $('#chk_remove_duplicates').css('border-color', '#a0a0a0');
      $('#chk_remove_invalids').css('border-color', '#a0a0a0');
      $('#txt_sms_content').css('border-color', '#a0a0a0');
      $('#txt_char_count').css('border-color', '#a0a0a0');
      $('#txt_sms_count').css('border-color', '#a0a0a0');

      //get input field values 
      var txt_campaign_name = $('#txt_campaign_name').val();
      var txt_list_mobno = $('#txt_list_mobno').val();
      var chk_remove_duplicates = $('#chk_remove_duplicates').val();
      var chk_remove_invalids = $('#chk_remove_invalids').val();

      var upload_image = $('#upload_image').val();
      var upload_video = $('#upload_video').val();

      var flag = true;
      var len = $('.cls_checkbox:checked').length;

      if (len <= 0) {
        $("#id_error_display").html("Please check at least one Whatsapp Sender ID");
        $('#txt_whatsapp_mobno').focus();
        flag = false;
      }

      /********validate all our form fields***********/

      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        var fd = new FormData(this);
        $.ajax({
          type: 'post',
          url: "ajax/whatsapp_call_functions.php",
          dataType: 'json',
          data: fd,
          contentType: false,
          processData: false,
          beforeSend: function () {
            $('#compose_submit').attr('disabled', true);
            $('.theme-loader').show();
          },
          complete: function () {
            $('#compose_submit').attr('disabled', false);
            $('.theme-loader').hide();
            e.preventDefault();

          },
          success: function (response) {
            console.log("SUCC");
            if (response.status == '0') {
              $('#id_slt_header').val('');
              $('#id_slt_template').val('');
              e.preventDefault();
              $('#txt_list_mobno').val('');
              $('#chk_remove_duplicates').val('');
              $('#chk_remove_invalids').val('');
              $('#txt_sms_content').val('');
              $('#txt_char_count').val('');
              $('#txt_sms_count').val('');
              $('#id_submit_composercs').attr('disabled', false);
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response.msg);
            } else if (response.status == 2) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response.msg);
            } else if (response.status == 1) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response.msg);
              setInterval(function () {
                window.location = 'compose_whatsapp_list';
              }, 2000);
            }
            $('.theme-loader').hide();
          },
          error: function (response, status, error) {
            console.log("FAL");
            $('#id_slt_header').val('');
            $('#id_slt_template').val('');
            $('#txt_list_mobno').val('');
            $('#chk_remove_duplicates').val('');
            $('#chk_remove_invalids').val('');
            $('#txt_sms_content').val('');
            $('#txt_char_count').val('');
            $('#txt_sms_count').val('');
            $('#id_submit_composercs').attr('disabled', false);
            $('#compose_submit').attr('disabled', false);
            $('.theme-loader').show();
            $("#id_error_display").html(response.msg);
          }
        });
      }
    });

    function call_schedule_date(status_display) {
      if (status_display == "1")
        $("#id_txt_schedule_date").css("display", "none");
      else
        $("#id_txt_schedule_date").css("display", "block");
    }

    // Schedule Calender date disabled 
    const now = new Date();
    // Format the current date and time as required by the datetime-local input
    const currentDateTime = now.toISOString().slice(0, 16);
    // Set the minimum value of the datetime-local input to the current date and time
    document.getElementById('txt_schedule_date').setAttribute('min', currentDateTime);


    function validate_imagesize(fileInput) {
      $("#id_error_display").html(""); // Clear any previous error messages
      var file = fileInput.files[0]; // Access the files property of the file input element

      // Check if a file is selected
      if (!file) {
        console.error("No file selected.");
        return;
      }

      var file_size = file.size;
      var file_name_parts = file.name.split('.');
      var file_extension = file_name_parts[file_name_parts.length - 1].toLowerCase();

      // Allowed file extensions
      var allowed_extensions = ["jpg", "jpeg", "png"];

      // Check if the file extension is in the allowed list
      if (!allowed_extensions.includes(file_extension)) {
        $("#id_error_display").html("Invalid file type. Only JPG, JPEG, and PNG files are allowed.");
        return;
      }

      if (file_size > 5242880) { // 5 MB in bytes
        $("#id_error_display").html("Image file size must be below 5 MB. Kindly try again!");
        return;
      }

      // Additional validation and processing here...
    }


    function validate_video_size(file_name) {
      $("#id_error_display").html(""); // Clear any previous error message
      var file = file_name.files[0];
      var file_size = file.size;
      var file_name_parts = file.name.split('.');
      var file_extension = file_name_parts[file_name_parts.length - 1].toLowerCase(); // Get the file extension
      // Allowed file extensions
      var allowed_extensions = ["mp4", "webm", "m4v", "mpeg", "mpeg4", "h263"];
      // Check if the file extension is in the allowed list
      if (!allowed_extensions.includes(file_extension)) {
        $("#id_error_display").html("Invalid file type. Only MP4, WEBM, M4V, MPEG, MPEG4, H263 files are allowed.");
        file_name.value = ''; // Clear the file input
        return;
      }
      // Create a temporary video element
      var video = document.createElement('video');
      video.preload = 'metadata';
      video.onloadedmetadata = function () {
        // Check video duration
        if (video.duration > 30) {
          $("#id_error_display").html("Video duration must be below 30 seconds. Please select a shorter video.");
          file_name.value = ''; // Clear the file input
          return;
        }
        // Check if the file size exceeds 5 MB
        if (file_size > 5242880) { // 5 MB in bytes
          $("#id_error_display").html("Media file size must be below 5 MB. Kindly try again!");
          console.log("Failed");
          file_name.value = ''; // Clear the file input
          return;
        }
        // Clean up
        URL.revokeObjectURL(video.src);
      };
      // Set video source to the selected file
      video.src = URL.createObjectURL(file);
    }

  </script>
</body>

</html>
