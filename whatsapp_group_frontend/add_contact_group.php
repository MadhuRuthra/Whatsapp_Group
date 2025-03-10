<?php
session_start();
error_reporting(0);
include_once('api/configuration.php');
extract($_REQUEST);

if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
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
  <title>Add Contacts in Group ::
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
            <h1>Add Contacts in Group</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Add Contacts in Group</div>
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
                        <label class="col-sm-3 col-form-label">Whatsapp Sender ID <label
                            style="color:#FF0000">*</label></label>
                        <div class="col-sm-7">
                          <?
                          $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
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
                              CURLOPT_SSL_VERIFYPEER => 0,
                              CURLOPT_CUSTOMREQUEST => 'GET',
                              CURLOPT_HTTPHEADER => array(
                                $bearer_token,
                                'Content-Type: application/json'
                              ),
                            )
                          );
                          site_log_generate("Add Contacts in Group Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the get sender id service on " . date("Y-m-d H:i:s"));
                          $response = curl_exec($curl);
                          curl_close($curl);

                          $state1 = json_decode($response, false);
                          site_log_generate("Add Contacts in Group Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"));
                          ?>
                          <table style="width: 100%;">
                            <!-- <input type="checkbox" checked class="cls_checkbox" id="id_checkAll" name="id_checkAll" tabindex="1" value=""> Select / Deselect All -->
                            <? $counter = 0;
                            if ($state1->response_status == 403) { ?>
                              <script>window.location = "logout"</script>
                            <? }

                            $firstid = 0;
                            if ($state1->response_status == 200) {
                              for ($indicator = 0; $indicator < count($state1->sender_id); $indicator++) {
                                if ($state1->sender_id[$indicator]->senderid_master_status == 'Y') {
                                  if ($counter % 2 == 0) { ?>
                                    <tr>
                                    <? } ?>
                                    <td>
                                      <input type="radio" <? if ($counter == 0 or $_REQUEST['sender'] == $state1->sender_id[$indicator]->mobile_no) {
                                        $firstid = $state1->sender_id[$indicator]->mobile_no; ?>checked<? } ?>
                                        onclick="func_change_groupname('<?= $state1->sender_id[$indicator]->mobile_no ?>')"
                                        class="cls_checkbox" id="txt_whatsapp_mobno_<?= $indicator ?>"
                                        name="txt_whatsapp_mobno" tabindex="1" autofocus
                                        value="<?= $state1->sender_id[$indicator]->mobile_no ?>">
                                      <label class="form-label">
                                        <?= $state1->sender_id[$indicator]->mobile_no ?>
                                      </label>
                                    </td>
                                    <?
                                    if ($counter % 2 == 1) { ?>
                                    </tr>
                                  <? }
                                    $counter++;
                                }
                              }
                            }
                            ?>
                          </table>
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Group <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="Choose New or Existing Group">[?]</span></label>
                        <div class="col-sm-7">
                          <input type="radio" name="rdo_newex_group" id="rdo_new_group" checked tabindex="2" value="N"
                            onclick="func_open_newex_group('N')"> New Group&nbsp;&nbsp;&nbsp;<input type="radio"
                            name="rdo_newex_group" id="rdo_ex_group" tabindex="3" value="E" <? if ($_SERVER["QUERY_STRING"] != '') { ?> checked <? } ?>onclick="func_open_newex_group('E')">
                          Existing Group
                        </div>
                        <div class="col-sm-2">
                        </div>
                      </div>

                      <div class="form-group mb-2 row">
                        <label class="col-sm-3 col-form-label">Group Name <label style="color:#FF0000">*</label>
                          <span data-toggle="tooltip"
                            data-original-title="If New Group, then Enter the Group Name. If Existing Group, then Choose the Group Name">[?]</span></label>
                        <div class="col-sm-7 id_new_groupname">
                          <div id="id_new_groupname" <? if ($_SERVER["QUERY_STRING"] != '') { ?> style="display: none" <? } else { ?> style="display: block" <? } ?>>
                            <input type="text" name="txt_group_name" id='txt_group_name' tabindex="4"
                              class="form-control" value="" <? /*if($_REQUEST["group"] == '') { ?> required="" <? }*/?>
                              maxlength="250" placeholder="Enter Group Name" data-toggle="tooltip" data-placement="top"
                              title="" data-original-title="Enter Group Name">
                          </div>
                        </div>

                        <div class="col-sm-7 row id_ex_groupname" style="display: none">
                          <div class="col-6" id="id_ex_groupname">
                            <select id="slt_group" name="slt_group" class="form-control" tabindex="5">

                              <?
                              $replace_txt = '{
                                "sender_id" : "' . $firstid . '"
                              }';
                              $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
                              $curl = curl_init();
                              curl_setopt_array(
                                $curl,
                                array(
                                  CURLOPT_URL => $api_url . '/list/sender_id_groups',
                                  CURLOPT_RETURNTRANSFER => true,
                                  CURLOPT_ENCODING => '',
                                  CURLOPT_MAXREDIRS => 10,
                                  CURLOPT_TIMEOUT => 0,
                                  CURLOPT_FOLLOWLOCATION => true,
                                  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                                  CURLOPT_SSL_VERIFYPEER => 0,
                                  CURLOPT_CUSTOMREQUEST => 'GET',
                                  CURLOPT_POSTFIELDS => $replace_txt,
                                  CURLOPT_HTTPHEADER => array(
                                    $bearer_token,
                                    'Content-Type: application/json'
                                  ),
                                )
                              );

                              site_log_generate("Add Contact Group Page : " . $uname . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                              $response = curl_exec($curl);
                              curl_close($curl);

                              $state1 = json_decode($response, false);
                              site_log_generate("Add Contact Group Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"));

                              if ($state1->response_status == 403) { ?>
                                <script>window.location = "logout"</script>
                              <? }

                              if ($state1->response_status == 200) {
                                $exgroup_name = ''; ?>
                                <option value="">Choose Group Name</option>
                                <? for ($indicator = 0; $indicator < count($state1->group_list); $indicator++) {
                                  if ($exgroup_name != $state1->group_list[$indicator]->group_name) {
                                    $group_name = $state1->group_list[$indicator]->group_name;
                                    $group_contact_id = $state1->group_list[$indicator]->group_master_id; ?>
                                    <option value="<?= $group_name ?>" <? /* if ($indicator == 0 or $_REQUEST["group"] == $group_master_id) { echo "selected"; } */?>>
                                      <?= $group_name ?>
                                    </option>
                                  <?php }
                                  $exgroup_name = $state1->group_list[$indicator]->group_name;
                                }
                              }
                              ?>
                            </select>
                          </div>
                          <div class="col-6">
                            <input type="text" name="txt_group_name_ex" id='txt_group_name_ex' tabindex="4"
                              class="form-control" value="" maxlength="250" placeholder="Enter Group Name"
                              data-toggle="tooltip" data-placement="top" title=""
                              data-original-title="Enter Group Name">
                          </div>
                        </div>
                        <div class="col-sm-2"></div>
                      </div>

                      <? /* <div class="form-group mb-2 row">
                    <label class="col-sm-3 col-form-label">Campaign Name <label style="color:#FF0000">*</label>
                      <span data-toggle="tooltip"
                        data-original-title="Enter Campaign Name">[?]</span></label>
                    <div class="col-sm-7">
                      <input type="text" name="txt_campaign_name" id='txt_campaign_name' tabindex="4" class="form-control"
                        value="" required="" maxlength="30" placeholder="Enter Campaign Name" data-toggle="tooltip" data-placement="top" title=""
                        data-original-title="Enter Campaign Name">
                    </div>
                    <div class="col-sm-2">
                    </div>
                  </div> */?>

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
                            data-original-title="Enter contact name and comma separated,country code must allowed"
                            style="margin-bottom: 10px;">

                          <input type="file" class="form-control" name="upload_contact" id='upload_contact' tabindex="7"
                            accept="text/csv" data-toggle="tooltip" data-placement="top" data-html="true" title=""
                            data-original-title="Upload the Contacts Mobile Number via CSV Files"> <label
                            style="color:#FF0000">[Upload the Contacts Mobile Number via CSV Files]</label>
                        </div>
                        <div class="col-sm-2">
                          <div class="checkbox-fade fade-in-primary" style="display: none;">
                            <label data-toggle="tooltip" data-placement="top" data-html="true" title=""
                              data-original-title="Click here to Remove the Duplicates">
                              <input type="checkbox" name="chk_remove_duplicates" id="chk_remove_duplicates" checked
                                value="remove_duplicates" tabindex="7" onclick="call_remove_duplicate_invalid()">
                              <span class="cr"><i class="cr-icon icofont icofont-ui-check txt-primary"></i></span>
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Duplicates</span>
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
                              <span class="text-inverse" style="color:#FF0000 !important">Remove Stop Status Mobile
                                No's</span>
                            </label>
                          </div>

                          <div class="checkbox-fade fade-in-primary" id='id_mobupload'>

                          </div>
                        </div>
                      </div>

                    </div>
                    <div class="card-footer text-center">
                      <span class="error_display" id='id_error_display'></span><br>
                      <input type="hidden" class="form-control" name='tmpl_call_function' id='tmpl_call_function'
                        value='contact_group' />
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

  <!-- Confirmation details content Reject-->
  <div class="modal" tabindex="-1" role="dialog" id="plan-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Confirmation details</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p style="font-size:20px;">The current WhatsApp availability count has exceeded the limit. To accommodate
            additional users, consider upgrading your plans and creating a new group.</p>
        </div>
        <div class="modal-footer">
          <span class="error_display" id='id_error_reject'></span>
          <button type="button" class="btn btn-success remove_btn button" data-dismiss="model">Remove</button>
          <button type="button" class="btn btn-secondary button" data-dismiss="modal">Cancel</button>
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

    $(document).ready(function () {
      <? if ($_SESSION['yjwatsp_user_master_id'] != '1') { ?>
        plan_details_list();
      <? } ?>

    });

    // To Display the Whatsapp NO List
    function plan_details_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=plans_details",
        dataType: 'html',
        success: function (response) { // Success
          console.log("Response value:", response);
          console.log("Response type:", typeof response);
          var trimmedResponse = response.trim();
          if (!trimmedResponse) {
            console.log("Inside else block");
            $('#plan-Modal').modal({ show: false });
          } else {
            console.log("Inside if block");
            $('#plan-Modal').modal({ show: true });
            setTimeout(function () {
              window.location = "pricing_plan";
            }, 4000);
          }
        },
        error: function (response, status, error) { } // Error
      });
    }

    $("#id_checkAll").click(function () {
      $('input:checkbox').not(this).prop('checked', this.checked);
    });

    $(function () {
      $('.theme-loader').fadeOut("slow");
      init();
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
        $('#txt_contact_name').css({ borderColor: '' });
        $('#upload_contact').css({ borderColor: '' });
        $('#txt_group_name_ex').val('');
        $('.id_new_groupname').css({ display: '' });
        $('.id_ex_groupname').css("display", "none")
        // $('#txt_group_name').prop("required", true);
      } else if (group_avail == 'E') {
        $('#txt_contact_name').css({ borderColor: '' });
        $('#upload_contact').css({ borderColor: '' });
        $("#frm_contact_group").removeClass("was-validated");
        $('#txt_group_name').val('');
        $('.id_ex_groupname').css({ display: '' })
        $('.id_new_groupname').css("display", "none");
        // $('#txt_group_name').prop("required", false);
      }
    }
    function init() {
      // document.getElementById('upload_contact').addEventListener('change', handleFileSelect, false);
    }

    function handleFileSelect(event) {
      var flenam = document.querySelector('#upload_contact').value;
      var extn = flenam.split('.').pop();

      if (extn == 'xlsx' || extn == 'xls') {
        ExportToTable();
      } else {
        const reader = new FileReader()
        reader.onload = handleFileLoad;
        reader.readAsText(event.target.files[0])
      }
    }

    function handleFileLoad(event) {
      console.log(event);
      $('#txt_list_mobno').val(event.target.result);
      $('#txt_list_mobno').focus();
    }

    var value_list = new Array; ///this one way of declaring array in javascript
    function ExportToTable() {
      var regex = /^([a-zA-Z0-9\s_\\.\-:])+(.xlsx|.xls)$/;
      /*Checks whether the file is a valid excel file*/
      if (regex.test($("#upload_contact").val().toLowerCase())) {
        var xlsxflag = false; /*Flag for checking whether excel is .xls format or .xlsx format*/
        if ($("#upload_contact").val().toLowerCase().indexOf(".xlsx") > 0) {
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
            reader.readAsArrayBuffer($("#upload_contact")[0].files[0]);
          } else {
            reader.readAsBinaryString($("#upload_contact")[0].files[0]);
          }
        } else {
          alert("Sorry! Your browser does not support HTML5!");
        }
      } else {
        alert("Please upload a valid Excel file!");
      }
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
        data: { validateMobno: 'validateMobno', mobno: txt_list_mobno, dup: chk_remove_duplicates, inv: chk_remove_invalids },
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
      var txt_header_name_length = $('#txt_group_name_ex').val().length;
      e.preventDefault();
      $('#compose_submit').prop('disabled', false);
      console.log("View Submit Pages");
      console.log("came Inside");

      $("#id_error_display").html("");
      $('#txt_group_name').css('border-color', '#a0a0a0');
      $('#slt_group').css('border-color', '#a0a0a0');
      $('#upload_contact').css('border-color', '#a0a0a0');
      $('#txt_contact_name').css('border-color', '#a0a0a0');
      $('#txt_group_name_ex').css('border-color', '#a0a0a0');
      //get input field values 
      var txt_group_name = $('#txt_group_name').val();
      var slt_group = $('#slt_group').val();
      var upload_contact = $('#upload_contact').val();
      var txt_contact_name = $('#txt_contact_name').val();
      //var txt_group_name_ex = $('#txt_group_name_ex').val();
      var group_avail = $("input[type='radio'][name='rdo_newex_group']:checked").val();

      var flag = true;
      /********validate all our form fields***********/
      if (group_avail == 'N') {
        if (txt_group_name == "") {
          $('#txt_group_name').css('border-color', 'red');
          flag = false;
        }
      } else if (group_avail == 'E') {
        if (slt_group == "" && txt_group_name_ex.length <= 0) {
          $('#slt_group').css('border-color', 'red');
          $('#txt_group_name_ex').css('border-color', 'red');
          flag = false;
        }
        //else if (txt_group_name_ex.length <= 0){
        //$('#txt_group_name_ex').css('border-color', 'red');
        //          flag = false;

        //}
      }
      /* upload_contact field validation  */
      if (upload_contact == "" && txt_contact_name == "") {
        $('#upload_contact').css('border-color', 'red');
        $('#txt_contact_name').css('border-color', 'red');
        flag = false;
      }

      <? if ($_REQUEST['group'] == '') { ?>
        if (upload_contact != "" && txt_contact_name != "") {
          $('#txt_contact_name').val('');
          //flag = true;
        }
      <? } ?>

      /* If all are ok then we send ajax request to ajax/master_call_functions.php *******/
      if (flag) {
        var fd = new FormData(this);
        // exit();
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
            // exit;
            console.log("SUCC");
            if (response.status == '0') {
              $('#txt_group_name').val('');
              $('#upload_contact').val('');
              $('#compose_submit').attr('disabled', false);
              $('#id_submit_composercs').attr('disabled', false);
              $("#id_error_display").html(response.msg);
            } else if (response.status == 2) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html(response.msg);
              $('#compose_submit').attr('disabled', false);
            } else if (response.status == 1) {
              $('#compose_submit').attr('disabled', false);
              $("#id_error_display").html("Contacts Created Successfully..");
              window.location = 'group_list';
            }
            $('.theme-loader').hide();
          },
          error: function (response, status, error) {
            // die;
            console.log("FAL");
            $('#txt_group_name').val('');
            $('#upload_contact').val('');
            $('#compose_submit').attr('disabled', false);
            $('#id_submit_composercs').attr('disabled', false);
            $('.theme-loader').show();
            //     window.location = 'add_contact_group';
            $("#id_error_display").html(response.msg);
          }
        });
      }
    });
  </script>
</body>

</html>
