<?php
/*
Authendicated users only allow to view this Messenger Response list page.
This page is used to view the list of Messenger response from Whatsapp server and its Status.
Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table

Version : 1.0
Author : Madhubala (YJ0009)
Date : 03-Jul-2023
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
site_log_generate("Messenger Response List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Messenger Response List ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/searchPanes.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/select.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/colReorder.dataTables.min.css">
  <link rel="stylesheet" href="assets/css/buttons.dataTables.min.css">

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
</head>

<body>
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
            <h1>Messenger Response List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Messenger Response List</div>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_messenger_responses">
                      Loading ..
                    </div>
                  </div>
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

  <!-- Modal Popup Window content-->
  <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Response</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" id="id_modal_display">
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

  <script src="assets/js/socket.io.js"
    integrity="sha512-xbQU0+iHqhVt7VIXi6vBJKPh3IQBF5B84sSHdjKiSccyX/1ZI7Vnkt2/8y8uruj63/DVmCxfUNohPNruthTEQA=="
    crossorigin="anonymous" referrerpolicy="no-referrer"></script>
  <script>
    // On loading the page, this function will call
    $(document).ready(function () {
      find_messenger_responses();
    });

    // To list the Messenger Response from API
    function find_messenger_responses() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=messenger_responses",
        dataType: 'html',
        success: function (response) {
          $("#id_messenger_responses").html(response);
        },
        error: function (response, status, error) { }
      });
    }
    setInterval(find_messenger_responses, 60000); // Every 1 min (60000), it will call

    // To Preview a particular Response and Show in Modal Popup Window
    function func_view_response(message_id, message_from, message_to) {
      // Check if any of the parameters is undefined
      if (message_id === undefined || message_from === undefined || message_to === undefined) {
        console.error("One or more parameters are undefined.");
        return; // Return early without making the AJAX request
      }
      $.ajax({
        type: 'post',
        url: "ajax/preview_functions.php?tmpl_call_function=view_response&message_id=" + message_id + "&message_from=" + message_from + "&message_to=" + message_to,
        dataType: 'html',
        success: function (response) {
          $("#id_modal_display").html(response);
          $('#default-Modal').modal({ show: true });
        },
        error: function (response, status, error) { }
      });
    }

    // Send Reply against Response Popup Form - To Submit the Form and Save
    $(document).on("submit", "form#frm_reply", function (e) {
      e.preventDefault(); // Prevent the default behaviours
      $("#id_error_display").html("");

      // To get the input field values
      var txt_reply = $('#txt_reply').val();
      var message_id = $('#message_id').val();
      var message_from = $('#message_from').val();
      var message_to = $('#message_to').val();

      var flag = true;
      /********validate all our form fields***********/
      /* txt_reply field validation  */
      if (txt_reply == "") {
        $('#txt_reply').css('border-color', 'red');
        flag = false;
        e.preventDefault();
      }
      /********Validation end here ****/

      /* If all are ok then we send ajax request to ajax/message_call_functions.php *******/
      if (flag) {
        var data_serialize = $("#frm_reply").serialize();
        $.ajax({
          type: 'post',
          url: "ajax/message_call_functions.php?tmpl_call_function=messenger_reply",
          dataType: 'json',
          data: data_serialize,
          beforeSend: function () { // Before send it to Ajax
            $('#reply_submit').attr('disabled', true);
            $('#load_page').show();
          },
          complete: function () { // After complete the Ajax
            $('#reply_submit').attr('disabled', false);
            $('#load_page').hide();
          },
          success: function (response) { // Success
            if (response.status == '0') { // Failure Response
              $('#txt_reply').val('');
              $('#reply_submit').attr('disabled', false);
              $("#id_error_display").html(response.msg);
            } else if (response.status == 1) { // Success Response
              $('#reply_submit').attr('disabled', false);
            }
            func_view_response(message_id, message_from, message_to); // Call the another function to view the Response
          },
          error: function (response, status, error) { // Error
            $('#txt_reply').val('');
            $('#reply_submit').attr('disabled', false);
            $("#id_error_display").html(response.msg);
          }
        });
      }
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

    // Web Socket for Messenger Auto Response
    var socket = io.connect('<?= $site_socket_url ?>', { reconnect: true });

    // Add a connect listener
    socket.on('connect', function (msg_response) {
      console.log('Connected!');
    });
    socket.on('messenger_response', function (data) {

      if (data.response_msg == 1) { // If success response returns
        var message_id = $('#message_id').val();
        var message_from = $('#message_from').val();
        var message_to = $('#message_to').val();

        // To open the popup and get the latest response from API
        find_messenger_responses();
        func_view_response(message_id, message_from, message_to);
      }

    });
  </script>
</body>

</html>
