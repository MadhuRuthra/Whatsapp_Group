<?php
session_start();
error_reporting(0);
include_once('api/configuration.php');
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>
    window.location = "index";
  </script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);
site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Group Rights ::
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

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Group Rights</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Group Rights</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">

              <div class="col-12 col-md-12 col-lg-12">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_contact_group" name="frm_contact_group"
                    action="#" method="post" enctype="multipart/form-data">
                    <div class="card-body">
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Select Whatsapp Sender ID <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="slt_whatsapp_sender" id='slt_whatsapp_sender' class="form-control"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Sender ID" tabindex="1" autofocus
                            onchange="getGroups()">
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
                            site_log_generate("Compose Business Whatsapp Page : User : " . $_SESSION['yjwatsp_user_name'] . " get the Service response ($response) on " . date("Y-m-d H:i:s"));
                            if ($response == '') { ?>
                              <script>
                                window.location = "index"
                              </script>
                            <? } else if ($state1->response_status == 403) { ?>
                                <script>
                                  window.location = "index"
                                </script>
                            <? }
                            // After got response decode the JSON result
                            if ($state1->response_code == 1) {
                              // Looping the indicator is less than the count of templates.if the condition is true to continue the process and to get the details.if the condition are false to stop the process
                              for ($indicator = 0; $indicator < count($state1->sender_id); $indicator++) { // Set the response details into Option 
                                if ($state1->sender_id[$indicator]->senderid_master_status == 'Y' && $state1->sender_id[$indicator]->user_id == $_SESSION['yjwatsp_user_id']) {
                                  ?>
                                  <option value="<?= $state1->sender_id[$indicator]->mobile_no ?>">
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

                      <!-- Choose Group -->
                      <div class="form-group mb-2 row setting_show_group" style="display:none;">
                        <label class="col-sm-3 col-form-label"> Select Whatsapp Group <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="txt_group_name" id='txt_group_name' class="form-control groups"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Group" tabindex="1" autofocus onchange="getData()">
                          </select>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>
                      <br>
                      <div class="form-group mb-2 row setting_show" style="display:none;">
                        <label class="col-sm-3 col-form-label">
                          Add members <span data-toggle="tooltip"
                            data-original-title="Enter contact Name or Upload the Contact Downloaded CSV File Here">[?]</span>

                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7">
                          <div class="form-group mb-2 row">
                            <div class="col-sm-6">
                              <input type="text" name="contact_name_add" id='contact_name_add' tabindex="7"
                                class="form-control" value="" maxlength="1000" placeholder="Enter Contact Name"
                                data-toggle="tooltip" data-placement="top" title=""
                                onkeypress="return (event.charCode === 44 || (event.charCode >= 48 && event.charCode <= 57)) && this.value.length < 1000"
                                data-original-title="Enter contact name and comma separated,country code must allowed"
                                style="margin-bottom: 10px;" onpaste="return handlePaste(event);">
                              <!-- onpaste="return false;" -->
                            </div>
                            <div class="col-sm-6">
                              <input type="file" class="form-control" name="upload_contact_add" id='upload_contact_add'
                                tabindex="7" accept="text/csv" data-toggle="tooltip" data-placement="top"
                                data-html="true" title="" onclick="handleFileSelect()"
                                data-original-title="Upload the Contacts Mobile Number via CSV Files">
                              <label style="color:#FF0000">[Upload the Contacts Mobile
                                Number via CSV Files]</label>
                            </div>
                          </div>
                        </div>
                        <div class="col-sm-2">
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to Remove the Duplicates">
                              <input type="checkbox" name="chk_remove_duplicates" id="chk_remove_duplicates" checked
                                value="remove_duplicates" tabindex="7" onclick="call_remove_duplicate_invalid()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove
                                Duplicates</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to remove Invalids Mobile Nos">
                              <input type="checkbox" name="chk_remove_invalids" id="chk_remove_invalids" checked
                                value="remove_invalids" tabindex="7" onclick="call_remove_duplicate_invalid()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove
                                Invalids</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to remove Stop Status Mobile No's">
                              <input type="checkbox" name="chk_remove_stop_status" id="chk_remove_stop_status" checked
                                value="remove_stop_status" tabindex="7" onclick="call_remove_duplicate_invalid()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Stop
                                Status
                                Mobile
                                No's</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" id='id_mobupload'>
                          </div>
                        </div>
                      </div>

                      <div class="form-group mb-2 row setting_show" style="display:none;">
                        <label class="col-sm-3 col-form-label">
                          Remove members <span data-toggle="tooltip"
                            data-original-title="Enter contact Name or Upload the Contact Downloaded CSV File Here">[?]</span>
                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7">
                          <div class="form-group mb-2 row">
                            <div class="col-sm-6">
                              <div class="dropdown-container remove" name="contact_name_remove" id="contact_name_remove"
                                onclick="disableElement2('upload_contact_remove')">
                                <div class="dropdown-button dropdown-button_remove noselect" id="drop_down_id">
                                  <div class="dropdown-label">Select Member:</div>
                                  <div class="dropdown-quantity_remove"></div>
                                </div>
                                <div class="dropdown-list dropdown-list_remove ">
                                  <input type="search" placeholder="Search members" class="dropdown-search_remove"><br>
                                  <label><input id="select-all-remove" type="checkbox">Select
                                    All</label>
                                  <ul class="remove" id="remove">
                                  </ul>
                                </div>
                              </div>
                            </div>
                            <div class="col-sm-6">
                              <input type="file" class="form-control" name="upload_contact_remove"
                                id='upload_contact_remove' tabindex="7" accept="text/csv" data-toggle="tooltip"
                                data-placement="top" data-html="true" title=""
                                data-original-title="Upload the Contacts Mobile Number via CSV Files">
                              <label style="color:#FF0000">[Upload the Contacts Mobile
                                Number via CSV Files]</label>
                            </div>
                          </div>
                        </div>
                        <div class="col-sm-2">
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to Remove the Duplicates">
                              <input type="checkbox" name="chk_remove_duplicates" id="chk_remove_duplicates" checked
                                value="remove_duplicates" tabindex="7" onclick="call_remove_duplicate_invalid_remove()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove
                                Duplicates</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to remove Invalids Mobile Nos">
                              <input type="checkbox" name="chk_remove_invalids" id="chk_remove_invalids" checked
                                value="remove_invalids" tabindex="7" onclick="call_remove_duplicate_invalid_remove()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove
                                Invalids</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to remove Stop Status Mobile No's">
                              <input type="checkbox" name="chk_remove_stop_status" id="chk_remove_stop_status" checked
                                value="remove_stop_status" tabindex="7"
                                onclick="call_remove_duplicate_invalid_remove()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Stop
                                Status
                                Mobile
                                No's</span>
                            </label>
                          </div>

                          <div class="checkbox-fade fade-in-primary" id='id_mobupload'>

                          </div>
                        </div>
                      </div>

                      <div class="form-group mb-2 row setting_show" style="display:none;">
                        <label class="col-sm-3 col-form-label">
                          Promote member to admin <span data-toggle="tooltip"
                            data-original-title="Select Member to promote as admin">[?]</span>
                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7">
                          <div class="dropdown-container promote" name="contact_name_promote" id="contact_name_promote">
                            <div class="dropdown-button dropdown-button_promote noselect" id="drop_down_id">
                              <div class="dropdown-label">Select Member:</div>
                              <div class="dropdown-quantity_promote"></div>
                            </div>
                            <div class="dropdown-list dropdown-list_promote ">
                              <input type="search" placeholder="Search members" class="dropdown-search_promote"><br>
                              <label><input id="select-all-promote" type="checkbox">Select All</label>
                              <ul class="promote" id="promote">
                              </ul>
                            </div>
                          </div>
                        </div>
                      </div>

                      <br>
                      <div class="form-group mb-2 row setting_show" style="display:none;">
                        <label class="col-sm-3 col-form-label">
                          Demote admin to member <span data-toggle="tooltip"
                            data-original-title="Select admin to demote as member">[?]</span>
                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7">

                          <div class="dropdown-container demote" name="contact_name_demote" id="contact_name_demote">
                            <div class="dropdown-button dropdown-button_demote noselect" id="drop_down_id">
                              <div class="dropdown-label">Select Member:</div>
                              <div class="dropdown-quantity_demote"></div>
                            </div>
                            <div class="dropdown-list dropdown-list_demote ">
                              <input type="search" placeholder="Search members" class="dropdown-search_demote"><br>
                              <label><input id="select-all-demote" type="checkbox">Select All</label>
                              <ul class="demote" id="demote">
                              </ul>
                            </div>
                          </div>
                        </div>
                      </div>
                      <br>
                      <div class="form-group mb-2 row setting_show" style="display:none;">
                        <label class="col-sm-3 col-form-label">
                          Who can send message to group
                          <span data-toggle="tooltip"
                            data-original-title='You can specify who can send messages to your group. It can be either only admins or both admins and members.'>[?]</span>

                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7" style="margin-top:10px;">
                          <input type="radio" name="rdo_msg_setting" id="rdo_msg_setting_admin" tabindex="2" value="A">
                          Only Admins&nbsp;&nbsp;&nbsp;
                          <input type="radio" name="rdo_msg_setting" id="rdo_msg_setting_member" tabindex="3"
                            value="M">Admins and Members
                        </div>
                      </div>
                    </div>
                    <div class="card-footer text-center" id="setting_show_submit">
                      <span class="error_display" id='id_error_display'></span><br>
                      <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                        value='group_rights' />
                      <input type="submit" name="compose_submit" id="compose_submit" tabindex="8" value="Submit"
                        class="btn btn-success">
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </section>

      </div>

      <? include("libraries/site_footer.php"); ?>

    </div>
  </div>
  <!-- Modal content-->
  <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" style=" max-width: 50% !important;">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Group Rights</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" id="id_modal_display" style="word-wrap: break-word; word-break: break-word;">
          <table class="table table-striped table-bordered m-0 add_remove"
            style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
            <tbody>
              <tr style="border: 1px solid #000;">
                <th scope="col" style="border: 1px solid #000;">Action</th>
                <th scope="col" style="border: 1px solid #000;">Success</th>
                <th scope="col" style="border: 1px solid #000;">Exist</th>
                <th scope="col" style="border: 1px solid #000;">Invalid</th>
                <th scope="col" style="border: 1px solid #000;">Duplicate</th>
              </tr>
              <!-- First row -->
              <tr style="border: 1px solid #000;">
                <th scope="row" style="border: 1px solid #000;">Add Members</th>
                <td class="add_success" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="add_exist" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="add_invalid" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="add_duplicate" style="white-space: inherit !important;border: 1px solid #000;"></td>
              </tr>
              <!-- Second row -->
              <tr style="border: 1px solid #000;">
                <th scope="row" style="border: 1px solid #000;">Remove Members</th>
                <td class="rm_success" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="rm_exist" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="rm_invalid" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="rm_duplicate" style="white-space: inherit !important;border: 1px solid #000;"></td>
              </tr>
            </tbody>
          </table>
          <br>
          <table class="table table-striped table-bordered m-0 promote_demote"
            style="table-layout: fixed; white-space: inherit; width: 100%; overflow-x: scroll;">
            <tbody>
              <tr style="border: 1px solid #000;">
                <th scope="col" style="border: 1px solid #000;">Action</th>
                <th scope="col" style="border: 1px solid #000;">Success</th>
                <th scope="col" style="border: 1px solid #000;">Failed</th>
              </tr>
              <!-- Third row (with only two columns) -->
              <tr>
                <th scope="row" style="border: 1px solid #000;">Promote Members</th>
                <td class="pm_success" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="pm_failed" style="white-space: inherit !important;border: 1px solid #000;"></td>
              </tr>
              <!-- Fourth row (with only two columns) -->
              <tr style="border: 1px solid #000;">
                <th scope="row" style="border: 1px solid #000;">Demote Admin</th>
                <td class="dm_success" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="dm_failed" style="white-space: inherit !important;border: 1px solid #000;"></td>
              </tr>
              <tr style="border: 1px solid #000;">
                <th scope="row" style="border: 1px solid #000;">Message Settings</th>
                <td class="msg_setting_suc" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="msg_setting_fal" style="white-space: inherit !important;border: 1px solid #000;"> - </td>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-success waves-effect " data-dismiss="modal">Close</button>
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

  <!-- JS Libraies -->
  <!-- Page Specific JS File -->
  <!-- Template JS File -->
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>

  <script src="assets/js/xlsx.core.min.js"></script>
  <script src="assets/js/xls.core.min.js"></script>

  <script>
    var updated_promote_values = [], updated_remove_values = [],
      selectedValue, response_remove = [], updated_demote_values = [];
    response_demote = [],
      response_promote = [];
    const $dropdown_grp = $('.remove'); // Cache all;

    function UI_dropdown_grp() {
      const $this = $(this);
      const $btn = $('.dropdown-button_remove', this);
      const $list = $('.dropdown-list_remove', this);
      const $li = $('li', this);
      const $search = $('.dropdown-search_remove', this);
      const $ckb = $(':checkbox', this);
      const $qty = $('.dropdown-quantity_remove', this);
      $btn.on('click', function () {
        $dropdown_grp.not($this).removeClass('is-active'); // Close other
        $this.toggleClass('is-active'); // Toggle this
      });
      // Search functionality
      $search.on('input', function () {
        const val = $(this).val().trim();
        const rgx = new RegExp(val, 'i');
        // Target the list items within the container with class .test
        $('.remove li').each(function () {
          const name = $(this).text().trim(); // Extract text from list item
          $(this).toggleClass('is-hidden', !rgx.test(name));
        });
      });
      // select all
      $('#select-all-remove', $this).on('change', function () {
        const isChecked = $(this).prop('checked');
        $this.find(':checkbox').prop('checked',
          isChecked); // Set checkboxes within the current dropdown container
        updateQuantity(); // Update quantity display
      });
      $(document).on('change', '.remove :checkbox', function (event) {
        updateQuantity(); // Update quantity display
      });
      function updateQuantity() {
        const $checkedCheckboxes = $('.remove :checkbox:checked');
        const $quantityDisplay = $('.dropdown-quantity_remove');
        const $promoteList = $('#promote');
        const $demoteList = $('#demote');
        const names = $checkedCheckboxes.map(function () {
          return `<span class="dropdown-sel">${$(this).closest('label').text().trim()}</span>`;
        }).get();
        $quantityDisplay.html(names.join(','));
        if (updated_promote_values.length > 0) {
          const resultArray = updated_promote_values.filter(value => !$checkedCheckboxes.is(`[value="${value}"]`));
          const response_promote = resultArray.map(contact => {
            return `<li><label><input value="${contact}" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">${contact}</label></li>`;
          });
          $promoteList.html(response_promote.join(''));
        }
        if (updated_demote_values.length > 0) {
          const resultArray = updated_demote_values.filter(value => !$checkedCheckboxes.is(`[value="${value}"]`));
          const response_demote = resultArray.map(contact => {
            return `<li><label><input value="${contact}" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">${contact}</label></li>`;
          });
          $demoteList.html(response_demote.join(''));

        }
      }

    }
    // $dropdown.each(UI_dropdown);
    $dropdown_grp.each(UI_dropdown_grp);

    function disableElement2(elementId) {
      var element = document.getElementById(elementId);
      if (element) {
        element.value = "";
        element.disabled = true;
      } else {
        console.error("Element with ID '" + elementId + "' not found.");
      }
    }

    // Promote admin Multiple select
    const $dropdown_grp_promote = $('.promote'); // Cache all;
    function UI_dropdown_grp_promote() {
      const $this = $(this);
      const $btn = $('.dropdown-button_promote', this);
      const $list = $('.dropdown-list_promote', this);
      const $li = $('li', this);
      const $search = $('.dropdown-search_promote', this);
      const $ckb = $(':checkbox', this);
      const $qty = $('.dropdown-quantity_promote', this);
      $btn.on('click', function () {
        $dropdown_grp_promote.not($this).removeClass('is-active'); // Close other
        $this.toggleClass('is-active'); // Toggle this
      });
      // Search functionality
      $search.on('input', function () {
        const val = $(this).val().trim();
        const rgx = new RegExp(val, 'i');
        // Target the list items within the container with class .test
        $('.promote li').each(function () {
          const name = $(this).text().trim(); // Extract text from list item
          $(this).toggleClass('is-hidden', !rgx.test(name));
        });
      });
      // select all
      $('#select-all-promote', $this).on('change', function () {
        const isChecked = $(this).prop('checked');
        $this.find(':checkbox').prop('checked',
          isChecked); // Set checkboxes within the current dropdown container
        updateQuantity(); // Update quantity display
      });
      $(document).on('change', '.promote :checkbox', function (event) {
        updateQuantity(); // Update quantity display
      });
      function updateQuantity() {
        const $checkedCheckboxes = $('.promote :checkbox:checked');
        const $quantityDisplay = $('.dropdown-quantity_promote');
        const $removeList = $('#remove');

        const names = $checkedCheckboxes.map(function () {
          return `<span class="dropdown-sel">${$(this).closest('label').text().trim()}</span>`;
        }).get();
        $quantityDisplay.html(names.join(','));

        const resultArray = updated_remove_values.filter(value => !$checkedCheckboxes.is(`[value="${value}"]`));
        const response_remove = resultArray.map(contact => {
          return `<li><label><input value="${contact}" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">${contact}</label></li>`;
        });
        $removeList.html(response_remove.join(''));
      }
    }
    $dropdown_grp_promote.each(UI_dropdown_grp_promote);

    // Demote admin Multiple select
    const $dropdown_grp_demote = $('.demote'); // Cache all;
    function UI_dropdown_grp_demote() {
      const $this = $(this);
      const $btn = $('.dropdown-button_demote', this);
      const $list = $('.dropdown-list_demote', this);
      const $li = $('li', this);
      const $search = $('.dropdown-search_demote', this);
      const $ckb = $(':checkbox', this);
      const $qty = $('.dropdown-quantity_demote', this);
      $btn.on('click', function () {
        $dropdown_grp_demote.not($this).removeClass('is-active'); // Close other
        $this.toggleClass('is-active'); // Toggle this
      });
      // Search functionality
      $search.on('input', function () {
        const val = $(this).val().trim();
        const rgx = new RegExp(val, 'i');
        // Target the list items within the container with class .test
        $('.demote li').each(function () {
          const name = $(this).text().trim(); // Extract text from list item
          $(this).toggleClass('is-hidden', !rgx.test(name));
        });
      });
      // select all
      $('#select-all-demote', $this).on('change', function () {
        const isChecked = $(this).prop('checked');
        $this.find(':checkbox').prop('checked',
          isChecked); // Set checkboxes within the current dropdown container
        updateQuantity(); // Update quantity display
      });
      $(document).on('change', '.demote :checkbox', function (event) {
        updateQuantity(); // Update quantity display
      });
      // updateQuantity Function
      function updateQuantity() {
        const $checkedCheckboxes = $('.demote :checkbox:checked');
        const $quantityDisplay = $('.dropdown-quantity_demote');
        const $removeList = $('#remove');

        const names = $checkedCheckboxes.map(function () {
          return `<span class="dropdown-sel">${$(this).closest('label').text().trim()}</span>`;
        }).get();
        $quantityDisplay.html(names.join(','));

        const resultArray = updated_remove_values.filter(value => !$checkedCheckboxes.is(`[value="${value}"]`));
        const response_remove = resultArray.map(contact => {
          return `<li><label><input value="${contact}" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">${contact}</label></li>`;
        });
        $removeList.html(response_remove.join(''));
      }
    }
    $dropdown_grp_demote.each(UI_dropdown_grp_demote);


    function getData() {
      // myFunction();
      selectedValue = document.getElementById("txt_group_name").value;
      console.log("Selected option:", selectedValue);
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=getGroupDetails&group_id=" + selectedValue,
        dataType: 'json',
        beforeSend: function () {
          $('.theme-loader').show();
        },
        complete: function () {
          $('.theme-loader').hide();
        },
        success: function (response) {
          for (let key in response) {
            var ul = document.getElementById('remove');
            if (key == 0) {
              var contacts = response[key]
              // Loop through the contacts array
              contacts.forEach(function (contact) {
                if (contact.member !== null) {
                  // Create a new li element
                  console.log(contact.member + "memmbers");
                  updated_remove_values.push(contact.member)
                  response_remove.push('<li><label><input value="' + contact.member +
                    '" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">' +
                    contact.member + '</label></li>')
                }
              });
              $('#remove').html(response_remove);
            }
            if (key == 1) {
              var contacts = response[key]
              // Loop through the contacts array
              contacts.forEach(function (contact) {
                if (contact.member !== null) {
                  updated_promote_values.push(contact.member)
                  // Create a new li element
                  console.log(contact.member + "memmbers");
                  response_promote.push('<li><label><input value="' + contact.member +
                    '" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">' +
                    contact.member + '</label></li>')
                }
              });
              $('#promote').html(response_promote);
            }
            if (key == 2) {
              var admin_contacts = response[key]
              // Loop through the contacts array
              admin_contacts.forEach(function (ad_contact) {
                if (ad_contact.admin !== null) {
                  updated_demote_values.push(ad_contact.admin);
                  console.log(ad_contact.admin + "admin_con");
                  response_demote.push('<li><label><input value="' + ad_contact
                    .admin +
                    '" name="txt_whatsapp_mobno[]" data-name="" type="checkbox">' +
                    ad_contact.admin + '</label></li>')
                }
              });
              $('#demote').html(response_demote);
            }
            if (key == 3) {
              var radioAdmin = response[key][0].rights_value == 'N' ? document.getElementById(
                'rdo_msg_setting_member') : document.getElementById('rdo_msg_setting_admin');
              radioAdmin.checked = true;
            }
          }
          if (selectedValue == "") {
            $('.setting_show').css("display", "none")
            $('#setting_show_submit').css("display", "none")
          } else {
            $('.setting_show').css("display", "flex")
            $('#setting_show_submit').css("display", "block")
          }
        },
        error: function (response, status, error) {
          console.log(response)
          console.log(error)
        } // Error
      });
    }


    $("#id_checkAll").click(function () {
      $('input:checkbox').not(this).prop('checked', this.checked);
    });

    $(function () {
      $('.theme-loader').fadeOut("slow");
      init();
    });

    function func_change_groupname(sender_id) {
      var send_code = "&sender_id=" + sender_id;
      $('#slt_group').html('');
      console.log("!!!FALSE");
      $.ajax({
        type: 'post',
        url: "ajax/call_functions.php?tmpl_call_function=senderid_groupname" + send_code,
        dataType: 'json',
        beforeSend: function () {
          $('.theme-loader').show();
        },
        complete: function () {
          $('.theme-loader').hide();
        },
        success: function (response) {
          $('#slt_group').html(response.msg);
          $('.theme-loader').hide();
        },
        error: function (response, status, error) { }
      });
    }

    function handleFileSelectremove(event) {
      var flenam = document.querySelector('#upload_contact_remove').value;
      var extn = flenam.split('.').pop();

      if (extn == 'xlsx' || extn == 'xls') {
        ExportToTableRemove();
      } else {
        const reader = new FileReader()
        reader.onload = handleFileLoadRemove;
        reader.readAsText(event.target.files[0])
      }
    }

    function handleFileSelect() {
      var flenam = document.querySelector('#upload_contact_add').value;
      console.log(flenam);
      $('#contact_name_add').val("");
      var extn = flenam.split('.').pop();
      if (extn == 'xlsx' || extn == 'xls') {
        ExportToTable();
      } else {
        const fileInput = document.querySelector('#upload_contact_add');
        console.log(fileInput);
        console.log(fileInput.files.length)
        console.log(fileInput.files)
        if (fileInput.files.length > 0) {
          const reader = new FileReader();
          reader.onload = handleFileLoad;
          reader.readAsText(fileInput.files[0]);
        } else {
          // Handle case when no file is selected
          console.error('No file selected.');
        }
      }
    }

    function handleFileLoad(event) {
      console.log(event);
      $('#txt_list_mobno').val(event.target.result);
      $('#txt_list_mobno').focus();
    }

    function handleFileLoadRemove(event) {
      console.log(event);
      $('#txt_list_mobno_remove').val(event.target.result);
      $('#txt_list_mobno_remove').focus();
    }

    var value_list_remove = new Array; ///this one way of declaring array in javascript
    function ExportToTableRemove() {
      var regex = /^([a-zA-Z0-9\s_\\.\-:])+(.xlsx|.xls)$/;
      /*Checks whether the file is a valid excel file*/
      if (regex.test($("#upload_contact_remove").val().toLowerCase())) {
        var xlsxflag = false; /*Flag for checking whether excel is .xls format or .xlsx format*/
        if ($("#upload_contact_remove").val().toLowerCase().indexOf(".xlsx") > 0) {
          xlsxflag = true;
        }
        /*Checks whether the browser supports HTML5*/
        if (typeof (FileReader) != "undefined") {
          var reader = new FileReader();
          reader.onload = function (e) {
            var data = e.target.result;
            /*Converts the excel data in to object*/
            if (xlsxflag) {
              var workbook = XLSX.read(data, {
                type: 'binary'
              });
            } else {
              var workbook = XLS.read(data, {
                type: 'binary'
              });
            }
            /*Gets all the sheetnames of excel in to a variable*/
            var sheet_name_list = workbook.SheetNames;

            var cnt = 0; /*This is used for restricting the script to consider only first sheet of excel*/
            sheet_name_list.forEach(function (y) {
              /*Iterate through all sheets*/
              /*Convert the cell value to Json*/
              if (xlsxflag) {
                var exceljson = XLSX.utils.sheet_to_json(workbook.Sheets[y]);
              } else {
                var exceljson = XLS.utils.sheet_to_row_object_array(workbook.Sheets[y]);
              }
              if (exceljson.length > 0 && cnt == 0) {
                BindTableRemove(exceljson, '#txt_list_mobno_remove');
                cnt++;
              }
            });
            $('#txt_list_mobno_remove').show();
            $('#txt_list_mobno_remove').focus();
          }
          if (xlsxflag) {
            /*If excel file is .xlsx extension than creates a Array Buffer from excel*/
            reader.readAsArrayBuffer($("#upload_contact_remove")[0].files[0]);
          } else {
            reader.readAsBinaryString($("#upload_contact_remove")[0].files[0]);
          }
        } else {
          alert("Sorry! Your browser does not support HTML5!");
        }
      } else {
        alert("Please upload a valid Excel file!");
      }
    }

    var value_list = new Array; ///this one way of declaring array in javascript
    function ExportToTable() {
      var regex = /^([a-zA-Z0-9\s_\\.\-:])+(.xlsx|.xls)$/;
      /*Checks whether the file is a valid excel file*/
      if (regex.test($("#upload_contact_add").val().toLowerCase())) {
        var xlsxflag = false; /*Flag for checking whether excel is .xls format or .xlsx format*/
        if ($("#upload_contact_add").val().toLowerCase().indexOf(".xlsx") > 0) {
          xlsxflag = true;
        }
        /*Checks whether the browser supports HTML5*/
        if (typeof (FileReader) != "undefined") {
          var reader = new FileReader();
          reader.onload = function (e) {
            var data = e.target.result;
            /*Converts the excel data in to object*/
            if (xlsxflag) {
              var workbook = XLSX.read(data, {
                type: 'binary'
              });
            } else {
              var workbook = XLS.read(data, {
                type: 'binary'
              });
            }
            /*Gets all the sheetnames of excel in to a variable*/
            var sheet_name_list = workbook.SheetNames;

            var cnt = 0; /*This is used for restricting the script to consider only first sheet of excel*/
            sheet_name_list.forEach(function (y) {
              /*Iterate through all sheets*/
              /*Convert the cell value to Json*/
              if (xlsxflag) {
                var exceljson = XLSX.utils.sheet_to_json(workbook.Sheets[y]);
              } else {
                var exceljson = XLS.utils.sheet_to_row_object_array(workbook.Sheets[y]);
              }
              if (exceljson.length > 0 && cnt == 0) {
                BindTable(exceljson, '#txt_list_mobno');
                cnt++;
              }
            });
            $('#txt_list_mobno').show();
            $('#txt_list_mobno').focus();
          }
          if (xlsxflag) {
            /*If excel file is .xlsx extension than creates a Array Buffer from excel*/
            reader.readAsArrayBuffer($("#upload_contact_add")[0].files[0]);
          } else {
            reader.readAsBinaryString($("#upload_contact_add")[0].files[0]);
          }
        } else {
          alert("Sorry! Your browser does not support HTML5!");
        }
      } else {
        alert("Please upload a valid Excel file!");
      }
    }

    function BindTableRemove(jsondata, tableid) {
      /*Function used to convert the JSON array to Html Table*/
      var columns = BindTableHeaderRemove(jsondata, tableid); /*Gets all the column headings of Excel*/
      for (var i = 0; i < jsondata.length; i++) {
        for (var colIndex = 0; colIndex < columns.length; colIndex++) {
          var cellValue = jsondata[i][columns[colIndex]];
          if (cellValue == null)
            cellValue = "";
          value_list_remove.push("\n" + cellValue);
        }
      }
      $(tableid).val(value_list_remove);
    }

    function BindTable(jsondata, tableid) {
      /*Function used to convert the JSON array to Html Table*/
      var columns = BindTableHeader(jsondata, tableid); /*Gets all the column headings of Excel*/
      for (var i = 0; i < jsondata.length; i++) {
        for (var colIndex = 0; colIndex < columns.length; colIndex++) {
          var cellValue = jsondata[i][columns[colIndex]];
          if (cellValue == null)
            cellValue = "";
          value_list.push("\n" + cellValue);
        }
      }
      $(tableid).val(value_list);
    }

    function BindTableHeader(jsondata, tableid) {
      /*Function used to get all column names from JSON and bind the html table header*/
      var columnSet = [];
      for (var i = 0; i < jsondata.length; i++) {
        var rowHash = jsondata[i];
        for (var key in rowHash) {
          if (rowHash.hasOwnProperty(key)) {
            if ($.inArray(key, columnSet) == -1) {
              /*Adding each unique column names to a variable array*/
              columnSet.push(key);
              value_list.push("\n" + key);
            }
          }
        }
      }
      return columnSet;
    }

    function BindTableHeaderRemove(jsondata, tableid) {
      /*Function used to get all column names from JSON and bind the html table header*/
      var columnSet = [];
      for (var i = 0; i < jsondata.length; i++) {
        var rowHash = jsondata[i];
        for (var key in rowHash) {
          if (rowHash.hasOwnProperty(key)) {
            if ($.inArray(key, columnSet) == -1) {
              /*Adding each unique column names to a variable array*/
              columnSet.push(key);
              value_list_remove.push("\n" + key);
            }
          }
        }
      }
      return columnSet;
    }
    // To Remove the Duplicate Mobile numbers
    function call_remove_duplicate_invalid_remove() {
      $("#txt_list_mobno_remove_txt").html("");
      var txt_list_mobno_remove = $("#txt_list_mobno_remove").val();

      var chk_remove_duplicates = 0;
      if ($("#chk_remove_duplicates").prop('checked') == true) {
        chk_remove_duplicates = 1;
      }

      var chk_remove_invalids = 0;
      if ($("#chk_remove_invalids").prop('checked') == true) {
        chk_remove_invalids = 1;
      }

      var chk_remove_stop_status = 0;
      if ($("#chk_remove_stop_status").prop('checked') == true) {
        chk_remove_stop_status = 1;
      }

      $.ajax({
        type: 'post',
        url: "ajax/message_call_functions.php",
        data: {
          validateMobno: 'validateMobno',
          mobno: txt_list_mobno_remove,
          dup: chk_remove_duplicates,
          inv: chk_remove_invalids
        },
        success: function (response_msg) { // Success
          let response_msg_text = response_msg.msg;
          const response_msg_split = response_msg_text.split("||");
          $("#txt_list_mobno_remove").val(response_msg_split[0]);
          if (response_msg_split[1] != '') {
            $("#txt_list_mobno_remove_txt").html("Invalid Mobile Nos : " + response_msg_split[1]);
          }

          if (chk_remove_stop_status == 1) {

          }
        },
        error: function (response_msg, status, error) { // Error
        }
      });
    }

    // To Remove the Duplicate Mobile numbers
    function call_remove_duplicate_invalid() {
      $("#txt_list_mobno_txt").html("");
      var txt_list_mobno = $("#txt_list_mobno").val();

      var chk_remove_duplicates = 0;
      if ($("#chk_remove_duplicates").prop('checked') == true) {
        chk_remove_duplicates = 1;
      }

      var chk_remove_invalids = 0;
      if ($("#chk_remove_invalids").prop('checked') == true) {
        chk_remove_invalids = 1;
      }

      var chk_remove_stop_status = 0;
      if ($("#chk_remove_stop_status").prop('checked') == true) {
        chk_remove_stop_status = 1;
      }

      $.ajax({
        type: 'post',
        url: "ajax/message_call_functions.php",
        data: {
          validateMobno: 'validateMobno',
          mobno: txt_list_mobno,
          dup: chk_remove_duplicates,
          inv: chk_remove_invalids
        },
        success: function (response_msg) { // Success
          let response_msg_text = response_msg.msg;
          const response_msg_split = response_msg_text.split("||");
          $("#txt_list_mobno").val(response_msg_split[0]);
          if (response_msg_split[1] != '') {
            $("#txt_list_mobno_txt").html("Invalid Mobile Nos : " + response_msg_split[1]);
          }
          if (chk_remove_stop_status == 1) {

          }
        },
        error: function (response_msg, status, error) { // Error
        }
      });
    }

    function getGroups() {
      var dropdown1 = document.getElementById('slt_whatsapp_sender');
      // Get the selected value
      var mobile_numbers = dropdown1.value;
      if (mobile_numbers != '') {
        var send_code = "&sender_id=" + mobile_numbers;
        $.ajax({
          type: 'post',
          url: "ajax/display_functions.php?call_function=get_rights_groups" + send_code,
          dataType: 'html',
          success: function (response) { // Success
            $(".groups").html(response);
            $('.setting_show_group').css("display", "")
          },
          error: function (response, status, error) { } // Error
        });
      }
    }
    var rdo_msg_setting = false;
    $('input[name="rdo_msg_setting"]').on('change', function () {
      if ($(this).is(':checked')) {
        rdo_msg_setting = true;
      }
    });

    $(document).on("submit", "form#frm_contact_group", function (e) {
      e.preventDefault();
      $('#compose_submit').prop('disabled', false);
      console.log("View Submit Pages");
      console.log("came Inside");
      $("#id_error_display").html("");
      $('#txt_group_name').css('border-color', '#a0a0a0');
      //get input field values 
      var slt_group = $('#slt_group').val();
      var group_avail = $("input[type='radio'][name='rdo_newex_group']:checked").val();

      if (rdo_msg_setting === false) {
        $('#rdo_msg_setting_admin').prop('checked', false);
        $('#rdo_msg_setting_member').prop('checked', false);
      }
      var flag = true;
      /********validate all our form fields***********/

      var grp_mas_id = document.getElementById('txt_group_name');
      var grp_mas_id_value = grp_mas_id.value;
      if (grp_mas_id_value == "") {
        // $("#id_error_display").html("Please select mandal");
        $('#txt_group_name').css('border-color', 'red');
        flag = false;
      }

      var spanElements = document.querySelectorAll('.dropdown-quantity_remove .dropdown-sel');
      var remove_mobile_numbers = "";
      spanElements.forEach(function (span) {
        var number = span.textContent.trim().replace(/\D/g, ''); // Remove non-numeric characters
        if (number) {
          remove_mobile_numbers += "," + number; // Concatenate mobile numbers
          // Remove leading comma if present
          if (remove_mobile_numbers.startsWith(',')) {
            remove_mobile_numbers = remove_mobile_numbers.substring(1);
          }
        }
      });

      var spanElements = document.querySelectorAll('.dropdown-quantity_promote .dropdown-sel');
      var promote_mobile_numbers = "";
      spanElements.forEach(function (span) {
        var number = span.textContent.trim().replace(/\D/g, ''); // Remove non-numeric characters
        if (number) {
          promote_mobile_numbers += "," + number; // Concatenate mobile numbers
          // Remove leading comma if present
          if (promote_mobile_numbers.startsWith(',')) {
            promote_mobile_numbers = promote_mobile_numbers.substring(1);
          }
        }
      });
      var spanElements = document.querySelectorAll('.dropdown-quantity_demote .dropdown-sel');
      var demote_mobile_numbers = "";
      spanElements.forEach(function (span) {
        var number = span.textContent.trim().replace(/\D/g, ''); // Remove non-numeric characters
        if (number) {
          demote_mobile_numbers += "," + number; // Concatenate mobile numbers
          // Remove leading comma if present
          if (demote_mobile_numbers.startsWith(',')) {
            demote_mobile_numbers = demote_mobile_numbers.substring(1);
          }
        }
      });

      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        var fd = new FormData(this);

        fd.append('group_id', selectedValue);
        fd.append('remove_mobile_numbers', remove_mobile_numbers);
        fd.append('promote_mobile_numbers', promote_mobile_numbers);
        fd.append('demote_mobile_numbers', demote_mobile_numbers);
        $.ajax({
          type: 'post',
          url: "ajax/message_call_functions.php",
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
          },
          success: function (response) {
            var response_obj_str = JSON.stringify(response);
            var response_obj = JSON.parse(response_obj_str);
            // Accessing the properties
            var status = response_obj.status;
            var msg = response_obj.msg;
            // Since msg is a stringified JSON, parse it again to access its properties
            var msg_obj = JSON.parse(msg);
            if (response_obj.status == '0') {
              $('#txt_group_name').val('');
              $('#upload_contact_add').val('');
              $('#upload_contact_remove').val('');
              $('#compose_submit').attr('disabled', false);
              $('#id_submit_composercs').attr('disabled', false);
              $("#id_error_display").html(response_obj.msg);
            } else if (response_obj.status == 2) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response_obj.msg);
              $('#compose_submit').attr('disabled', false);
            } else if (response_obj.status == 1) {

              const addSuccessValue = msg_obj.add.success.length > 0 ? msg_obj.add.success.join(', ') : '-';
              $('.add_success').text(addSuccessValue);
              const addinvaildValue = msg_obj.add.exist.length > 0 ? msg_obj.add.exist.join(', ') : '-';
              $('.add_invalid').text(addinvaildValue);
              const addexistsValue = msg_obj.add.invalid.length > 0 ? msg_obj.add.invalid.join(', ') : '-';
              $('.add_exist').text(addexistsValue);
              const adduplicateValue = msg_obj.add.exist.length > 0 ? msg_obj.add.exist.join(', ') : '-';
              $('.add_duplicate').text(adduplicateValue);
              const removeSuccessValue = msg_obj.remove.success.length > 0 ? msg_obj.remove.success.join(', ') : '-';
              $('.rm_success').text(removeSuccessValue);
              const removeinvaildValue = msg_obj.remove.failed.length > 0 ? msg_obj.remove.failed.join(', ') : '-';
              $('.rm_invalid').text(removeinvaildValue);
              const removeexistsValue = msg_obj.remove.invalid.length > 0 ? msg_obj.remove.invalid.join(', ') : '-';
              $('.rm_exist').text(removeexistsValue);
              const removeduplicateValue = msg_obj.remove.duplicate.length > 0 ? msg_obj.duplicate.exist.join(', ') : '-';
              $('.rm_duplicate').text(removeduplicateValue);
              const pmSuccessValue = msg_obj.promote.success.length > 0 ? msg_obj.promote.success.join(', ') : '-';
              $('.pm_success').text(pmSuccessValue);
              const pmexistsValue = msg_obj.promote.failed.length > 0 ? msg_obj.promote.failed.join(', ') : '-';
              $('.pm_failed').text(pmexistsValue);
              const dmSuccessValue = msg_obj.demote.success.length > 0 ? msg_obj.demote.success.join(', ') : '-';
              $('.dm_success').text(dmSuccessValue);
              const dmexistsValue = msg_obj.demote.failed.length > 0 ? msg_obj.demote.failed.join(', ') : '-';
              $('.dm_failed').text(dmexistsValue);
              const msg_setting = msg_obj.status.message_setting_response ? msg_obj.status.message_setting_response : '-';
              $('.msg_setting_suc').text(msg_setting);
              $('#default-Modal').modal({ show: true });
              $('#compose_submit').attr('disabled', false);
              $('#default-Modal').on('hidden.bs.modal', function (e) {
                window.location = 'group_rights';
              });
              setInterval(function () {
              }, 5000);
              $("#id_error_display").html("Contacts Created Successfully..");

            }

            $('.theme-loader').hide();
          },
          error: function (response, status, error) {
            console.log("FAL");
            $("#id_modal_display").html(response);
            console.log(response.status);
            $('#txt_group_name').val('');
            $('#upload_contact_add').val('');
            $('#upload_contact_remove').val('');
            $('#compose_submit').attr('disabled', false);
            $('#id_submit_composercs').attr('disabled', false);
            $('.theme-loader').show();
            //window.location = 'index';
            $("#id_error_display").html(response.msg);
          }
        });
      }
    });

    // Event listener for the file input
    $("#upload_contact_add, #upload_contact_remove").on({
      mouseenter: function () {
        // Remove disabled attribute from file input
        $(this).removeAttr("disabled");
      }
    })
    $(document).on('click', '#upload_contact_add, #upload_contact_remove', function () {
      // Clear currently selected checkboxes and quantity display
      clearDropdownValues(this.id);
    });

    function clearDropdownValues(id) {
      const substringsids = id.split('_');
      const checkboxSelector = '.' + substringsids[2] + ' :checkbox';
      $(checkboxSelector).prop('checked', false);
      $('.dropdown-quantity_' + substringsids[2]).empty();
    }

    // paste only allowed on numbers and comma only using on add members count.
    function handlePaste(event) {
      var pastedText = (event.clipboardData || window.clipboardData).getData('text');
      var filteredText = pastedText.replace(/[^0-9,]/g, '');
      var input = document.getElementById('contact_name_add');
      input.value = filteredText;
      event.preventDefault();
    }
  </script>
</body>

</html>