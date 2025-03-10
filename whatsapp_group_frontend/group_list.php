<?php
/*
Authendicated users only allow to view this Manage Sender ID page.
This page is used to Add List the Sender ID and its Status.
Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table

Version : 1.0
Author : Arun Rama Balan.G (YJ0005)
Date : 07-Jul-2023
*/

session_start(); // To start session
error_reporting(0); // The error reporting function

include_once('api/configuration.php'); //  Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Group List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Group List ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <script src="assets/js/multiselect-dropdown.js"></script>

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/searchPanes.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/select.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/colReorder.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/buttons.dataTables.min.css">

  <!-- <script src="/scripts/snippet-javascript-console.min.js?v=1"></script> -->
  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/loader.css">
  <link rel="stylesheet" href="assets/css/components.css">
</head>
<style>
  .dataTables_filter label,
  .previous,
  .next {
    font-weight: bolder;
  }

  .modal-body {
    /*max-height: 120px; Adjust this value as needed */
    /* overflow-y: auto; */
    /* Enable vertical scrollbar when content overflows */
  }

  #id_manage_group_list {
    position: relative;
    height: 1000px;
  }

  .multiselect-dropdown {
    width: 300px !important;
  }

  .theme-loader {
    display: block;
    position: fixed;
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

  .dropdown-list {
    height: 300px;
  }
</style>

<body>
  <div class="loading" style="display:none;">Loading&#8230;</div>
  <!-- <div class="theme-loader">
  </div> -->
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

      <!-- include header function adding -->
      <? include("libraries/site_header.php"); ?>

      <!-- include sitemenu function adding -->
      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <!-- Title & Breadcrumb Panel -->
          <div class="section-header">
            <h1>Group List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="add_contact_group">Add Group Contact</a></div>
              <div class="breadcrumb-item">Group List</div>
            </div>
          </div>

          <!-- Add Group Contact Panel -->
          <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="add_contact_group" class="btn btn-success"><i class="fas fa-plus"></i>
                  Add Group Contact</a></h4>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_manage_group_list"> <!-- List from API -->
                      Loading ..
                    </div>
                  </div>
                </div>
              </div>
            </div>


          </div>
        </section>
      </div>

      <!-- Footer Panel -->
      <? include("libraries/site_footer.php"); ?>

    </div>
  </div>

  <!-- Confirmation details content Reject-->
  <div class="modal" tabindex="-1" role="dialog" id="reject-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Group Members </h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <h2 class="info" style="display:none;text-align:center;"> </h2>
          <form class="needs-validation" novalidate="" id="frm_sender_id" name="frm_sender_id" action="#" method="post"
            enctype="multipart/form-data" style="max-height:500px; ">
            <div class="dropdown-container" name="slt_drop_down" onclick="disableElement1('upload_contact')">
              <div class="dropdown-button noselect">
                <div class="dropdown-label">Select Numbers:</div>
                <div class="dropdown-quantity"></div>
              </div>
              <div class="dropdown-list">
                <input type="search" placeholder="Search states" class="dropdown-search"><br>
                <label><input id="select-all-states" type="checkbox">Select All</label>
                <ul class="test">
                </ul>
              </div>
            </div></br>
            <!--  //dropdown contanter -->

            <div class="form-group mb-2 row upload" >
              <label class="col-sm-4 col-form-label">Upload Numbers </label>
              <div class="col-sm-8">
                <input type="file" class="form-control" name="upload_contact" id='upload_contact' tabindex="7"
                  accept="text/csv" onchange="validateFile()" onclick="disableElement2('slt_drop_down')"
                  data-toggle="tooltip" data-placement="top" data-html="true" title=""
                  data-original-title="Upload the Contacts Mobile Number via CSV Files">
                <label style="color:#FF0000;margin-top:5px;" >[ Upload
                  the Contacts Mobile Number via CSV Files ]</label>
              </div>
            </div>
            <br>
            <div class="form-group mb-2 row reason" >
              <label class="col-sm-4 col-form-label">Reason <label style="color:#FF0000">*</label></label>
              <div class="col-sm-8">
                <input class="form-control form-control-primary" type="text" name="reject_reason" id="reject_reason"
                  maxlength="50" minlength="3" title="Reason to remove" tabindex="12" placeholder="Reason to remove">
              </div>
            </div>

          </form>
        </div>
        <br>


        <p class="msg_content" style="margin-left:30px;">Are you sure you want to Remove the contact ?</p>

        <div class="modal-footer" style="margin-top:100px;">
          <span class="error_display" id='id_error_reject'></span>
          <button type="button" class="btn btn-success remove_btn button" data-dismiss="model">Remove</button>
          <button type="button" class="btn btn-secondary button" data-dismiss="modal">Cancel</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Confirmation details content Reject-->
  <div class="modal" tabindex="-1" role="dialog" id="qrcode-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">QR Code</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <div id="qrcode"></div>
        </div>
        <div class="modal-footer">
          <span class="error_display" id="id_error_reject"></span>
          <button type="button" class="btn btn-success remove_btn button" onclick="downloadImage()">Download</button>
          <button type="button" class="btn btn-secondary button" data-dismiss="modal">Cancel</button>
        </div>
      </div>
    </div>
  </div>

  <!-- Confirmation details content File Upload-->
  <div class="modal" tabindex="-1" role="dialog" id="upload_file_popup">
    <div class="modal-dialog" role="document">
      <div class="modal-content" style="width: 400px;">
        <div class="modal-body">
          <button type="button" class="close" data-dismiss="modal" style="width:30px" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <p id="file_response_msg"></p>
          <span class="ex_msg">Are you sure you want to create a campaign?</span>
        </div>
        <div class="modal-footer file_valid" style="margin-right:30%;">
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
  <script src="assets/js/xlsx.full.min.js"></script>
  <!-- JS Libraies -->
  <!-- Page Specific JS File -->
  <!-- Template JS File -->
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>
  <script src="assets/js/jquery.dataTables.min.js"></script>
  <script src="assets/js/dataTables.buttons.min.js"></script>
  <script src="assets/js/dataTables.searchPanes.min.js"></script>
  <script src="assets/js/dataTables.select.min.js"></script>
  <script src="assets/js/jszip.min.js"></script>
  <script src="assets/js/pdfmake.min.js"></script>
  <script src="assets/js/vfs_fonts.js"></script>
  <script src="assets/js/buttons.html5.min.js"></script>
  <script src="assets/js/buttons.colVis.min.js"></script>
  <script type="text/javascript" defer>

    // On loading the page, this function will call
    $(document).ready(function () {
      manage_group_list();
    });

    // To Display the Whatsapp NO List
    function manage_group_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=manage_group_list",
        dataType: 'html',
        success: function (response) { // Success
          $("#id_manage_group_list").html(response);
        },
        error: function (response, status, error) { } // Error
      });
    }
    // setInterval(manage_group_list, 60000); // Every 1 min (60000), it will call

    function validateFile() {
      var input = document.getElementById('upload_contact');
      var file = input.files[0];
      var allowedExtensions = /\.csv$/i;
      var maxSizeInBytes = 100 * 1024 * 1024; // 100MB
      if (!allowedExtensions.test(file.name)) {
        $("#id_error_display").html("Invalid file type. Please select an .csv file.");
        document.getElementById('upload_contact').value = ''; // Clear the file input

      } else if (file.size > maxSizeInBytes) {
        $("#id_error_display").html("File size exceeds the maximum limit (100MB).");
        document.getElementById('upload_contact').value = '';// Clear the file input
      } else {
        $("#id_error_display").html("");// Clear any previous error message
        readFileContents(file);
      }

    }

    function validateNumber(number) {
      return /^91[6-9]\d{9}$/.test(number);
    }

    function readFileContents(file) {
      // Your regular expression pattern
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
        // array values get in invalids, duplicates
        var invalidValues = [];
        var duplicateValuesInColumnA = [];
        var valid_mobile_no = [];
        var valid_variable_values = [];
        var arrays = {};
        var uniqueValuesInColumnA = new Set();
        var bigArray = [];
        for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
          var valueA = data[rowIndex][0]; // Assuming column A is at index 0
          if (!validateNumber(valueA)) {
            invalidValues.push(valueA);
          } else if (uniqueValuesInColumnA.has(valueA)) {
            duplicateValuesInColumnA.push(valueA);
          } else {
            uniqueValuesInColumnA.add(valueA);
          }
        }
        var totalCount = data.length;

        if ((invalidValues.length + duplicateValuesInColumnA.length === totalCount)) {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          $(".ex_msg").css("display", "none");
          $(".file_valid").css("display", "none");
          // Show the modal
          $('#upload_file_popup').modal('show');
          setTimeout(function () {
            $('#upload_file_popup').modal('hide');
          }, 10000);
          $('#file_response_msg').html('<b>The count of valid numbers is 0. Therefore, it is not possible to file uploaded.</b>');
          document.getElementById('upload_contact').value = '';

        } else if ((invalidValues.length >= 1 && duplicateValuesInColumnA.length >= 1) !== totalCount) {
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          $(".ex_msg").css("display", "");
          $(".file_valid").css("display", "");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Total Count : \n' + JSON.stringify(totalCount) + '\n Invalid Numbers: \n' + JSON.stringify(invalidValues.length) + '\n Duplicate Numbers: \n' + JSON.stringify(duplicateValuesInColumnA.length) + '</b>');
        } else if (duplicateValuesInColumnA.length > 0 !== totalCount) {
          $(".ex_msg").css("display", "");
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          $(".file_valid").css("display", "");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Total Count : \n' + JSON.stringify(totalCount) + '\n Duplicate Numbers : \n' + JSON.stringify(duplicateValuesInColumnA.length) + '</b>');
        } else if ((invalidValues.length > 0) && (invalidValues.length !== totalCount)) {
          $(".ex_msg").css("display", "");
          $(".file_valid").css("display", "");
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
          // Show the modal
          $('#upload_file_popup').modal('show');
          $('#file_response_msg').html('<b>Total Count : \n' + JSON.stringify(totalCount) + '\n Invalid Numbers : \n' + JSON.stringify(invalidValues.length) + '\n' + '</b>');
        } else {
          $(".ex_msg").css("display", "");
          $('.preloader-wrapper').hide();
          $('.loading_error_message').css("display", "none");
        }
      };
      reader.readAsBinaryString(file);
    }

    $('#upload_file_popup').find('.btn-secondary').on('click', function () {
      $('#upload_contact').val('');
    });

    const $dropdown = $('.dropdown-container'); // Cache all;

    function UI_dropdown() {
      const $this = $(this);
      const $btn = $('.dropdown-button', this);
      const $list = $('.dropdown-list', this);
      const $li = $('li', this);
      const $search = $('.dropdown-search', this);
      const $ckb = $(':checkbox', this);
      const $qty = $('.dropdown-quantity', this);
      $btn.on('click', function () {
        $dropdown.not($this).removeClass('is-active'); // Close other
        $this.toggleClass('is-active'); // Toggle this
      });

      // Search functionality
      $search.on('input', function () {
        const val = $(this).val().trim();
        const rgx = new RegExp(val, 'i');
        // Target the list items within the container with class .test
        $('.test li').each(function () {
          const name = $(this).text().trim(); // Extract text from list item
          $(this).toggleClass('is-hidden', !rgx.test(name));
        });
      });

      // select all
      $('#select-all-states', $this).on('change', function () {
        const isChecked = $(this).prop('checked');
        $this.find(':checkbox').prop('checked', isChecked); // Set checkboxes within the current dropdown container
        updateQuantity(); // Update quantity display
      });

      $(document).on('change', '.dropdown-container :checkbox', function (event) {
        updateQuantity(); // Update quantity display
      });

      // updateQuantity Function
      function updateQuantity() {
        const $checkedCheckboxes = $('.dropdown-container').find(':checkbox:checked');
        const names = $checkedCheckboxes.map(function () {
          return `<span class="dropdown-sel">${$(this).closest('label').text().trim()}</span>`;
        }).get();
        $('.dropdown-quantity').html(names.join(''));
      }

    }

    $dropdown.each(UI_dropdown); // Apply logic to all dropdowns

    function disableElement1(elementId) {
    $('#upload_contact').val(''); 
      var element = document.getElementById(elementId);
      if (element) {
        element.disabled = true;
      } else {
        console.error("Element with ID '" + elementId + "' not found.");
      }
    }
    function disableElement2() {
    }


    function openQRCodeModal(imagePath) {
      // Set the image source in the modal
      $('#qrcode').html("<img src='" + imagePath + "' style='width:100%; height:auto;'>");
      // Display the modal
      $('#qrcode-Modal').modal('show');
    }

    function downloadImage() {
      var qrCodeImageSrc = $('#qrcode img').attr('src'); // Get the src of the QR code image
      var link = document.createElement('a'); // Create a new anchor element
      link.href = qrCodeImageSrc; // Set the href attribute to the QR code image src
      link.download = 'qrcode.png'; // Set the download attribute with desired file name
      document.body.appendChild(link); // Append the anchor element to the document body
      link.click(); // Simulate a click on the anchor element
      document.body.removeChild(link); // Remove the anchor element from the document body
    }

    // Dropdown - Close opened 
    $(document).on('click', function (ev) {
      const $targ = $(ev.target).closest('.dropdown-container');
      if (!$targ.length) $dropdown.filter('.is-active').removeClass('is-active');
    });


    function promote_admin_fuc() {
      $('.reason').css("display", "none");
      $('.upload').css("display", "");
      $(".msg_content").text("Are you sure you want to Promote the Admin ?");
      $('.remove_btn').css("display", "");
      $('.remove_btn').text('Promote');
    }

    function demote_admin_fuc() {
      $('.reason').css("display", "none");
      $('.upload').css("display", "");
      $(".msg_content").text("Are you sure you want to Demote the Admin ?");
      $('.remove_btn').css("display", "");
      $('.remove_btn').text('Demote');
    }

    function remove_users_fuc() {
      $('.reason').css("display", "");
      $('.upload').css("display", "");
      $(".msg_content").text("Are you sure you want to Remove the Member ?");
      $('.remove_btn').css("display", "");
      $('.remove_btn').text('Remove');
    }

    var indicatoris, group_names, sender_nos, selected_usr_id;

    //popup function
    function create_admin_popup(group_master_id, indicatori, group_name, sender_no, selected_user_id) {
      indicatoris = indicatori;
      group_names = group_name;
      sender_nos = sender_no;
      selected_usr_id = selected_user_id;
      var send_code = "&group_master_id=" + group_master_id;
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=create_admin_list" + send_code,
        dataType: 'html',
        beforeSend: function () {
          $(".loading").css('display', 'block');
          $('.loading').show();
        },
        complete: function () {
          $(".loading").css('display', 'none');
          $('.loading').hide();
        },
        success: function (response) {
          if (response == '204' || response == 204) {
            $(".msg_content").css("display", "none");
            $(".info").css("display", "");
            $("#frm_sender_id").css("display", "none");
            $(".info").html("No data available");
            $(".button").css("display", "none");
            $(".modal-title").css("display", "none");
          } else {
            $(".modal-title").css("display", "");
            $(".button").css("display", "");
            $(".info").css("display", "none");
            $("#frm_sender_id").css("display", "");
            $(".test").html(response);
          }
        },
        error: function (response, status, error) { }
      });
      $("#id_error_reject").html("");
      $('#reject_reason').val('');
      $('#reject-Modal').modal({ show: true });
    }



    //popup function
    function admin_contacts_popup(group_master_id, indicatori, group_name, sender_no, selected_user_id) {
      indicatoris = indicatori;
      group_names = group_name;
      sender_nos = sender_no;
      selected_usr_id = selected_user_id;
      var send_code = "&group_master_id=" + group_master_id;
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=get_admin_list" + send_code,
        dataType: 'html',
        beforeSend: function () {
          $(".loading").css('display', 'block');
          $('.loading').show();
        },
        complete: function () {
          $(".loading").css('display', 'none');
          $('.loading').hide();
        },
        success: function (response) {
          if (response == '204' || response == 204) {
            $(".msg_content").css("display", "none");
            $(".info").css("display", "");
            $("#frm_sender_id").css("display", "none");
            $(".info").html("No data available");
            $(".button").css("display", "none");
            $(".modal-title").css("display", "none");
          } else {
            $(".modal-title").css("display", "");
            $(".button").css("display", "");
            $(".info").css("display", "none");
            $("#frm_sender_id").css("display", "");
            $(".test").html(response);
          }

        },
        error: function (response, status, error) { }
      });
      $("#id_error_reject").html("");
      $('#reject_reason').val('');
      $('#reject-Modal').modal({ show: true });
    }

    //popup function
    function group_contacts_popup(group_master_id, indicatori, group_name, sender_no, selected_user_id) {
      indicatoris = indicatori;
      group_names = group_name;
      sender_nos = sender_no;
      selected_usr_id = selected_user_id;
      var send_code = "&group_master_id=" + group_master_id;
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?tmpl_call_function=remove_users_list" + send_code,
        dataType: 'html',
        beforeSend: function () {
          $(".loading").css('display', 'block');
          $('.loading').show();
        },
        complete: function () {
          $(".loading").css('display', 'none');
          $('.loading').hide();
        },
        success: function (response) {
          if (response == '204' || response == 204) {
            $(".msg_content").css("display", "none");
            $(".info").css("display", "");
            $("#frm_sender_id").css("display", "none");
            $(".info").html("No data available");
            $(".button").css("display", "none");
            $(".modal-title").css("display", "none");
          } else {
            $(".modal-title").css("display", "");
            $(".button").css("display", "");
            $(".info").css("display", "none");
            $("#frm_sender_id").css("display", "");
            $(".test").html(response);
          }
        },
        error: function (response, status, error) { }
      });
      $("#id_error_reject").html("");
      $('#reject_reason').val('');
      $('#reject-Modal').modal({ show: true });
    }

    var mobile_numbers = "";
    var group_contact_ids = "";
    // Call remove_senderid function with the provided parameters
    $('#reject-Modal').find('.btn-success').on('click', function () {
      var reason = $('#reject_reason').val();
      var spanElements = document.querySelectorAll('.dropdown-quantity .dropdown-sel');
      var mobile_numbers = "";

      spanElements.forEach(function (span) {
        var number = span.textContent.trim().replace(/\D/g, ''); // Remove non-numeric characters
        if (number) {
          mobile_numbers += "," + number; // Concatenate mobile numbers
          // Remove leading comma if present
          if (mobile_numbers.startsWith(',')) {
            mobile_numbers = mobile_numbers.substring(1);
          }
        }
      });

      var fileInput = document.getElementById('upload_contact');
      var file = fileInput.files[0]; // Assuming only one file is selected
      console.log(spanElements.length + "spanElements.length")
      console.log(file + "file")
      console.log(mobile_numbers + " mobile_numbers ")
      if (spanElements.length == 0 && file === undefined && mobile_numbers == '') {
        $("#id_error_reject").html("Please select numbers");
      } else {
        var buttonText = $(this).text(); // Get the text content of the button
        console.log('Button clicked:', buttonText);

        if (buttonText == 'Demote') {
          var formData = new FormData();
          if (file) {
            formData.append('upload_contact', file);
          }
          // console.log(indicatoris, group_names, sender_nos, selected_usr_id);
          var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;
          // Add other data to formData
          formData.append('send_code', send_code);
          $("#id_error_reject").html("");
          $.ajax({
            type: 'post',
            url: "ajax/message_call_functions.php?tmpl_call_function=demote_admin_wastp",
            data: formData,
            contentType: false,
            processData: false,
            dataType: 'json',
            beforeSend: function () {
              $(".loading").css('display', 'block');
              $('.loading').show();
              $('.remove_btn').attr('disabled', true);
            },
            complete: function () {
              $(".loading").css('display', 'none');
              $('.loading').hide();
            },
            success: function (response) { // Success
              alert(response.msg);
              setTimeout(function () {
                window.location = 'group_list';
              }, 1000); // Every 3 seconds it will check
            },
            error: function (response, status, error) { // Error
              $('#id_qrcode').show();
              window.location = 'logout';
            }

          });

        } else if (buttonText == 'Promote') {
          var formData = new FormData();
          if (file) {
            formData.append('upload_contact', file);
          }
          // Other data to send
          var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;

          // Add other data to formData
          formData.append('send_code', send_code);
          $("#id_error_reject").html("");
          // Send AJAX request
          $.ajax({
            type: 'post',
            url: "ajax/message_call_functions.php?tmpl_call_function=promote_admin_wastp",
            data: formData,
            contentType: false,
            processData: false,
            dataType: 'json',
            beforeSend: function () {
              $(".loading").css('display', 'block');
              $('.loading').show();
              $('.remove_btn').attr('disabled', true);
            },
            complete: function () {
              $(".loading").css('display', 'none');
              $('.loading').hide();
            },
            success: function (response) {
              alert(response.msg);
              setTimeout(function () {
                window.location = 'group_list';
              }, 1000); // Every 3 seconds it will check
            },
            error: function (response, status, error) {
              // Handle error response
            }
          });

        } else if (buttonText == 'Remove') {
          var formData = new FormData();
          if (file) {
            formData.append('upload_contact', file);
          }

          if (reason == "") {
            $('#reject-Modal').modal({ show: true });
            $("#id_error_reject").html("Please enter reason to remove");
          }
          else {
            $('#reject-Modal').modal({ show: false });
            // console.log(indicatoris, group_names, sender_nos, selected_usr_id);
            var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;
            // Add other data to formData
            formData.append('send_code', send_code);
            $("#id_error_reject").html("");
            $.ajax({
              type: 'post',
              url: "ajax/message_call_functions.php?tmpl_call_function=send_remove_campaign_wastp",
              data: formData,
              contentType: false,
              processData: false,
              dataType: 'json',
              beforeSend: function () {
                $(".loading").css('display', 'block');
                $('.loading').show();
                $('.remove_btn').attr('disabled', true);
              },
              complete: function () {
                $(".loading").css('display', 'none');
                $('.loading').hide();
              },
              success: function (response) { // Success
                alert(response.msg);
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
              },
              error: function (response, status, error) { // Error
                $('#id_qrcode').show();
                window.location = 'logout';
              }

            });
          }

        }
      }
    });

    // Close reject model reset values
    $('#reject-Modal').on('hidden.bs.modal', function () {
      const checkboxes = document.querySelectorAll('.dropdown-list input[type="checkbox"]');
      checkboxes.forEach((checkbox) => {
        checkbox.checked = false;
      });
      const searchInput = document.querySelector('.dropdown-search');
      searchInput.value = '';
      const dropdownQuantity = document.querySelector('.dropdown-quantity');
      while (dropdownQuantity.firstChild) {
        dropdownQuantity.removeChild(dropdownQuantity.firstChild);
      }
      $('#upload_contact').prop("disabled", false);
      $('#upload_contact').val("");
    });

    // clear image
    $('#qrcode-Modal').on('hidden.bs.modal', function () {
      $('#qrcode').html("");
    });

    // To Show Datatable with Export, search panes and Column visible
    $('#table-1').DataTable({
      dom: 'Bfrtip',
      colReorder: true,
      buttons: [{
        extend: 'copyHtml5',
        exportOptions: {
          columns: [0, ':visible']
        }
      }, {
        extend: 'csvHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'pdfHtml5',
        exportOptions: {
          columns: ':visible'
        }
      }, {
        extend: 'searchPanes',
        config: {
          cascadePanes: true
        }
      }, 'colvis'],
      columnDefs: [{
        searchPanes: {
          show: false
        },
        targets: [0]
      }]
    });
  </script>
</body>

</html>
