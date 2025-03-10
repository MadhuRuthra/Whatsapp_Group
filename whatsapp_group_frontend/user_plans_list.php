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
site_log_generate("Pricing Plans List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s"));
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Pricing Plans List ::
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
  #id_user_plans_list {
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

      <? include("libraries/site_header.php"); ?>

      <? include("libraries/site_menu.php"); ?>

      <!-- Main Content -->
      <div class="main-content">
        <section class="section">
          <div class="section-header">
            <h1>Pricing Plans List</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item active"><a href="compose_whatsapp">Compose Whatsapp</a></div>
              <div class="breadcrumb-item">Pricing Plans List</div>
            </div>
          </div>

          <div class="row">
            <div class="col-12">
              <h4 class="text-right"><a href="plan_creation" class="btn btn-success"><i class="fas fa-plus"></i>
                  Plan Creation</a></h4>
            </div>
          </div>

          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <div class="table-responsive" id="id_user_plans_list">
                      Loading ..
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>

      <? include("libraries/site_footer.php"); ?>

    </div>
  </div>
  <!-- Confirmation details content-->
  <div class="modal" tabindex="-1" role="dialog" id="default-Modal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h4 class="modal-title">Confirmation details</h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body" style="height: 50px;">
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

    $(document).ready(function () {
      plans_list();
    });

    function plans_list() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=plans_list",
        dataType: 'html',
        success: function (response) {
          $("#id_user_plans_list").html(response);
        },
        error: function (response, status, error) { }
      });
    }

    setInterval(plans_list, 60000); // Every 1 min (60000), it will call

    var plan_master_ids, approvestatus, indicatoris;
    //popup function
    function remove_plan_popup(plan_master_id, approve_status, indicatori) {
      plan_master_ids = plan_master_id; approvestatus = approve_status; indicatoris = indicatori;
      $('#default-Modal').modal({ show: true });
    }

    // Call remove_senderid function with the provided parameters
    $('#default-Modal').find('.btn-danger').on('click', function () {
      $('#delete-Modal').modal({ show: false });
      var send_code = "&plan_master_id=" + plan_master_ids;
      $.ajax({
        type: 'post',
        url: "ajax/message_call_functions.php?tmpl_call_function=delete_plan" + send_code,
        dataType: 'json',
        success: function (response) { // Success
          if (response.status == 0) { // Failure Response
            $('#id_approved_lineno_' + indicatoris).append('<a href="javascript:void(0)" class="btn disabled btn-outline-warning">Not Deleted</a>');
          } else { // Success Response
            $('#id_approved_lineno_' + indicatoris).html('<a href="javascript:void(0)" class="btn disabled btn-outline-danger">Deleted</a>');
            setTimeout(function () {
              window.location.reload(); // Window Reload
            }, 1000);
          }
        },
        error: function (response, status, error) { } // Error
      });
      // remove_senderid(whatspp_config_id, approve_status, indicatori);
    });


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
