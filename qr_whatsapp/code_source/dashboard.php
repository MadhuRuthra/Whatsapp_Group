<?php
/*
Authendicated users only allow to view this Dashboard page.
This page is used to view the logged in user.

Version : 1.0
Author : Arun Rama Balan.G (YJ0005)
Date : 06-Jul-2023
*/
//echo "**";
session_start(); // To start session
error_reporting(0); // The error reporting function

// Include configuration.php
include_once('api/configuration.php');
extract($_REQUEST); // Extract the Request

// If the Session is not available redirect to index page
if ($_SESSION['yjwatsp_user_id'] == "") { ?>
  <script>
    window.location = "index";
  </script>
  <?php exit();
}

$site_page_name = pathinfo($_SERVER['PHP_SELF'], PATHINFO_FILENAME); // Collect the Current page name
site_log_generate("Dashboard Page : User : " . $_SESSION['yjwatsp_user_name'] . " access the page on " . date("Y-m-d H:i:s")); // Log File
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta content="width=device-width, initial-scale=1, maximum-scale=1, shrink-to-fit=no" name="viewport">
  <title>Dashboard ::
    <?= $site_title ?>
  </title>
  <link rel="icon" href="assets/img/favicon.ico" type="image/x-icon">

  <!-- General CSS Files -->
  <link rel="stylesheet" href="assets/modules/bootstrap/css/bootstrap.min.css">
  <link rel="stylesheet" href="assets/modules/fontawesome/css/all.min.css">

  <!-- CSS Libraries -->
  <link rel="stylesheet" href="assets/modules/jqvmap/dist/jqvmap.min.css">
  <link rel="stylesheet" href="assets/modules/summernote/summernote-bs4.css">
  <link rel="stylesheet" href="assets/modules/owlcarousel2/dist/assets/owl.carousel.min.css">
  <link rel="stylesheet" href="assets/modules/owlcarousel2/dist/assets/owl.theme.default.min.css">

  <!-- Template CSS -->
  <link rel="stylesheet" href="assets/css/style.css">
  <link rel="stylesheet" href="assets/css/components.css">

  <!-- chart bar -->
  <script src="assets/barcharts/highstock.js"></script>
  <script src="assets/barcharts/exporting.js"></script>
  <script src="assets/barcharts/accessibility.js"></script>

</head>

