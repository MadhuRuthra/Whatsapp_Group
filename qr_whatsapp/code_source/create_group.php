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
  <title>Create Group ::
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

    .preloader-wrapper {
      display: flex;
      justify-content: center;
      background: rgba(22, 22, 22, 0.3);
      width: 100%;
      height: 80%;
      position: fixed;
      top: 0;
      left: 0;
      z-index: 10;
      align-items: center;
    }

    .preloader-wrapper>.preloader {
      background: transparent url("assets/img/ajaxloader.webp") no-repeat center top;
      min-width: 128px;
      min-height: 128px;
      z-index: 10;
      /* background-color:#f27878; */
      position: fixed;
    }
  </style>
</head>

<body>
  <div class="theme-loader"></div>
  <div class="preloader-wrapper" style="display:none;">
    <div class="preloader">
    </div>
    <div class="text" style="color: white; background-color:#f27878; padding: 10px; margin-left:400px;">
      <b>Mobile number validation processing ...<br /> Please wait.</b>
    </div>
  </div>
  <div id="app">
    <div class="main-wrapper main-wrapper-1">
      <div class="navbar-bg"></div>

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Create Group</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Create Group</div>
            </div>
          </div>

          <div class="section-body">
            <div class="row">
              <div class="col-12 col-md-12 col-lg-12">
                <div class="card">
                  <form class="needs-validation" novalidate="" id="frm_contact_group" name="frm_contact_group"
                    action="#" method="post" enctype="multipart/form-data">
                    <div class="card-body">

                      <div class="form-group mb-2 row" id="parliament_show" style="display: none;">
                        <label class="col-sm-3 col-form-label">Parliament<label style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="parliament" id='parliament' class="form-control" data-toggle="tooltip"
                            data-placement="top" title="" data-original-title="Select Parliament" tabindex="1" autofocus
                            onchange="getconstituency()">
                            <option value="" selected>Choose Parliament</option>
                          </select>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <div class="form-group mb-2 row" id="constituency_show" style="display:none">
                        <label class="col-sm-3 col-form-label">Constituency<label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="constituency" id='constituency' class="form-control" data-toggle="tooltip"
                            data-placement="top" title="" data-original-title="Select Constituency" tabindex="1"
                            autofocus>
                            <option value="" selected>Choose Constituency</option>
                          </select>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Whatsapp Sender ID <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <select name="txt_whatsapp_mobno" id='txt_whatsapp_mobno' class="form-control"
                            data-toggle="tooltip" data-placement="top" title=""
                            data-original-title="Select Whatsapp Sender ID" tabindex="1" autofocus>
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
                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Group Name <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip" data-original-title="">[?]</span></label>
                        <?
                        /* if ($_SESSION['yjwatsp_user_master_id'] == 3) {
                           $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
                           $curl = curl_init();
                           curl_setopt_array(
                             $curl,
                             array(
                               CURLOPT_URL => $api_url . '/group/group_latest_details', // Create a New Group
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
                                 "cache-control: no-cache",
                                 'Content-Type: application/json; charset=utf-8'
                               ),
                             )
                           );
                           $response = curl_exec($curl);
                           curl_close($curl);
                           $respobj = json_decode($response);
                           site_log_generate("Add Contacts in Group Page : User : " . $_SESSION['yjwatsp_user_name'] . " api response [$response] on " . date("Y-m-d H:i:s"), '../');

                           if ($response == '' || $respobj->response_status == 403) {
                             ob_clean(); // Clean the output buffer
                             header("Location: index");
                           } else if ($respobj->response_status == 200) { ?>
                               <div class="col-sm-7 id_new_groupname">
                                 <div id="id_new_groupname">
                                   <input type="text" name="txt_group_name" id='txt_group_name' tabindex="4"
                                     class="form-control" value="<?= $respobj->group_name ?>" maxlength="100"
                                     data-toggle="tooltip" data-placement="top" title="" readonly
                                     data-original-title="Enter Group Name">
                                 </div>
                               </div>
                           <? } else if ($respobj->response_status == 204 || $respobj->response_status == 201) { ?>
                                 <div class="col-sm-7 id_new_groupname">
                                   <div id="id_new_groupname">
                                     <input type="text" name="txt_group_name" id='txt_group_name' tabindex="4"
                                       class="form-control" value="" maxlength="100" placeholder="Enter Group Name"
                                       data-toggle="tooltip" data-placement="top" title=""
                                       data-original-title="Enter Group Name">
                                   </div>
                                 </div>
                           <? }
                         } else { */ ?>
                        <div class="col-sm-7 id_new_groupname">
                          <div id="id_new_groupname">
                            <input type="text" name="txt_group_name" id='txt_group_name' tabindex="4"
                              class="form-control" value="" maxlength="100" placeholder="Enter Group Name"
                              data-toggle="tooltip" data-placement="top" title=""
                              data-original-title="Enter Group Name">
                          </div>
                        </div>
                        <?/* }*/
                        ?>
                        <div class="col-sm-2"></div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Enter Mobile Numbers
                          (Comma Separated,Country Code Must Allowed) <label style="color:#FF0000">*</label> <span
                            data-toggle="tooltip"
                            data-original-title="Upload the Contact Downloaded CSV File Here or Enter contact Name">[?]</span>
                          <label style="color:#FF0000"></label></label>
                        <div class="col-sm-7">
                          <input type="text" name="txt_contact_name" id='txt_contact_name' tabindex="7"
                            class="form-control" value="" maxlength="1000" placeholder="Enter Contact Name"
                            data-toggle="tooltip" data-placement="top" title=""
                            onkeypress="return (event.charCode === 44 || (event.charCode >= 48 && event.charCode <= 57)) && this.value.length < 1000"
                            onchange="validateFile()"
                            data-original-title="Enter contact name and comma separated,country code must allowed"
                            style="margin-bottom: 10px;">

                          <input type="file" class="form-control" name="upload_contact" id='upload_contact' tabindex="7"
                            accept="text/csv" data-toggle="tooltip" data-placement="top" data-html="true" title=""
                            data-original-title="Upload the Contacts Mobile Number via CSV Files">
                          <label style="color:#FF0000">[Upload the Contacts Mobile Number via
                            CSV Files]</label>
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
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Invalids</span>
                            </label>
                          </div>
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to remove Stop Status Mobile No's">
                              <input type="checkbox" name="chk_remove_stop_status" id="chk_remove_stop_status" checked
                                value="remove_stop_status" tabindex="7" onclick="call_remove_duplicate_invalid()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Stop Status
                                Mobile
                                No's</span>
                            </label>
                          </div>

                          <div class="checkbox-fade fade-in-primary" id='id_mobupload'>

                          </div>
                        </div>
                      </div>
                    </div>
                    <? if ($respobj->response_status == 201 && $_SESSION['yjwatsp_user_master_id'] == 3) { ?>
                      <div class="card-footer text-center">
                        <span class="error_display" id='id_error_display'>Your latest group member
                          count is below 900. You
                          can create group once it's reached 900. </span><br>
                        <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                          value='contact_group' />
                      </div>
                    <? } else { ?>
                      <div class="card-footer text-center">
                        <span class="error_display" id='id_error_display'></span><br>
                        <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                          value='contact_group' />
                        <input type="submit" name="compose_submit" id="compose_submit" tabindex="8" value="Submit"
                          class="btn btn-success">
                      </div>
                    <? } ?>

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
          <h4 class="modal-title">Create & Add members</h4>
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
                <th scope="col" style="border: 1px solid #000;">Failure</th>
                <th scope="col" style="border: 1px solid #000;">Invalid</th>
                <th scope="col" style="border: 1px solid #000;">Duplicate</th>
                <th scope="col" style="border: 1px solid #000;">Exist</th>
              </tr>
              <!-- First row -->
              <tr style="border: 1px solid #000;">
                <th scope="row" style="border: 1px solid #000;">Create & Add Members</th>
                <td class="add_success" style="white-space: inherit !important;border: 1px solid #000;">
                </td>
                <td class="add_exist" style="white-space: inherit !important;border: 1px solid #000;">
                </td>
                <td class="add_invalid" style="white-space: inherit !important;border: 1px solid #000;">
                </td>
                <td class="add_duplicate" style="white-space: inherit !important;border: 1px solid #000;"></td>
                <td class="add_failure" style="white-space: inherit !important;border: 1px solid #000;">
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

  <!-- Confirmation details content-->
  <div class="modal" tabindex="-1" role="dialog" id="upload_file_popup">
    <div class="modal-dialog" role="document">
      <div class="modal-content" style="width: 400px;">
        <div class="modal-body">
          <button type="button" class="close" data-dismiss="modal" style="width:30px" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <p id="file_response_msg"></p>
          <span>Are you sure you want to Add Members and Create Group?</span>
        </div>
        <div class="modal-footer" style="margin-right:30%;">
          <button type="button" class="btn btn-danger" data-dismiss="modal">Yes</button>
          <button type="button" class="btn btn-secondary" data-dismiss="modal">No</button>
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
    window.onload = function () {
      var user_mas_id =
        <?php echo isset($_SESSION['yjwatsp_user_master_id']) ? $_SESSION['yjwatsp_user_master_id'] : 'null'; ?>;
      if (user_mas_id == 3) {
        $('#parliament_show').css("display", "flex")
        $('#constituency_show').css("display", "flex")
        // constituency_show
        getparliament();
        // document.getElementById('parliament_show').style.display = 'block';
      }
    };

    function getparliament() {
      var selectElement = document.getElementById("parliament");
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=getparliament",
        dataType: 'html',
        success: function (response) {
          var optionHTML = '<option value="" selected>Choose parliament</option>';
          selectElement.innerHTML = optionHTML;
          selectElement.innerHTML += response;
        },
        error: function (response, status, error) { } // Error
      });
    }


    function getconstituency() {
      var selectElement = document.getElementById("constituency");
      // Get the selected value from the select element
      var selectedValue = document.getElementById('parliament').value;
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=getconstituency&parliament_id=" + selectedValue,
        dataType: 'html',
        success: function (response) {
          var optionHTML = '<option value="" selected>Choose Constituency</option>';
          selectElement.innerHTML = optionHTML;
          selectElement.innerHTML += response;
        },
        error: function (response, status, error) { } // Error
      });
    }

    document.addEventListener('DOMContentLoaded', function () {
      var txt_group_name = document.getElementById('txt_group_name');
      // Add event listener for input events
      txt_group_name.addEventListener('input', function (event) {
        // Get the entered text
        var inputText = txt_group_name.value;
        // Define a regular expression pattern to match the `˜` character
        var tildeRegex = /['"`]/g;
        // Test if the entered text contains the `˜` character
        if (tildeRegex.test(inputText)) {
          // Remove the `˜` character from the text
          txt_group_name.value = inputText.replace(tildeRegex, '');
        }
      });
    });

    $("#id_checkAll").click(function () {
      $('input:checkbox').not(this).prop('checked', this.checked);
    });

    $(function () {
      $('.theme-loader').fadeOut("slow");
      func_open_newex_group('N');
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

    function func_open_newex_group(group_available) {
      var group_avail = $("input[type='radio'][name='rdo_newex_group']:checked").val();
      if (group_avail == 'N') {
        $("#frm_contact_group").removeClass("was-validated");
        $('#txt_contact_name').css({
          borderColor: ''
        });
        $('#upload_contact').css({
          borderColor: ''
        });
        $('#txt_group_name_ex').val('');
        $('.id_new_groupname').css({
          display: ''
        });
        $('.id_ex_groupname').css("display", "none")
      } else if (group_avail == 'E') {
        $('#txt_contact_name').css({
          borderColor: ''
        });
        $('#upload_contact').css({
          borderColor: ''
        });
        $("#frm_contact_group").removeClass("was-validated");
        $('#txt_group_name').val('');
        $('.id_ex_groupname').css({
          display: ''
        })
        $('.id_new_groupname').css("display", "none");
      }
    }

    // function init() {
    //   // document.getElementById('upload_contact').addEventListener('change', handleFileSelect, false);
    // }

    // function handleFileSelect(event) {
    //   var flenam = document.querySelector('#upload_contact').value;
    //   var extn = flenam.split('.').pop();

    //   if (extn == 'xlsx' || extn == 'xls') {
    //     ExportToTable();
    //   } else {
    //     const reader = new FileReader()
    //     reader.onload = handleFileLoad;
    //     reader.readAsText(event.target.files[0])
    //   }
    // }

    // function handleFileLoad(event) {
    //   console.log(event);
    //   $('#txt_list_mobno').val(event.target.result);
    //   $('#txt_list_mobno').focus();
    // }

    // var value_list = new Array; ///this one way of declaring array in javascript
    // function ExportToTable() {
    //   var regex = /^([a-zA-Z0-9\s_\\.\-:])+(.xlsx|.xls)$/;
    //   /*Checks whether the file is a valid excel file*/
    //   if (regex.test($("#upload_contact").val().toLowerCase())) {
    //     var xlsxflag = false; /*Flag for checking whether excel is .xls format or .xlsx format*/
    //     if ($("#upload_contact").val().toLowerCase().indexOf(".xlsx") > 0) {
    //       xlsxflag = true;
    //     }
    //     /*Checks whether the browser supports HTML5*/
    //     if (typeof (FileReader) != "undefined") {
    //       var reader = new FileReader();
    //       reader.onload = function (e) {
    //         var data = e.target.result;
    //         /*Converts the excel data in to object*/
    //         if (xlsxflag) {
    //           var workbook = XLSX.read(data, {
    //             type: 'binary'
    //           });
    //         } else {
    //           var workbook = XLS.read(data, {
    //             type: 'binary'
    //           });
    //         }
    //         /*Gets all the sheetnames of excel in to a variable*/
    //         var sheet_name_list = workbook.SheetNames;

    //         var cnt = 0; /*This is used for restricting the script to consider only first sheet of excel*/
    //         sheet_name_list.forEach(function (y) {
    //           /*Convert the cell value to Json*/
    //           if (xlsxflag) {
    //             var exceljson = XLSX.utils.sheet_to_json(workbook.Sheets[y]);
    //           } else {
    //             var exceljson = XLS.utils.sheet_to_row_object_array(workbook.Sheets[y]);
    //           }
    //           if (exceljson.length > 0 && cnt == 0) {
    //             BindTable(exceljson, '#txt_list_mobno');
    //             cnt++;
    //           }
    //         });
    //         $('#txt_list_mobno').show();
    //         $('#txt_list_mobno').focus();
    //       }
    //       if (xlsxflag) {
    //         /*If excel file is .xlsx extension than creates a Array Buffer from excel*/
    //         reader.readAsArrayBuffer($("#upload_contact")[0].files[0]);
    //       } else {
    //         reader.readAsBinaryString($("#upload_contact")[0].files[0]);
    //       }
    //     } else {
    //       alert("Sorry! Your browser does not support HTML5!");
    //     }
    //   } else {
    //     alert("Please upload a valid Excel file!");
    //   }
    // }

    // function BindTable(jsondata, tableid) {
    //   /*Function used to convert the JSON array to Html Table*/
    //   var columns = BindTableHeader(jsondata, tableid); /*Gets all the column headings of Excel*/
    //   for (var i = 0; i < jsondata.length; i++) {
    //     for (var colIndex = 0; colIndex < columns.length; colIndex++) {
    //       var cellValue = jsondata[i][columns[colIndex]];
    //       if (cellValue == null)
    //         cellValue = "";
    //       value_list.push("\n" + cellValue);
    //     }
    //   }btn-success
    //   $(tableid).val(value_list);
    // }

    // function BindTableHeader(jsondata, tableid) {
    //   /*Function used to get all column names from JSON and bind the html table header*/
    //   var columnSet = [];
    //   for (var i = 0; i < jsondata.length; i++) {
    //     var rowHash = jsondata[i];
    //     for (var key in rowHash) {
    //       if (rowHash.hasOwnProperty(key)) {
    //         if ($.inArray(key, columnSet) == -1) {
    //           /*Adding each unique column names to a variable array*/
    //           columnSet.push(key);
    //           value_list.push("\n" + key);
    //         }
    //       }
    //     }
    //   }
    //   return columnSet;
    // }

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

    $(document).on("submit", "form#frm_contact_group", function (e) {
      e.preventDefault();
      $('#compose_submit').prop('disabled', false);
      console.log("View Submit Pages");
      console.log("came Inside");
      $("#id_error_display").html("");
      $('#txt_group_name').css('border-color', '#a0a0a0');
      $('#txt_whatsapp_mobno').css('border-color', '#a0a0a0');
      $('#upload_contact').css('border-color', '#a0a0a0');
      $('#txt_contact_name').css('border-color', '#a0a0a0');
      $('#txt_group_name_ex').css('border-color', '#a0a0a0');

      //get input field values 
      var txt_group_name = $('#txt_group_name').val();
      var slt_group = $('#slt_group').val();
      var upload_contact = $('#upload_contact').val();
      var txt_contact_name = $('#txt_contact_name').val();
      var group_avail = $("input[type='radio'][name='rdo_newex_group']:checked").val();

      var flag = true;
      /********validate all our form fields***********/

      var parliament = document.getElementById('parliament');
      var parliament_show = document.getElementById('parliament_show');

      var parliament_value = parliament.value;
      if (isElementVisible(parliament_show) && parliament_value == "") {
        // $("#id_error_display").html("Please select parliament");
        $('#parliament').css('border-color', 'red');
        flag = false;
      }

      var constituency = document.getElementById('constituency');
      var constituency_show = document.getElementById('constituency_show');

      var constituency_value = constituency.value;
      if (isElementVisible(constituency_show) && constituency_value == "") {
        // $("#id_error_display").html("Please select parliament");
        $('#constituency').css('border-color', 'red');
        flag = false;
      }


      function isElementVisible(element) {
        return element.style.display !== 'none';
      }


      var sender_id = document.getElementById('txt_whatsapp_mobno');

      var sender_id_value = sender_id.value;

      if (txt_group_name.trim() == "") {
        $('#txt_group_name').css('border-color', 'red');
        flag = false;
      }


      if (sender_id_value == "") {
        $('#txt_whatsapp_mobno').css('border-color', 'red');
        flag = false;
      }
      /* upload_contact field validation  */
      if (upload_contact == "" && txt_contact_name == "") {
        $('#upload_contact').css('border-color', 'red');
        $('#txt_contact_name').css('border-color', 'red');
        flag = false;
      }

      <?
      if ($_REQUEST['group'] == '') {
        ?>
        if (upload_contact != "" && txt_contact_name != "") {
          $('#txt_contact_name').val('');
        } <?
      } ?>

      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        var fd = new FormData(this);
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
              $('#upload_contact').val('');
              $('#compose_submit').attr('disabled', false);
              $('#id_submit_composercs').attr('disabled', false);
              $("#id_error_display").html(response_obj.msg);
            } else if (response_obj.status == 2) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response_obj.msg);
              $('#compose_submit').attr('disabled', false);
            } else if (response_obj.status == 1) {
              // Check if the properties exist before accessing their length
              const successValue = msg_obj.success && msg_obj.success.length > 0 ? msg_obj.success.join(', ') : '-';
              console.log(successValue);
              $('.add_success').text(successValue);
              const failureValue = msg_obj.failure && msg_obj.failure.length > 0 ? msg_obj.failure.join(', ') : '-';
              $('.add_failure').text(failureValue);
              const invalidValue = msg_obj.invalid && msg_obj.invalid.length > 0 ? msg_obj.invalid.join(', ') : '-';
              $('.add_invalid').text(invalidValue);
              const duplicateValue = msg_obj.duplicate && msg_obj.duplicate.length > 0 ? msg_obj.duplicate.join(', ') : '-';
              $('.add_duplicate').text(duplicateValue);
              const existValue = msg_obj.exist && msg_obj.exist.length > 0 ? msg_obj.exist.join(', ') : '-';
              $('.add_exist').text(existValue);
              $('#default-Modal').modal('show');
              $('#compose_submit').attr('disabled', false);
              $('#default-Modal').on('hidden.bs.modal', function (e) {
                window.location = 'group_summary';
              });
              setInterval(function () {
              }, 5000);
              $("#id_error_display").html("Contacts Created Successfully..");
            }
            $('.theme-loader').hide();
          },
          error: function (response, status, error) {
            console.log("FAL");
            $('#txt_group_name').val('');
            $('#upload_contact').val('');
            $('#compose_submit').attr('disabled', false);
            $('#id_submit_composercs').attr('disabled', false);
            $('.theme-loader').show();
            window.location = 'index';
            $("#id_error_display").html(response.msg);
          }
        });
      }
    });


    function validateFile() {
      var input = document.getElementById('upload_contact');
      var file = input.files[0];
      console.log(file);
      var allowedExtensions = /\.csv$/i;
      var maxSizeInBytes = 100 * 1024 * 1024; // 100MB
      if (!allowedExtensions.test(file.name)) {
        document.getElementById('id_error_display').innerHTML = 'Invalid file type. Please select an .csv file.';
        input.value = ''; // Clear the file input
      } else if (file.size > maxSizeInBytes) {
        document.getElementById('id_error_display').innerHTML = 'File size exceeds the maximum limit (100MB).';
        input.value = ''; // Clear the file input
      } else {
        document.getElementById('id_error_display').innerHTML = ''; // Clear any previous error message
        readFileContents(file);
      }
    }

    function validateNumber(number) {
      return /^91[6-9]\d{9}$/.test(number);
    }
    function readFileContents(file) {
      $('.preloader-wrapper').show();
      var reader = new FileReader();
      reader.onload = function (event) {
        var contents = event.target.result;
        var workbook = XLSX.read(contents, {
          type: 'binary'
        });
        var firstSheetName = workbook.SheetNames[0];
        var worksheet = workbook.Sheets[firstSheetName];
        var data = XLSX.utils.sheet_to_json(worksheet, {
          header: 1
        });
        //array values get in invalids,dublicates
        var invalidValues = [];
        var duplicateValuesInColumnA = [];
        var uniqueValuesInColumnA = new Set();

        for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
          var valueA = data[rowIndex][0]; // Assuming column A is at index 0
          if (!validateNumber(valueA)) {
            console.log(valueA + "invalid");
            invalidValues.push(valueA);
          } else if (uniqueValuesInColumnA.has(valueA)) {
            duplicateValuesInColumnA.push(valueA);
            console.log(valueA + "duplicate")
          } else {
            console.log(valueA + "valid")
            uniqueValuesInColumnA.add(valueA);
          }
        }
        var totalCount = data.length - 1;

        if (invalidValues.length > 0 && duplicateValuesInColumnA.length > 0) {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Invalid Numbers: \n' + JSON.stringify(invalidValues.length) + '\n Duplicate Numbers: \n' + JSON.stringify(duplicateValuesInColumnA.length) + '</b>');
          // Add a click event handler to the modal's backdrop (outside the modal)
          $('body').on('click', function (e) {
            // Check if the click target is outside of the modal
            if (!$('#upload_file_popup').is(e.target) && $('#upload_file_popup').has(e.target).length === 0) {
              // Close the modal if the click is outside
              $('#upload_file_popup').modal('hide');
            }
          });
        } else if (duplicateValuesInColumnA.length > 0) {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Duplicate Numbers : \n' + JSON.stringify(duplicateValuesInColumnA.length) + '</b>');
          // Add a click event handler to the modal's backdrop (outside the modal)
          $('body').on('click', function (e) {
            // Check if the click target is outside of the modal
            if (!$('#upload_file_popup').is(e.target) && $('#upload_file_popup').has(e.target).length === 0) {
              // Close the modal if the click is outside
              $('#upload_file_popup').modal('hide');
            }
          });
        } else if (invalidValues.length > 0) {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Invalid Numbers : \n' + JSON.stringify(invalidValues.length) + '</b>');
          // Add a click event handler to the modal's backdrop (outside the modal)
          $('body').on('click', function (e) {
            // Check if the click target is outside of the modal
            if (!$('#upload_file_popup').is(e.target) && $('#upload_file_popup').has(e.target).length === 0) {
              // Close the modal if the click is outside
              $('#upload_file_popup').modal('hide');
            }
          });
        } else {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
        }
      };
      reader.readAsBinaryString(file);
    }
    $('#upload_file_popup').find('.btn-secondary').on('click', function () {
      $('#upload_contact').val('');
    });

  </script>
</body>

</html>