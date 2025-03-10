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
site_log_generate("Manage Sender ID List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Manage Sender ID List :: <?= $site_title ?></title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
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
          <!-- Title & Breadcrumb Panel -->
          <div class="section-header">
            <h1>Manage Sender ID List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="add_senderid">Add Sender ID</a></div>
              <div class="breadcrumb-item">Manage Sender ID List</div>
            </div>
          </div>

          <!-- Status Panel -->
          <div class="row">
            <div class="col-12">
              <a href="#!" class="btn btn-outline-success btn-disabled" title="Active">Active</a>&nbsp;<a href="#!"
                class="btn btn-outline-danger btn-disabled" title="Deleted">Deleted</a>&nbsp;<a href="#!"
                class="btn btn-outline-dark btn-disabled" title="Blocked">Blocked</a>&nbsp;<a href="#!"
                class="btn btn-outline-danger btn-disabled" title="Inactive">Inactive</a>&nbsp;<a href="#!"
                class="btn btn-outline-warning btn-disabled" title="Invalid">Invalid</a>&nbsp;<a href="#!"
                class="btn btn-outline-danger btn-disabled" title="Mobile No Mismatch">Mobile No Mismatch</a>&nbsp;<a
                href="#!" class="btn btn-outline-info btn-disabled" title="Processing">Processing</a>&nbsp;<a href="#!"
                class="btn btn-outline-danger btn-disabled" title="Rejected">Rejected</a>&nbsp;<a href="#!"
                class="btn btn-outline-primary btn-disabled" title="Need Rescan">Need Rescan</a>&nbsp;<a href="#!"
                class="btn btn-outline-info btn-disabled" title="Linked">Linked</a>&nbsp;<a href="#!"
                class="btn btn-outline-warning btn-disabled" title="Unlinked">Unlinked</a>
            </div>
          </div>

          <!-- Add Sender ID Panel -->
          <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="add_senderid" class="btn btn-success"><i class="fas fa-plus"></i>
                  Add Sender ID</a></h4>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_manage_whatsappno_list"> <!-- List from API -->
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

  <script>
    // On loading the page, this function will call
    $(document).ready(function () {
      manage_whatsappno_list();
    });

    // To Display the Whatsapp NO List
    function manage_whatsappno_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=manage_whatsappno_list",
        dataType: 'html',
        success: function (response) { // Success
          $("#id_manage_whatsappno_list").html(response);
        },
        error: function (response, status, error) { } // Error
      });
    }
    setInterval(manage_whatsappno_list, 60000); // Every 1 min (60000), it will call

    // To Remove the Sender ID
    function remove_senderid(whatspp_config_id, approve_status, indicatori) {
      var send_code = "&whatspp_config_id=" + whatspp_config_id + "&approve_status=D";
      $.ajax({
        type: 'post',
        url: "ajax/message_call_functions.php?tmpl_call_function=delete_senderid" + send_code,
        dataType: 'json',
        success: function (response) { // Success
          if (response.status == 0) { // Failure Response
            $('#id_approved_lineno_' + indicatori).append('<a href="javascript:void(0)" class="btn disabled btn-outline-warning">Not Deleted</a>');
          } else { // Success Response
            $('#id_approved_lineno_' + indicatori).html('<a href="javascript:void(0)" class="btn disabled btn-outline-danger">Deleted</a>');
            window.location.reload(); // Window Reload
          }
        },
        error: function (response, status, error) { } // Error
      });
    }

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