<style>
  .highcharts-root {
    position: relative;
    height: 1000px !important;
  }


  #container {
    position: relative;
    /* height:950px; */
    height: auto;
    min-height: 400px;
    min-width: 320px;
    width: 100%;
    margin: 0 auto;
    overflow: auto;
  }

  .highcharts-scrollbar-track {
    width: 15px !important;
  }

  .highcharts-scrollbar-thumb {
    width: 14px !important;
    height: 50px;
  }

  .highcharts-exporting-group {
    display: none !important;
  }

  .highcharts-figure,
  .highcharts-data-table table {
    min-width: 310px;
    max-width: 800px;
    margin: 1em auto;
  }

  #container {
    position: relative;
    height: 100%
  }

  .highcharts-container {
    position: relative;
    width: 100% !important;
    height: 100% !important;
  }

  .highcharts-data-table table {
    font-family: Verdana, sans-serif;
    border-collapse: collapse;
    border: 1px solid #ebebeb;
    margin: 10px auto;
    text-align: center;
    width: 100%;
    max-width: 500px;
  }

  .highcharts-data-table caption {
    padding: 1em 0;
    font-size: 1.2em;
    color: #555;
  }

  .highcharts-data-table th {
    font-weight: 600;
    padding: 0.5em;
  }

  .highcharts-data-table td,
  .highcharts-data-table th,
  .highcharts-data-table caption {
    padding: 0.5em;
  }

  .highcharts-data-table thead tr,
  .highcharts-data-table tr:nth-child(even) {
    background: #f8f8f8;
  }

  .highcharts-data-table tr:hover {
    background: #f1f7ff;
  }

  .highcharts-background {
    width: 100% !important;
    position: relative;
    height: 100% !important;
  }

  .highcharts-plot-background {
    width: 100% !important;
    position: relative;
    height: 100% !important;
  }

  .highcharts-plot-border {
    position: relative;
    width: 100% !important;
    height: 100% !important;

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
          <div class="row" id="id_dashboard_count">
            <!-- Show Count -->
          </div>
          <div id="container"></div>
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
  <script src="assets/modules/jquery.sparkline.min.js"></script>
  <script src="assets/modules/chart.min.js"></script>
  <script src="assets/modules/owlcarousel2/dist/owl.carousel.min.js"></script>
  <script src="assets/modules/summernote/summernote-bs4.js"></script>
  <script src="assets/modules/chocolat/dist/js/jquery.chocolat.min.js"></script>

  <!-- Page Specific JS File -->
  <script src="assets/js/page/index.js"></script>

  <!-- Template JS File -->
  <script src="assets/js/scripts.js"></script>
  <script src="assets/js/custom.js"></script>

  <script>
    // On loading the page, this function will call
    $(document).ready(function () {
      find_dashboard(); // Function Name
    });
    var user_name, total_admin, total_active_member, totalMember, groupNameInput;
    var groupNameArray, user_nameArray, total_active_memberArray, totalMemberArray;
    // To display the Dashboard details from API
    function find_dashboard() {
      $.ajax({
        type: 'post',
        url: "ajax/display_functions.php?call_function=dashboard_count",
        dataType: 'html',
        success: function (response) {
          $("#id_dashboard_count").html(response); // Show the details from API Response
          groupNameInput = document.getElementById('group_name').value;
          groupNameArray = JSON.parse(groupNameInput);
          user_name = document.getElementById('user_name').value;
          user_nameArray = JSON.parse(user_name);
          total_admin = document.getElementById('total_admin').value;
          total_adminArray = JSON.parse(total_admin);
          totalMember = document.getElementById('total_member').value;
          totalMemberArray = JSON.parse(totalMember);
          total_active_member = document.getElementById('total_active_member').value;
          total_active_memberArray = JSON.parse(total_active_member);

          // Convert each element to a number
          totalMemberArray = totalMemberArray.map(function (value) {
            return Number(value);
          });

          // Convert each element to a number
          total_active_memberArray = total_active_memberArray.map(function (value) {
            return Number(value);
          });

          // Convert each element to a number
          total_adminArray = total_adminArray.map(function (value) {
            return Number(value);
          });
          document.addEventListener("DOMContentLoaded", function () {
            // Code to modify the width attribute of .highcharts-scrollbar-track
            document.querySelector('.highcharts-scrollbar-track').setAttribute('width',
              '15');
          });


          // JavaScript code to create the Highcharts chart
          Highcharts.chart('container', {
            chart: {
              type: 'bar',
              contextMenu: null,
              scrollablePlotArea: {
            minHeight: 1000,
            scrollPositionY: 1
        }
            },
            title: {
              text: 'Group Charts',
              align: 'left'
            },
            xAxis: {
              min: 0, // Set the minimum value displayed on the x-axis
              max: 5,
              scrollbar: {
                enabled: true
              },
              categories: groupNameArray.map((groupName, index) =>
                `${groupName} (${user_nameArray[index]})`),
              title: {
                text: null
              },
              gridLineWidth: 1,
              lineWidth: 0
            },
            yAxis: {
              min: 0, // Start the y-axis from 1
              // max: 1000, // Start the y-axis from 1
              title: {
                text: 'Members (Counts)',
                align: 'high'
              },
              labels: {
                overflow: 'justify',
                step: 1 // Set the step value for labels to 1
              },
              gridLineWidth: 0,
            },
            tooltip: {
              valueSuffix: ' counts'
            },
            plotOptions: {
              bar: {
                borderRadius: '50%',
                dataLabels: {
                  enabled: true
                },
                groupPadding: 0.1
              }
            },
            legend: {
              layout: 'vertical',
              align: 'right',
              verticalAlign: 'top',
              x: -40,
              y: 80,
              floating: true,
              borderWidth: 3,
              // backgroundColor: Highcharts.defaultOptions.legend.backgroundColor || '#FFFFFF',
              shadow: true,
              enabled: true
            },
            credits: {
              enabled: false
            },
            series: [{
              name: 'Total Member',
              data: totalMemberArray
            }, {
              name: 'Total Active Member',
              data: total_active_memberArray
            }, {
              name: 'Total Admin',
              data: total_adminArray
            }]
          });
        },
        error: function (response, status, error) { } // Error
      });
    }
    // setInterval(find_dashboard, 60000); // Every min it will call
  </script>
</body>

</html>