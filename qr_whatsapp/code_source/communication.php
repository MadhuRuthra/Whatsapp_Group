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
site_log_generate("Communication Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Communication ::
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
            <h1>Communication</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="communication_list">Communication Report</a></div>
              <div class="breadcrumb-item">Communication</div>
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
                        <label class="col-sm-3 col-form-label">Select Whatsapp Sender ID <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="slt_whatsapp_sender" id='slt_whatsapp_sender' class="form-control"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Sender ID" tabindex="1" autofocus
                            onchange="getGroups()"
                            >
                            <option value="" selected>Choose Whatsapp Sender ID</option>
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
                                CURLOPT_URL => $api_url . '/sender_id/get_sender_ids',
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
                            if ($response == '') { ?>
                              <script>
                                window.location = "index"
                              </script>
                            <? } else if ($state1->response_status == 403) { ?>
                                <script>
                                  window.location = "index"
                                </script>
                            <? }
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " get the Service response ($response) on " . date("Y-m-d H:i:s"));
                            // After got response decode the JSON result
                            if ($state1->response_code == 1) {
                              // Looping the indicator is less than the count of templates.if the condition is true to continue the process and to get the details.if the condition are false to stop the process
                              for ($indicator = 0; $indicator < count($state1->sender_id); $indicator++) { // Set the response details into Option 
                                if($state1->sender_id[$indicator]->senderid_master_status == 'Y' && $state1->sender_id[$indicator]->user_id == $_SESSION['yjwatsp_user_id'] ){
                              ?>
                                <option
                                  value="<?= $state1->sender_id[$indicator]->mobile_no ?>">
                                  <?= $state1->sender_id[$indicator]->mobile_no ?>
                                  
                                </option>
                              <? }
                            }
                            }
                            ?>
                            </table>
                          </select>

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label"> Whatsapp Sender ID <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                        <div class="dropdown-container sender_id" name="slt_drop_down" onclick="disableElement1('upload_contact')">
              <div class="dropdown-button dropdown-button_sender noselect">
                <div class="dropdown-label">Select Sender IDs:</div>
                <div class="dropdown-quantity_sender"></div>
              </div>
              <div class="dropdown-list_sender dropdown-list">
                <input type="search" placeholder="Search Sender IDs" class="dropdown-search_sender"><br>
                <label><input id="select-all-states" type="checkbox">Select All</label>
                <ul class="test">
                </ul>
              </div>
            </div> -->

                        <!-- </div>
                        <div class="col-sm-2">
                        </div>
                      </div> -->


                            <!-- Choose Group -->
                            <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label"> Select Whatsapp Group <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                        <div class="dropdown-container group" name="slt_drop_down" id="slt_drop_down"  onclick="disableElement2('upload_contact')">
              <div class="dropdown-button dropdown-button_group noselect" id="drop_down_id">
                <div class="dropdown-label">Select Whatsapp Group:</div>
                <div class="dropdown-quantity_group"></div>
              </div>
              <div class="dropdown-list dropdown-list_group ">
                <input type="search" placeholder="Search whatsapp group" class="dropdown-search_group"><br>
                <label><input id="select-all-groups" type="checkbox">Select All</label>
                <ul class="groups">
                </ul>
              </div>
            </div>

                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <!-- Whatsapp Sender ID -->
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Message <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Message to send">[?]</span></label>
                        <div class="col-sm-7">
                        <textarea id="textarea" class="delete form-control" name="textarea"
                                maxlength="1024" tabindex="11" placeholder="Enter Body Content" rows="6"
                                style="width: 100%; height: 150px !important;" ></textarea>
                              <div class="row" style="right: 0px;">
                                <!-- <div class="col-sm" style="margin-top: 5px;"> <span
                                    id="current_text_value">0</span><span id="maximum">/ 1024</span>
                                </div> -->
                                <!-- <div class="col-sm" style=" margin-top: 5px;">​<a href='#!' name="btn" type="button" id="btn"  tabindex="12"
                                class="btn btn-success"> + Add variable</a></div> -->
                              </div>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <!-- Scheduled sms -->
                 
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Media Type
                          <span data-toggle="tooltip"
                            data-original-title="Choose Image or Video">[?]</span></label>
                        <div class="col-sm-7" style="margin-top:10px;">
                          <input type="radio" name="rdo_media" id="rdo_media_image" tabindex="2" value="I" onclick="func_open_newex_group('I')">Image&nbsp;&nbsp;&nbsp;
                          <input type="radio" name="rdo_media" id="rdo_media_video" tabindex="3" value="V" <? if($_SERVER["QUERY_STRING"] != '') { ?> checked <? } ?>onclick="func_open_newex_group('V')"> Video 
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <!-- To upload check the Image -->
                      <div class="form-group mb-3 row" id="image_id" style="display:none;">
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

                      <div class="form-group mb-3 row" id="video_id" style="display:none;">
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
                      <!-- <div class="form-group mb-2 row">
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
                      </div> -->
                      <!-- if the url button is select to visible the url Button -->
                      <!-- <div class="form-group mb-2 row" id="id_open_url" style="display: none;">
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
                      </div> -->
                      <!-- if the url button is select to visible the Reply Buttons-->
                      <!-- <div class="form-group mb-2 row" id="id_reply_button" style="display: none;">
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
                      </div> -->
                      <!-- Product List  -->
                      <!-- <div class="form-group mb-2 row" id="id_option_list" style="display: none;">
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
                      </div> -->

                    </div>

                    <!-- submit button and error display -->
                    <div class="card-footer text-center">
                    <div class="error_display" id='id_error_display'></div>
                      
                      <input type="hidden" name="txt_sms_count" id="txt_sms_count" value="<?= $sms_ttl_chars ?>">
                      <input type="hidden" name="txt_char_count" id="txt_char_count" value="<?= $cnt_ttl_chars ?>">
                      <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                        value='compose_whatsapp' />
                      <a href="#!" onclick="preview_compose_template()" name="preview_submit" id="preview_submit"
                        tabindex="11" value="" class="btn btn-info">Preview</a>
                      <input type="submit" name="compose_submit" id="compose_submit" tabindex="12" value="Submit"
                        class="btn btn-success">
                      <a href="communication" name="cancel_submit" id="cancel_submit" tabindex="13" value=""
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
          <h4 class="modal-title">Preview Message</h4>
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
getSenderIds();

