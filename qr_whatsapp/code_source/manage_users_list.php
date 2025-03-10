<?php
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
site_log_generate("Manage Users List Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
    <title>Manage Users List ::
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
  #id_manage_users_list {
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
                    <!-- Title & Breadcrumb Panel -->
                    <div class="section-header">
                        <h1>Manage Users List</h1>
                        <div class="section-header-breadcrumb">
                            <div class="breadcrumb-item active"><a href="dashboard">Dashboard</a></div>
                            <div class="breadcrumb-item active"><a href="manage_users">Manage Users</a></div>
                            <div class="breadcrumb-item">Manage Users List</div>
                        </div>
                    </div>
                    <!-- Add Users Panel -->
                    <div class="row">
                        <div class="col-12">
                            <h4 class="text-right"><a href="manage_users" class="btn btn-success"><i
                                        class="fas fa-plus"></i>
                                    Add Users</a></h4>
                        </div>
                    </div>
                    <!-- List Panel -->
                    <div class="section-body">
                        <div class="row">
                            <div class="col-12">
                                <div class="card">
                                    <div class="card-body">
                                        <div class="table-responsive" id="id_manage_users_list">
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
            manage_users_list();
        });

        // To Display the Whatsapp NO List
        function manage_users_list() {
            $.ajax({
                type: 'post',
                url: "ajax/display_functions.php?call_function=manage_users_list",
                dataType: 'html',
                success: function (response) { // Success
                    $("#id_manage_users_list").html(response);
                },
                error: function (response, status, error) { } // Error
            });
        }
        setInterval(manage_users_list, 60000); // Every 1 min (60000), it will call

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
