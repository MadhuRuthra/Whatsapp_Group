<?php
/*
Authendicated users only allow to view this Manage Sender ID list page.
This page is used to view the list of Templates and its Status.
Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table

Version : 1.0
Author : Madhubala (YJ0009)
Date : 01-Jul-2023
*/

session_start(); // start session
error_reporting(0); // The error reporting function

include_once 'api/configuration.php'; // Include configuration.php
extract($_REQUEST); // Extract the request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>window.location = "index";</script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME);  // Collect the Current page name
site_log_generate("Template List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Template List ::
    <?= $site_title ?>
  </title>
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
 <link rel="stylesheet" href="assets/css/loader.css">
</head>
<style>
  #id_template_list {
    height: 600px;
  }

  .dataTables_filter label,
  .previous,
  .next {
    font-weight: bolder;
  }
</style>

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
            <h1>Template List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="create_template">Create Template</a></div>
              <div class="breadcrumb-item">Template List</div>
            </div>
          </div>

          <!-- Create Panel -->
          <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="create_template" class="btn btn-success"><i class="fas fa-plus"></i>
                  Create Template</a></h4>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_template_list"> <!-- Template list from API Service -->
                      Loading..
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

  <!-- Modal Popup window content-->
  <div class="modal fade" id="default-Modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" style=" max-width: 75% !important;">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Template Details</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" id="id_modal_display" style=" word-wrap: break-word; word-break: break-word;">
          <h5>No Data Available</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-success waves-effect " data-dismiss="modal">Close</button>
        </div>
      </div>
    </div>
  </div>
  <!-- Confirmation details content-->
  <div class="modal" tabindex="-1" role="dialog" id="delete-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Confirmation details</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <p>Are you sure you want to delete ?</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-danger" data-dismiss="modal">Delete</button>
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
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


  <script>
    // const minEl = document.getElementById('#btn_success').title;

    // On loading the page, this function will call
    $(document).ready(function () {
      find_template_list();
    });

    // To list the Templates from API
    function find_template_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=template_list",
        dataType: 'html',
        success: function (response) { // Succcess
          $("#id_template_list").html(response);
        },
        error: function (response, status, error) { // Error 
        }
      });
    }
    setInterval(find_template_list, 300000); // Every 5 mins (300000), it will call

    //popup function
    function remove_template_popup(template_response_id, indicatori) {
      $('#delete-Modal').modal({ show: true });
      // Call remove_senderid function with the provided parameters
      $('#delete-Modal').find('.btn-danger').on('click', function () {
        $('#delete-Modal').modal({ show: false });
        remove_template(template_response_id, indicatori);
      });
    }
    // To Delete the Templates from List
    function remove_template(template_response_id, indicatori) {
      var send_code = "&template_response_id=" + template_response_id + "&change_status=D";
      $.ajax({
        type: 'post',
        url: "ajax/whatsapp_call_functions.php?tmpl_call_function=remove_template" + send_code,
        dataType: 'json',
        success: function (response) {
          if (response.status == 0) {
          } else {
            setTimeout(function () {
              window.location = 'template_list';
            }, 2000);
            $('#id_template_status_' + indicatori).html('<a href="#!" class="btn btn-outline-danger btn-disabled">Deleted</a>');
          }
        },
        error: function (response, status, error) { }
      });
    }

    // To get the Single Template details from List and show in Modal Popup Window
    function call_getsingletemplate(tmpl_name, wht_tmpl_url, wht_bearer_token, indicatori) {
      $("#slt_whatsapp_template_single").html("");
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
          var tmpl_name_split = tmpl_name.split("!");
          if (response_msg.msg == '-' || response_msg.msg == null) {
            $("#id_modal_display").html('Template Name : ' + tmpl_name_split[0] + '<br><br>No Data Available!!');
          } else {
            $("#id_modal_display").html('Template Name : ' + tmpl_name_split[0] + '<br>' + response_msg.msg);
          }
          $('#default-Modal').modal({ show: true });
        },
        error: function (response_msg, status, error) {
          $("#slt_whatsapp_template_single").html(response_msg.msg);
          $('.theme-loader').hide();
          $("#id_error_display").html("");
        }
      });
    }

    // To Show Datatable with Export, search panes and Column visible
    $('#table-1').DataTable({
      dom: 'PlBfrtip',
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
      }, 'colvis'],
    });
  </script>
</body>

</html>