document.addEventListener('DOMContentLoaded', function() {
    var textarea = document.getElementById('textarea');
    
    // Add event listener for input events
    textarea.addEventListener('input', function(event) {
        // Get the entered text
        var inputText = textarea.value;
        
        // Define a regular expression pattern to match the `˜` character
        var tildeRegex = /['"`]/g;
        
        // Test if the entered text contains the `˜` character
        if (tildeRegex.test(inputText)) {
            // Remove the `˜` character from the text
            textarea.value = inputText.replace(tildeRegex, '');
        }
    });
});
// const $dropdown = $('.sender_id'); // Cache all;
const $dropdown_grp = $('.group'); // Cache all;

    function UI_dropdown_grp() {
      const $this = $(this);
      const $btn = $('.dropdown-button_group', this);
      const $list = $('.dropdown-list_group', this);
      const $li = $('li', this);
      const $search = $('.dropdown-search_group', this);
      const $ckb = $(':checkbox', this);
      const $qty = $('.dropdown-quantity_group', this);
      $btn.on('click', function () {
        $dropdown_grp.not($this).removeClass('is-active'); // Close other
        $this.toggleClass('is-active'); // Toggle this
      });

      // Search functionality
      $search.on('input', function () {
        const val = $(this).val().trim();
        const rgx = new RegExp(val, 'i');
        // Target the list items within the container with class .test
        $('.groups li').each(function () {
          const name = $(this).text().trim(); // Extract text from list item
          $(this).toggleClass('is-hidden', !rgx.test(name));
        });
      });

      // select all
      $('#select-all-groups', $this).on('change', function () {
        const isChecked = $(this).prop('checked');
        $this.find(':checkbox').prop('checked', isChecked); // Set checkboxes within the current dropdown container
        updateQuantity(); // Update quantity display
      });

      $(document).on('change', '.group :checkbox', function (event) {
        updateQuantity(); // Update quantity display
      });

      // updateQuantity Function
      function updateQuantity() {
        const $checkedCheckboxes = $('.group').find(':checkbox:checked');
        const names = $checkedCheckboxes.map(function () {
          return `<span class="dropdown-sel">${$(this).closest('label').text().trim()}</span>`;
        }).get();
        $('.dropdown-quantity_group').html(names.join(''));
      }

    }

    // $dropdown.each(UI_dropdown);
    $dropdown_grp.each(UI_dropdown_grp);

function disableElement1(elementId) {
  getGroups();
      var element = document.getElementById(elementId);
      if (element) {
        element.disabled = true;
      } else {
        console.error("Element with ID '" + elementId + "' not found.");
      }
    }

    function disableElement2(elementId) {
      var element = document.getElementById(elementId);
      if (element) {
        element.disabled = true;
      } else {
        console.error("Element with ID '" + elementId + "' not found.");
      }
    }

    function func_open_newex_group(group_available) {
      var group_avail = $("input[type='radio'][name='rdo_media']:checked").val();
      <? // if($_REQUEST['group'] == '') { ?>
        if(group_avail == 'I') {
          $('#video_id').css("display", "none");
          $('#image_id').css("display", "block");
        } else if(group_avail == 'V') {
          $('#image_id').css("display", "none");
          $('#video_id').css("display", "block");
        }
      <? // } ?>
    }

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
        
      var selectedGroupNames = [];

// Get all selected checkboxes within the dropdown
var $selectedCheckboxes = $('.group :checkbox:checked');

// Iterate over each selected checkbox and extract its corresponding group name
$selectedCheckboxes.each(function() {
    // Get the label text associated with the checkbox
    var groupName = $(this).closest('label').text().trim();
    if (groupName !== 'Select All') {
        // Add the group name to the array
        selectedGroupNames.push(groupName);
    }
});

// Convert the array of selected group names to a comma-separated string
var selectedGroupsString = selectedGroupNames.join(',');

      fd.append( "groups",selectedGroupsString );
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

    function getSenderIds() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=get_sender_id",
        dataType: 'html',
        success: function (response) { // Success
          // console.log(response)
          $(".test").html(response);
        },
        error: function (response, status, error) { } // Error
      });
    }

    function getGroups() {
      var dropdown1 = document.getElementById('slt_whatsapp_sender');
// Get the selected value
var mobile_numbers = dropdown1.value;
      if(mobile_numbers != ''){
        var send_code = "&sender_id=" + mobile_numbers;
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=get_groups"+ send_code,
        dataType: 'html',
        success: function (response) { // Success
          console.log(response)
          $(".groups").html(response);
        },
        error: function (response, status, error) { } // Error
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
    // function call_composesms() {
    $(document).on("submit", "form#frm_compose_whatsapp", function (e) {
      
      var selectedGroupNames = [];

// Get all selected checkboxes within the dropdown
var $selectedCheckboxes = $('.group :checkbox:checked');

// Iterate over each selected checkbox and extract its corresponding group name
$selectedCheckboxes.each(function() {
    // Get the label text associated with the checkbox
    var groupValue = $(this).val();
    // Add the group name to the array
    var name = groupValue.replace(/\D/g, '');
    if(name){
      selectedGroupNames.push(name);
    }
});

// Convert the array of selected group names to a comma-separated string
var selectedGroupsString = selectedGroupNames.join(',');

      e.preventDefault();
      $("#id_error_display").html("");
      $('#txt_list_mobno').css('border-color', '#a0a0a0');
      $('#chk_remove_duplicates').css('border-color', '#a0a0a0');
      $('#chk_remove_invalids').css('border-color', '#a0a0a0');
      $('#txt_sms_content').css('border-color', '#a0a0a0');
      $('#txt_char_count').css('border-color', '#a0a0a0');
      $('#txt_sms_count').css('border-color', '#a0a0a0');
      $('#slt_whatsapp_sender').css('border-color', '#a0a0a0');
      $('#drop_down_id').css('border-color', '#a0a0a0');
      $('#textarea').css('border-color', '#a0a0a0');
      $('#upload_image').css('border-color', '#a0a0a0');
      $('#upload_video').css('border-color', '#a0a0a0');

      //get input field values 
      var txt_campaign_name = $('#txt_campaign_name').val();
      var txt_list_mobno = $('#txt_list_mobno').val();
      var chk_remove_duplicates = $('#chk_remove_duplicates').val();
      var chk_remove_invalids = $('#chk_remove_invalids').val();

      var upload_image = $('#upload_image').val();
      var upload_video = $('#upload_video').val();

      var flag = true;

      var dropdown1 = document.getElementById('slt_whatsapp_sender');

      // Get the selected value
      var mobile_numbers = dropdown1.value;

      var message = document.getElementById('textarea');

      // Get the selected value
      var message_text = message.value;
      console.log(mobile_numbers);
      console.log(message_text);
      console.log(selectedGroupsString);
      console.log(upload_image);
      console.log(upload_video);

      var group_avail = $("input[type='radio'][name='rdo_media']:checked").val();

      if(group_avail == "I" && upload_image == ""){
        $('#upload_image').css('border-color', 'red');
        flag = false;
      }
      if(group_avail == "V" && upload_video == ""){
        $('#upload_video').css('border-color', 'red');
        flag = false;
      }

      if (mobile_numbers == "") {
        // $("#id_error_display").html("Please select at least one Whatsapp Sender ID");
        $('#slt_whatsapp_sender').css('border-color', 'red');
        flag = false;
      }
      if (selectedGroupsString == "") {
        // $("#id_error_display").html("Please select at least one Whatsapp Group");
        $('#drop_down_id').css('border-color', 'red');
        flag = false;
      }
      if (message_text == "") {
        // $("#id_error_display").html("Please select at least one Whatsapp Group");
        $('#textarea').css('border-color', 'red');
        flag = false;
      }

      /********validate all our form fields***********/

      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        var fd = new FormData(this);
        fd.append("sender_ids",mobile_numbers)
        fd.append("groups",selectedGroupsString)
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
                window.location = 'communication_list';
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
        fileInput.value = '';
        return;
      }

      if (file_size > 5242880) { // 5 MB in bytes
        $("#id_error_display").html("Image file size must be below 5 MB. Kindly try again!");
        fileInput.value = '';
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
      var allowed_extensions = ["mp4"];
      // Check if the file extension is in the allowed list
      if (!allowed_extensions.includes(file_extension)) {
        $("#id_error_display").html("Invalid file type. Only MP4 files are allowed.");
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
