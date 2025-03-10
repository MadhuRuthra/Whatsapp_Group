<?php
/*
Authendicated users only allow to view this Campaign Report page.
This page is used to view the List of Campaign Report.
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
site_log_generate("Campaign Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Detailed Report ::
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
  <!--Date picker -->
  <script type="text/javascript" src="assets/js/daterangepicker.min.js" defer></script>
  <link rel="stylesheet" type="text/css" href="assets/css/daterangepicker.css" />

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">
</head>
<style>
  element.style {}

  .card .card-header,
  .card .card-body,
  .card .card-footer {
    padding: 20px;
  }

  .custom-file,
  .custom-file-label,
  .custom-select,
  .custom-file-label:after,
  .form-control[type="color"],
  select.form-control:not([size]):not([multiple]) {
    height: calc(2.25rem + 6px);
  }

  .input-group-text,
  select.form-control:not([size]):not([multiple]),
  .form-control:not(.form-control-sm):not(.form-control-lg) {
    Loading… ￼ font-size: 14px;
    padding: 5px 15px;
  }

  .search {
    width: 200px;
    margin-right: 50px;
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
            <h1>Whatsapp Detailed Report</h1>
            <div class="section-header-breadcrumb">
              <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
              <div class="breadcrumb-item">Detailed Report</div>
            </div>
          </div>

          <!-- List Panel -->
          <div class="section-body">
            <div class="row">
              <div class="col-12">
                <div class="card">
                  <div class="card-body">
                    <!-- Choose User -->
                    <form method="post">
                      <div id="table-1_filter" class="dataTables_filter">

                        <!-- date filter -->
                        <div style="width: 20%; padding-right:1%; float: left;">Date : <input type="search" name="dates"
                            id="dates" value="<?= $_REQUEST['dates'] ?>" class="search_1" placeholder=""
                            aria-controls="table-1"
                            style="width: 100%;height:30px;background-color: #e9ecef;border :1px solid #ced4da;" />
                        </div>
                        <!-- submit button -->
                        <div style="width: 20%; padding-right:1%; float: left;">
                          <input type="submit" name="submit_1" id="submit_1" tabindex="10" value="Search"
                            class="btn btn-success " style="height:30px; margin-top: 20px;">
                        </div>
                      </div>
                    </form>

                    <div class="table-responsive" id="id_campaign_report" style="padding-top: 20px;">
                      <!-- List from API -->
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
      campaign_report();
    });


    var dates;
    // While click the Submit button
    $("#submit_1").click(function (e) {
      e.preventDefault();
      dates = $('#dates').val();
      campaign_report();
    });

    // To Display the Whatsapp NO List
    function campaign_report() {
      date = $("#dates").val();
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=detailed_report&dates=" + date,
        dataType: 'html',
        success: function (response) { // Success
          $("#id_campaign_report").html(response);
        },
        error: function (response, status, error) { } // Error
      });
    }
    // setInterval(campaign_report, 60000); // Every 1 min (60000), it will call


    // To show the Calendar
    $(function () {
      var start = moment().subtract(7, 'days');
      var end = moment();
      function cb(start, end) {
        $('#dates').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
      }
      $('#dates').daterangepicker({
        startDate: start,
        endDate: end,
        locale: {
          cancelLabel: 'Clear',
          format: 'YYYY/MM/DD'
        }
      }, cb);
      cb(start, end);
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
