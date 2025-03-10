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

  <!-- <script src="assets/js/multiselect-dropdown.js"></script> -->

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/searchPanes.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/select.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/colReorder.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/buttons.dataTables.min.css">
<link rel="stylesheet" href="assets/multi-select_1/css/chosen.css">
    
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
    overflow-y: auto;
    /* Enable vertical scrollbar when content overflows */
  }

  #id_manage_group_list {
    position: relative;
    height: 950px;
  }

  /* .multiselect-dropdown {
    width: 300px !important;
  } */
 
</style>

<body>
  <div class="loading" style="display:none;">Loading&#8230;</div>

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
      <div class="modal-content" style="height:500px;">
        <div class="modal-header">
          <h4 class="modal-title">Group Members <label style="color:#FF0000">*</label></h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <h2 class="info" style="display:none;text-align:center;"> </h2>
          <form class="needs-validation" novalidate="" id="frm_sender_id" name="frm_sender_id" action="#" method="post"
            enctype="multipart/form-data">

            <select data-placeholder="Select Categories" multiple class="chosen-select" id="multiple-label-example" tabindex="8">
</select>

            <div class="form-group mb-2 row reason">
              <label class="col-sm-5 col-form-label">Reason <label style="color:#FF0000">*</label></label>
              <div class="col-sm-7">
                <input class="form-control form-control-primary" type="text" name="reject_reason" id="reject_reason"
                  maxlength="50" minlength="3" title="Reason to remove" tabindex="12" placeholder="Reason to remove">
              </div>
            </div>
            <p>Are you sure you want to Remove the contact ?</p>
          </form>
        </div>
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
  <script src="assets/js/jquery.dataTables.min.js"></script>
  <script src="assets/js/dataTables.buttons.min.js"></script>
  <script src="assets/js/dataTables.searchPanes.min.js"></script>
  <script src="assets/js/dataTables.select.min.js"></script>
  <script src="assets/js/jszip.min.js"></script>
  <script src="assets/js/pdfmake.min.js"></script>
  <script src="assets/js/vfs_fonts.js"></script>
  <script src="assets/js/buttons.html5.min.js"></script>
  <script src="assets/js/buttons.colVis.min.js"></script>

    <!-- <script src="js/jquery-3.3.1.min.js"></script> -->
    <script src="assets/multi-select_1/js/popper.min.js"></script>
    <script src="assets/multi-select_1/js/bootstrap.min.js"></script>
    <script src="assets/multi-select_1/js/chosen.jquery.min.js"></script>
    
    <script src="assets/multi-select_1/js/main.js"></script>
  
  <script defer>
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


    $('#qrcode-Modal').on('hidden.bs.modal', function () {
      $('#qrcode').html("");
    });

    function promote_admin_fuc() {
      $('.reason').css("display", "none");
      $("p").text("Are you sure you want to Promote the Admin ?");
      $('.remove_btn').css("display", "");
      $('.remove_btn').text('Promote');
    }

    function demote_admin_fuc() {
      $('.reason').css("display", "none");
      $("p").text("Are you sure you want to Demote the Admin ?");
      $('.remove_btn').css("display", "");
      $('.remove_btn').text('Demote');
    }

    function remove_users_fuc() {
      $('.reason').css("display", "");
      $("p").text("Are you sure you want to Remove the Member ?");
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
          // alert(response)
          if (response == '204' || response == 204) {
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
            $(".remove_contact_list").html(response);
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
          alert(response); // For debugging purposes
          if (response == '204' || response == 204) {
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
            $('#multiple-label-example').html(response);
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
          // alert(response)
          if (response == '204' || response == 204) {
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
            $(".remove_contact_list").html(response);
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
      var txt_whatsapp_mobno = $('input[name="txt_whatsapp_mobno"]:checked').serialize();
      if (txt_whatsapp_mobno == "") {
        $("#id_error_reject").html("Please select users");
      }
      else {
        // console.log(txt_whatsapp_mobno);
        var mobile_split = txt_whatsapp_mobno.split("&")
        // console.log(mobile_split);
        for (var i = 0; i < mobile_split.length; i++) {
          var mobile_no_split = mobile_split[i].split("=");

          if (i == 0) {
            // For the first element, split and assign values
            var pair = mobile_no_split[1].split("-");
            mobile_numbers = pair[0];
            group_contact_ids = pair[1];
          } else {
            // For subsequent elements, split and append values
            var pair = mobile_no_split[1].split("-");
            mobile_numbers += "," + pair[0];
            group_contact_ids += "," + pair[1];
          }
        }

        var buttonText = $(this).text(); // Get the text content of the button
        console.log('Button clicked:', buttonText);

        if (buttonText == 'Demote') {
          // console.log(indicatoris, group_names, sender_nos, selected_usr_id);
          var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;
          $.ajax({
            type: 'post',
            url: "ajax/message_call_functions.php?tmpl_call_function=demote_admin_wastp" + send_code,
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
              if (response.status == '0' || response.status == 0) {
                alert(response.msg);
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
              } else if (response.status == '2' || response.status == 2) {
                alert(response.msg);
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
              } else { // Success
                alert("Admin Demoted Successfully.!");
                $('#reject_reason').val("");
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
                $('.theme-loader').hide();
              }
            },
            error: function (response, status, error) { // Error
              $('#id_qrcode').show();
              window.location = 'logout';
            }

          });

        } else if (buttonText == 'Promote') {

          // console.log(indicatoris, group_names, sender_nos, selected_usr_id);
          var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;
          $.ajax({
            type: 'post',
            url: "ajax/message_call_functions.php?tmpl_call_function=promote_admin_wastp" + send_code,
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
              if (response.status == '0' || response.status == 0) {
                alert(response.msg);
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
              } else if (response.status == '2' || response.status == 2) {
                alert(response.msg);
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
              } else { // Success
                alert("Admin Promoted Successfully.!");
                $('#reject_reason').val("");
                setTimeout(function () {
                  window.location = 'group_list';
                }, 1000); // Every 3 seconds it will check
                $('.theme-loader').hide();
              }
            },
            error: function (response, status, error) { // Error
              // $('#id_qrcode').show();
              // window.location = 'logout';
            }

          });
        } else if (buttonText == 'Remove') {
          $('.remove_name').attr("data-dismiss", "modal");
          if (reason == "") {
            $('#reject-Modal').modal({ show: true });
            $("#id_error_reject").html("Please enter reason to remove");
          }
          else {
            $('.remove_name').attr("data-dismiss", "modal");
            $('#reject-Modal').modal({ show: false });
            // console.log(indicatoris, group_names, sender_nos, selected_usr_id);
            var send_code = "&group_name=" + group_names + "&reason=" + reason + "&select_user_id=" + selected_usr_id + "&mobile_numbers=" + mobile_numbers + "&group_contacts_ids=" + group_contact_ids + "&sender_no=" + sender_nos;
            $.ajax({
              type: 'post',
              url: "ajax/message_call_functions.php?tmpl_call_function=send_remove_campaign_wastp" + send_code,
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
                if (response.status == '0' || response.status == 0) {
                  // alert(response.msg);
                  setTimeout(function () {
                    window.location = 'group_list';
                  }, 1000); // Every 3 seconds it will check
                } else if (response.status == '2' || response.status == 2) {
                  alert(response.msg);
                  setTimeout(function () {
                    window.location = 'group_list';
                  }, 1000); // Every 3 seconds it will check
                } else { // Success
                  alert("Users Removed!");
                  $('#reject_reason').val("");
                  setTimeout(function () {
                    window.location = 'group_list';
                  }, 1000); // Every 3 seconds it will check
                  $('.theme-loader').hide();
                }
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


    $('#reject-Modal').on('hidden.bs.modal', function () {
      // Clear the text fields
      $('.cls_checkbox1').prop('checked', false); // Replace with your actual text field IDs
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
