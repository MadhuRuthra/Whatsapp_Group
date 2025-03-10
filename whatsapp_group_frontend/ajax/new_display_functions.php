<?php
session_start();
error_reporting(E_ALL);
// Include configuration.php
include_once('../api/configuration.php');
extract($_REQUEST);

$current_date = date("Y-m-d H:i:s");

// Dashboard Page dashboard_count - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "dashboard_count") {
	site_log_generate("Dashboard Page : User : " . $_SESSION['yjwatsp_user_name'] . " access this page on " . date("Y-m-d H:i:s"), '../');
	// To Send the request  API
	$replace_txt = '{
    "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
  }';

	$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . ''; // add the bearer
	// It will call "dashboard" API to verify, can we access for the dashboard details
	$curl = curl_init();
	curl_setopt_array(
		$curl,
		array(
			CURLOPT_URL => $api_url . '/user/dashboard',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_ENCODING => '',
			CURLOPT_MAXREDIRS => 10,
			CURLOPT_TIMEOUT => 0,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
			CURLOPT_CUSTOMREQUEST => 'GET',
			CURLOPT_POSTFIELDS => $replace_txt,
			CURLOPT_HTTPHEADER => array(
				$bearer_token,
				'Content-Type: application/json'

			),
		)
	);

	// Send the data into API and execute
	site_log_generate("Dashboard Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt,$bearer_token] on " . date("Y-m-d H:i:s"), '../');

	$response = curl_exec($curl);
	curl_close($curl);
	// echo $response;

	if ($response == '') { ?>
		<script>
			window.location = "logout"
		</script>
	<? } else if ($state1->response_status == 403) { ?>
			<script>
				window.location = "logout"
			</script>
	<? }
	// After got response decode the JSON result
	$state1 = json_decode($response, false);

	site_log_generate("Dashboard Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
	$total_msg = 0;
	$total_success = 0;
	$total_failed = 0;
	$total_invalid = 0;
	$total_waiting = 0;

	// To get the one by one data
	if ($state1->response_code == 1) { // If the response is success to execute this condition
		for ($indicator = 0; $indicator < count($state1->dashboard_data); $indicator++) {
			//Looping the indicator is less than the count of report.if the condition is true to continue the process.if the condition is false to stop the process
			// $header_title = $state1->dashboard_data[$indicator]->header_title;
			$user_id = $state1->dashboard_data[$indicator]->user_id;
			// $user_master_id	= $state1->report[$indicator]->user_master_id;
			$user_name = $state1->dashboard_data[$indicator]->user_name;
			$total_groups = $state1->dashboard_data[$indicator]->total_groups;
			$total_active_group = $state1->dashboard_data[$indicator]->total_active_group;
			$total_inactive_group = $state1->dashboard_data[$indicator]->total_inactive_group;
			$total_contacts = $state1->dashboard_data[$indicator]->total_contacts;
			$total_succ_contact = $state1->dashboard_data[$indicator]->total_succ_contact;
			$total_fail_contact = $state1->dashboard_data[$indicator]->total_fail_contact;
			// $total_waiting = $state1->dashboard_data[$indicator]->total_waiting;
			if ($user_name == $_SESSION['yjwatsp_user_name']) { // If the userid is equal to authenticate userid success to execute this condition
				?>
				<div class="col-lg-12 col-md-12 col-sm-12">
				<? } else { // otherwise it willbe execute
				?>
					<div class="col-lg-6 col-md-6 col-sm-12">
					<? } ?>
					<div class="card card-statistic-2">
						<div class="card-stats">
							<div class="card-stats-title mb-2">
								<?= strtoupper($user_name) ?>	Summary
							</div>
							<div class="card-stats-items" style="margin: 10px 0 20px 0;">
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_groups ?>
									</div>
									<div class="card-stats-item-label">Total Groups</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_active_group ?>
									</div>
									<div class="card-stats-item-label">Active Group</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_inactive_group ?>
									</div>
									<div class="card-stats-item-label">Inactive Group</div>
								</div>

								<? if ($user_name == $_SESSION['yjwatsp_user_name']) { // If the userid is equal to authenticate userid success to execute this condition
											} else { ?>
								</div>
								<div class="card-stats-items" style="margin: 10px 0 20px 0;">
								<? } ?>
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_contacts ?>
									</div>
									<div class="card-stats-item-label">Total Contacts</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_succ_contact ?>
									</div>
									<div class="card-stats-item-label">Success Contact</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">
										<?= $total_fail_contact ?>
									</div>
									<div class="card-stats-item-label">Failed Contact</div>
								</div>

							</div>
						</div>
					</div>
				</div>

				<?php
		}
		site_log_generate("Index Page : " . $uname . " logged in success on " . date("Y-m-d H:i:s"), '../');
		$json = array("status" => 1, "info" => $result);
		site_log_generate("Dashboard Page : User : " . $response . " Preview on " . date("Y-m-d H:i:s"), '../');
	} else {
		// otherwise it willbe execute
		if ($user_name == $_SESSION['yjwatsp_user_name']) {
			// If the userid is equal to authenticate userid success to execute this condition
			?>
				<div class="col-lg-12 col-md-12 col-sm-12">
				<? } else { // otherwise it willbe execute
			?>
					<div class="col-lg-6 col-md-6 col-sm-12">
					<? } ?>
					<div class="card card-statistic-2">
						<div class="card-stats">
							<div class="card-stats-title mb-2">
								<?= strtoupper($_SESSION['yjwatsp_user_name']) ?>	- Whatsapp Summary
							</div>
							<div class="card-stats-items" style="margin: 10px 0 20px 0;">
								<div class="card-stats-item">
									<div class="card-stats-item-count">0</div>
									<div class="card-stats-item-label">In processing</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">0</div>
									<div class="card-stats-item-label">Failed</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">0</div>
									<div class="card-stats-item-label">Delivered</div>
								</div>

								<div class="card-stats-item">
									<div class="card-stats-item-count">0</div>
									<div class="card-stats-item-label">Available Credits</div>
								</div>
								<div class="card-stats-item">
									<div class="card-stats-item-count">0</div>
									<div class="card-stats-item-label">Total Messages</div>
								</div>
							</div>
						</div>
					</div>
				</div>
				<?
	}
}
// Dashboard Page dashboard_count - End

// manage_whatsappno_list Page manage_whatsappno_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_whatsappno_list") {
	site_log_generate("Manage Whatsappno List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Mobile No</th>
						<th>Profile Details</th>
						<th>Status</th>
						<th>Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					$replace_txt = '';
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
					site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					$sms = json_decode($response, false);
					site_log_generate("Manage Whatsappno List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }

					// print_r($sms); exit;
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < count($sms->sender_id); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->sender_id[$indicator]->senderid_master_entdate));
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($sms->sender_id[$indicator]->user_name) ?>
								</td>
								<td>
									<?= $sms->sender_id[$indicator]->country_code . $sms->sender_id[$indicator]->mobile_no ?>
								</td>
								<td>
									<? echo $sms->sender_id[$indicator]->profile_name . "<br>";
									if ($sms->sender_id[$indicator]->profile_image != '') {
										echo "<img src='" . $sms->sender_id[$indicator]->profile_image . "' style='width:100px; max-height: 100px;'>";
									} ?>
								</td>

								<td>
									<? if ($sms->sender_id[$indicator]->senderid_master_status == 'Y') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled"
											style="width:120px; text-align:center">Active</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'D') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled"
											style="width:120px; text-align:center">Deleted</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'B') { ?><a href="#!"
											class="btn btn-outline-dark btn-disabled" style="width:120px; text-align:center">Blocked</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'N') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled"
											style="width:120px; text-align:center">Inactive</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'M') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled" style="width:120px; text-align:center">Mobile No
											Mismatch</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'I') { ?><a href="#!"
											class="btn btn-outline-warning btn-disabled"
											style="width:120px; text-align:center">Invalid</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'P') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled"
											style="width:120px; text-align:center">Processing</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'R') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled"
											style="width:120px; text-align:center">Rejected</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'X') { ?><a href="#!"
											class="btn btn-outline-primary btn-disabled" style="width:120px; text-align:center">Need
											Rescan</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'L') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled" style="width:120px; text-align:center">Linked</a>
									<? } elseif ($sms->sender_id[$indicator]->senderid_master_status == 'U') { ?><a href="#!"
											class="btn btn-outline-warning btn-disabled"
											style="width:120px; text-align:center">Unlinked</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td id='id_approved_lineno_<?= $indicatori ?>'>
									<? if ($sms->sender_id[$indicator]->senderid_master_status == 'D' or $sms->sender_id[$indicator]->senderid_master_status == 'N' or $sms->sender_id[$indicator]->senderid_master_status == 'M' or $sms->sender_id[$indicator]->senderid_master_status == 'I' or $sms->sender_id[$indicator]->senderid_master_status == 'X') { ?>
										<a href="add_senderid?mob=<?= $sms->sender_id[$indicator]->mobile_no ?>&pro=<?= $sms->sender_id[$indicator]->profile_name ?>&img=<?= $sms->sender_id[$indicator]->profile_image ?>"
											class="btn btn-success">Scan</a>

									<? } else { ?>
										<a href="#!" class="btn btn-outline-light btn-disabled" style="cursor: not-allowed;">Scan</a>
									<? } ?>

									<? if ($sms->sender_id[$indicator]->senderid_master_status != 'D') { ?>
										<button type="button" title="Delete Sender ID"
											onclick="remove_senderid_popup('<?= $sms->sender_id[$indicator]->sender_master_id ?>', 'D', '<?= $indicatori ?>')"
											class="btn btn-icon btn-danger" style="padding: 0.3rem 0.41rem !important;">Delete</button>
									<? } else { ?>
										<a href="#!" class="btn btn-outline-light btn-disabled"
											style="padding: 0.3rem 0.41rem !important;cursor: not-allowed;">Delete</a>
									<? } ?>
								</td>
							</tr>
							<?
						}
					}
					?>
				</tbody>
			</table>

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
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: true
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// manage_whatsappno_list Page manage_whatsappno_list - End

// template_list Page template_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "template_list") {
	site_log_generate("Template List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	// Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table ?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Template Name</th>
						<th>Template Category</th>
						<th>Status</th>
						<th>Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					// To Send the request API
					$replace_txt = '{
            "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
             }';

					// Add bearer token
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// It will call "p_template_list" API to verify, can we can we allow to view the template list
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/message_template',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'GET',
							CURLOPT_POSTFIELDS => $replace_txt,
							CURLOPT_HTTPHEADER => array(
								$bearer_token,
								'Content-Type: application/json'
							),
						)
					);

					// Send the data into API and execute   
					site_log_generate("Template List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt,$bearer_token] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					// After got response decode the JSON result
					$sms = json_decode($response, false);
					site_log_generate("Template List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					$indicatori = 0;
					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }

					// print_r($sms); exit;
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < $sms->num_of_rows; $indicator++) {
							// Looping the indicator is less than the num_of_rows.if the condition is true to continue the process.if the condition is false to stop the process
							$indicatori++;
							// To get the one by one data
							if ($sms->templates[$indicator]->template_entry_date != '' and $sms->templates[$indicator]->template_entry_date != '00-00-0000 12:00:00 AM') {
								$entry_date = date('d-m-Y h:i:s A', strtotime($sms->templates[$indicator]->template_entry_date));
							}
							?>
							<tr>

								<td>
									<?= $indicatori ?>
								</td>

								<td>
									<?= $sms->templates[$indicator]->user_name; ?>
								</td>

								<td>
									<?= $sms->templates[$indicator]->template_name; ?>
								</td>

								<td>
									<?= $sms->templates[$indicator]->template_category; ?>
								</td>

								<td id='id_template_status_<?= $indicatori ?>'>
									<? if ($sms->templates[$indicator]->template_status == 'Y') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled"
											style="width:90px; text-align:center">Approved</a>
									<? } elseif ($sms->templates[$indicator]->template_status == 'N') { ?><a href="#!"
											class="btn btn-outline-warning btn-disabled"
											style="width:90px; text-align:center">Inactive</a>
									<? } elseif ($sms->templates[$indicator]->template_status == 'R') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled"
											style="width:90px; text-align:center">Rejected</a>
									<? } elseif ($sms->templates[$indicator]->template_status == 'F') { ?><a href="#!"
											class="btn btn-outline-dark btn-disabled" style="width:90px; text-align:center">Failed</a>
									<? } elseif ($sms->templates[$indicator]->template_status == 'D') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled"
											style="width:90px; text-align:center">Deleted</a>
									<? } elseif ($sms->templates[$indicator]->template_status == 'S') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled" style="width:90px; text-align:center">Waiting</a>
									<? } ?>
								</td>

								<td>
									<?= $entry_date; ?>
								</td>

								</td>
								<td><a href="#!"
										onclick="call_getsingletemplate('<?= $sms->templates[$indicator]->template_name ?>!<?= $sms->templates[$indicator]->language_code ?>', '<?= $indicatori ?>')">View</a>
									<? if ($sms->templates[$indicator]->template_response_id != '-' and $sms->templates[$indicator]->template_status != 'D') { ?>
										<!-- <a href="#!"
										onclick="remove_template_popup('<?= $sms->templates[$indicator]->unique_template_id ?>', '<?= $indicatori ?>')">Delete</a> -->
									<? } ?>
								</td>
							</tr>
							<?
						}
					}
					?>
				</tbody>
			</table>

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
							columns: [0, 1, 2, 3, 4, 5]
						}
					}, {
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5]
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
			<?
}
// template_list Page template_list - End

// template_whatsapp_list Page template_whatsapp_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "template_whatsapp_list") {
	site_log_generate("Template Whatsapp List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	// Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table 
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Campaign</th>
						<th>Group Name</th>
						<th>Count</th>
						<th>Sender No</th>
						<th>Status</th>
						<th>Entry Date</th>
					</tr>
				</thead>
				<tbody>
					<?
					// To Send the request API 
					$replace_txt = '{
        "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
      }';
					// Add bearer token
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// It will call "get_sent_messages_status_list" API to verify, can we can we allow to view the message list
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/compose_whatsapp_list',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'GET',
							CURLOPT_POSTFIELDS => $replace_txt,
							CURLOPT_HTTPHEADER => array(
								$bearer_token,
								'Content-Type: application/json'
							),
						)
					);
					// Send the data into API and execute   
					$response = curl_exec($curl);

					site_log_generate("Template Whatsapp List Page : " . $uname . " Execute the service [$replace_txt,$bearer_token] on " . date("Y-m-d H:i:s"), '../');
					curl_close($curl);
					// After got response decode the JSON result
					$sms = json_decode($response, false);
					site_log_generate("Template Whatsapp List Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
					// To get the one by one data
					$increment = 0;
					if ($sms->num_of_rows > 0) {
						// Looping the indicator is less than the num_of_rows.if the condition is true to continue the process.if the condition is false to stop the process
						for ($indicator = 0; $indicator < $sms->num_of_rows; $indicator++) {
							$increment++;

							$compose_whatsapp_id = $sms->report[$indicator]->compose_message_id;
							$user_id = $sms->report[$indicator]->user_id;
							$user_name = $sms->report[$indicator]->user_name;
							$campaign_name = $sms->report[$indicator]->campaign_name;
							$message_type = $sms->report[$indicator]->message_type;
							$total_mobileno_count = $sms->report[$indicator]->total_count;
							$cmm_status = $sms->report[$indicator]->cmm_status;
							$mobile_no = $sms->report[$indicator]->mobile_no;

							$group_name = $sms->report[$indicator]->group_name;
							$send_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->cmm_entry_date));

							?>
							<tr>
								<td>
									<?= $increment ?>
								</td>
								<td>
									<?= $user_name ?>
								</td>
								<td>
									<?= $campaign_name ?>
								</td>
								<td>
									<?= $group_name ?>
								</td>
								<td>Total Mobile No :
									<?= $total_mobileno_count ?>
								</td>
								<td>
									<?= $mobile_no ?>
								</td>


								<td id='id_template_status_<?= $indicatori ?>'>
									<? if ($cmm_status == 'Y') { ?><a href="#!" class="btn btn-outline-success btn-disabled"
											style="width:90px; text-align:center">Approved</a>
									<? } elseif ($cmm_status == 'N') { ?><a href="#!" class="btn btn-outline-warning btn-disabled"
											style="width:90px; text-align:center">Inactive</a>
									<? } elseif ($cmm_status == 'R') { ?><a href="#!" class="btn btn-outline-danger btn-disabled"
											style="width:90px; text-align:center">Rejected</a>
									<? } elseif ($cmm_status == 'F') { ?><a href="#!" class="btn btn-outline-dark btn-disabled"
											style="width:90px; text-align:center">Failed</a>
									<? } elseif ($cmm_status == 'D') { ?><a href="#!" class="btn btn-outline-danger btn-disabled"
											style="width:90px; text-align:center">Deleted</a>
									<? } elseif ($cmm_status == 'S') { ?><a href="#!" class="btn btn-outline-info btn-disabled"
											style="width:90px; text-align:center">Waiting</a>
									<? } ?>
								</td>

								<td>
									<?= $send_date ?>
								</td>
							</tr>
							<?
						}
					} else if ($sms->response_status == 204) {
						site_log_generate("Template Whatsapp List Page: " . $user_name . "get the Service response [$sms->response_status] on " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 2, "msg" => $sms->response_msg);
					} else {
						site_log_generate("Template Whatsapp List Page : " . $user_name . " get the Service response [$sms->response_msg] on  " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 0, "msg" => $sms->response_msg);
					}
					?>
				</tbody>
			</table>
			<!-- General JS Scripts -->
			<script src="assets/js/jquery.dataTables.min.js"></script>
			<script src="assets/js/dataTables.buttons.min.js"></script>
			<script src="assets/js/dataTables.searchPanes.min.js"></script>
			<script src="assets/js/dataTables.select.min.js"></script>
			<script src="assets/js/jszip.min.js"></script>
			<script src="assets/js/pdfmake.min.js"></script>
			<script src="assets/js/vfs_fonts.js"></script>
			<script src="assets/js/buttons.html5.min.js"></script>
			<script src="assets/js/buttons.colVis.min.js"></script>
			<!-- filter using -->
			<script>
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// template_whatsapp_list Page template_whatsapp_list - End

// plans_list Page plans_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "plans_list") {
	site_log_generate("plans_list List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>Plan Title</th>
						<th>Validity Period</th>
						<th>Whatsapp No Count</th>
						<th>Group No Count</th>
						<th>Plan Price</th>
						<th>Plan Status</th>
						<th>Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					$replace_txt = '';
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/plan/get_plans',
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
					site_log_generate("user_plans List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					$sms = json_decode($response, false);
					site_log_generate("user_plans List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->plan_entry_date));
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($sms->report[$indicator]->plan_title) ?>
								</td>
								<td>
									<? if ($sms->report[$indicator]->annual_monthly == "A") {
										echo "ANNUALLY" ?>
									<? } else {
										echo "MONTHLY" ?>
									<? } ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->whatsapp_no_max_count ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->group_no_max_count ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->plan_price ?>
								</td>
								<td>
									<? if ($sms->report[$indicator]->plan_status == 'Y') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled">Active</a>
									<? } elseif ($sms->report[$indicator]->plan_status == 'N') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled">Inactive</a>
									<? } elseif ($sms->report[$indicator]->plan_status == 'D') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled">Deleted</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td id='id_approved_lineno_<?= $indicatori ?>'>


									<? if ($sms->report[$indicator]->plan_status != 'D') { ?>
										<a href="plan_creation?plan_id=<?= $sms->report[$indicator]->plan_master_id ?>"
											class="btn btn-success">Edit Plan</a>
									<? } else { ?>
										<a href="#!" class="btn btn-outline-light btn-disabled"
											style="padding: 0.3rem 0.41rem !important;cursor: not-allowed;">Edit Plan</a>
									<? } ?>

									<? if ($sms->report[$indicator]->plan_status != 'D') { ?>
										<button type="button" title="Delete plan"
											onclick="remove_plan_popup('<?= $sms->report[$indicator]->plan_master_id ?>', 'D', '<?= $indicatori ?>')"
											class="btn btn-icon btn-danger" style="padding: 0.3rem 0.41rem !important;">Delete</button>
									<? } else { ?>
										<a href="#!" class="btn btn-outline-light btn-disabled"
											style="padding: 0.3rem 0.41rem !important;cursor: not-allowed;">Delete</a>
									<? } ?>
								</td>
								<?
						}
					}
					?>
				</tbody>
			</table>

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
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// plans_list Page plans_list - End

// purchase_plans_list Page purchase_plans_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "purchase_plans_list") {
	site_log_generate("user_plans List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Plan Title / Period</th>
						<th>Plan Amount</th>
						<th>Plan Status</th>
						<th style="width:20px;">Plan Comments</th>
						<th>Plan Reference Id</th>
						<th>Payment Status</th>
						<th>Entry Date</th>
						<th>Expiry Date</th>
					</tr>
				</thead>
				<tbody>
					<?
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					$replace_txt = '';
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/user_plans_list',
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
					site_log_generate("user_plans List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					$sms = json_decode($response, false);
					site_log_generate("user_plans List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < count($sms->user_plan_list); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->user_plan_list[$indicator]->user_plans_entdate));
							$plan_expiry_date = date('d-m-Y h:i:s A', strtotime($sms->user_plan_list[$indicator]->plan_expiry_date));
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($sms->user_plan_list[$indicator]->user_name) ?>
								</td>
								<td>
									<?= $sms->user_plan_list[$indicator]->plan_title . " / <br>" .
										strtoupper($sms->user_plan_list[$indicator]->annual_monthly) ?>
								</td>

								<td>
									<?= $sms->user_plan_list[$indicator]->plan_amount ?>
								</td>
								<td>
									<? if ($sms->user_plan_list[$indicator]->user_plans_status == 'A') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled">Approved</a>
									<? } elseif ($sms->user_plan_list[$indicator]->user_plans_status == 'R') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled">Rejected</a>
									<? } elseif ($sms->user_plan_list[$indicator]->user_plans_status == 'W') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled">Waiting</a>
									<? } ?>
								</td>
								<td>
									<?= $sms->user_plan_list[$indicator]->plan_comments ?>
								</td>
								<td>
									<?= $sms->user_plan_list[$indicator]->plan_reference_id ?>
								</td>
								<td>
									<? if ($sms->user_plan_list[$indicator]->payment_status == 'A') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled">Approved</a>
									<? } elseif ($sms->user_plan_list[$indicator]->payment_status == 'R') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled">Rejected</a>
									<? } elseif ($sms->user_plan_list[$indicator]->payment_status == 'W') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled">Waiting</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td>
									<?= $plan_expiry_date ?>
								</td>
								<?
						}
					}
					?>
				</tbody>
			</table>

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
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// purchase_plans_list Page purchase_plans_list - End


// payment_history_list Page payment_history_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "payment_history_list") {
	site_log_generate("payment_history List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Plan Title</th>
						<th>Payment Amount</th>
						<th> Payment History Status</th>
						<th>Plan Comments</th>
						<th>Plan Status</th>
						<th>Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					$replace_txt = '';
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/payment_history_list',
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
					site_log_generate("payment_history List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					$sms = json_decode($response, false);
					site_log_generate("payment_history List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < count($sms->payment_history_list); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->payment_history_list[$indicator]->payment_history_log_date));
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($sms->payment_history_list[$indicator]->user_name) ?>
								</td>
								<td>
									<?= $sms->payment_history_list[$indicator]->plan_title ?>
								</td>
								<td>
									<?= $sms->payment_history_list[$indicator]->plan_amount ?>
								</td>
								<td>
									<? if ($sms->payment_history_list[$indicator]->payment_history_logstatus == 'Y') { ?><a
											href="#!" class="btn btn-outline-success btn-disabled">Active</a>
									<? } elseif ($sms->payment_history_list[$indicator]->payment_history_logstatus == 'R') { ?><a
											href="#!" class="btn btn-outline-danger btn-disabled">Rejected</a>
									<? } elseif ($sms->payment_history_list[$indicator]->payment_history_logstatus == 'W') { ?><a
											href="#!" class="btn btn-outline-info btn-disabled">Waiting</a>
									<? } ?>
								</td>
								<td>
									<?= $sms->payment_history_list[$indicator]->plan_comments ?>
								</td>

								<td>
									<? if ($sms->payment_history_list[$indicator]->payment_status == 'A') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled" style="width:90px;">Approved</a>
									<? } elseif ($sms->payment_history_list[$indicator]->payment_status == 'R') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled" style="width:90px;">Rejected</a>
									<? } elseif ($sms->payment_history_list[$indicator]->payment_status == 'W') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled" style="width:90px;">Waiting</a>
									<? } elseif ($sms->payment_history_list[$indicator]->payment_status == 'N') { ?><a href="#!"
											class="btn btn-outline-info btn-disabled" style="width:90px;">Inactive</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td id='id_approved_lineno_<?= $indicatori ?>'>
									<? if ($sms->payment_history_list[$indicator]->payment_status == 'W') { ?>
										<button type="button" title="Add Payment"
											onclick="add_payment_status('<?= $sms->payment_history_list[$indicator]->user_name ?>','<?= $sms->payment_history_list[$indicator]->plan_master_id ?>','<?= $sms->payment_history_list[$indicator]->plan_amount ?>','<?= $sms->payment_history_list[$indicator]->user_email ?>','<?= $indicatori ?>')"
											class="btn btn-icon btn-danger" style="padding: 0.3rem 0.41rem !important;">Add
											Payment</button>
									<? } else { ?>
										<a href="#!" class="btn btn-outline-light btn-disabled"
											style="padding: 0.3rem 0.41rem !important;cursor: not-allowed;">Add Payment</a>
									<? } ?>
								</td>

							</tr>
							<?
						}
					}
					?>
				</tbody>
			</table>

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
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6, 7], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// payment_history_list Page payment_history_list - End

// manage_group_list Page manage_group_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_group_list") {
	site_log_generate("Group List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Sender ID</th>
						<th>Group Name</th>
						<th>Total Mobile Numbers</th>
						<th>Success Mobile Numbers</th>
						<th>Failure Mobile Numbers</th>
						<th>Status</th>
						<th>Entry Date</th>
						<th>Updated Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					$replace_txt = '';
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/group_list',
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
					site_log_generate("Group List Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);

					$sms = json_decode($response, false);
					site_log_generate("Group List Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }

					// print_r($sms); exit;
					$indicatori = 0;
					if ($sms->response_status == 200) {
						for ($indicator = 0; $indicator < count($sms->group_list); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->group_list[$indicator]->group_master_entdate));
							$group_updated_date = date('d-m-Y h:i:s A', strtotime($sms->group_list[$indicator]->group_updated_date));
							/* <?=  $sms->group_list[$indicator]->group_name ?>','<?= $sms->group_list[$indicator]->user_id ?>','<?= $sms->group_list[$indicator]->mobile_no ?>',*/
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($sms->group_list[$indicator]->user_name) ?>
								</td>
								<td>
									<?= $sms->group_list[$indicator]->mobile_no ?>
								</td>
								<td>
									<?= $sms->group_list[$indicator]->group_name ?>
								</td>
								<td>
									<?= $sms->group_list[$indicator]->total_count ?>
								</td>
								<td>
									<?= $sms->group_list[$indicator]->success_count ?>
								</td>
								<td>
									<?= $sms->group_list[$indicator]->failure_count ?>
								</td>
								<td>
									<? if ($sms->group_list[$indicator]->group_master_status == 'Y') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled" style="width:80px;">Active</a>
									<? } elseif ($sms->group_list[$indicator]->group_master_status == 'N') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled" style="width:80px;">Inactive</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td>
									<?= $group_updated_date ?>
								</td>
								<td>
									<div class="dropdown-primary dropdown open">
										<button class="btn btn-primary dropdown-toggle waves-effect waves-light btn-sm f-w-700"
											type="button" id="dropdown-2" data-toggle="dropdown" aria-haspopup="true"
											aria-expanded="true">Action</button>
										<div class="dropdown-menu" aria-labelledby="dropdown-2" data-dropdown-in="fadeIn"
											data-dropdown-out="fadeOut">

											<a href="add_contact_group?group=<?= $sms->group_list[$indicator]->group_master_id ?>&sender=<?= $sms->group_list[$indicator]->mobile_no ?>"
												class="dropdown-item waves-effect waves-light">Update Contacts</a>
											<? if ($sms->group_list[$indicator]->admin_status != 'Y') { ?>
												<a href="#!"
													onclick="group_contacts_popup('<?= $sms->group_list[$indicator]->group_master_id ?>','<?= $indicatori ?>','<?= $sms->group_list[$indicator]->group_name ?>');promote_admin_fuc()"
													class="dropdown-item waves-effect waves-light">Admin Promote</a>
											<? }
											if ($sms->group_list[$indicator]->admin_status == 'Y') { ?>
												<a href="#!"
													onclick="group_contacts_popup('<?= $sms->group_list[$indicator]->group_master_id ?>','<?= $indicatori ?>','<?= $sms->group_list[$indicator]->group_name ?>');demote_admin_fuc()"
													class="dropdown-item waves-effect waves-light">Admin Demote</a>
											<? } ?>

											<a href="#!"
												onclick="group_contacts_popup( '<?= $sms->group_list[$indicator]->group_master_id ?>', '<?= $indicatori ?>','<?= $sms->group_list[$indicator]->group_name ?>','<?= $sms->group_list[$indicator]->mobile_no ?>','<?= $sms->group_list[$indicator]->user_id ?>');remove_users_fuc()"
												class="dropdown-item waves-effect waves-light">Remove Users</a>
											<a href="#!"
												onclick="generateQRCode('<?= $sms->group_list[$indicator]->group_link ?>','<?= $indicatori ?>')"
												class="dropdown-item waves-effect waves-light">Join Members</a>

										</div>
									</div>

								</td>


							</tr>
							<?
						}
					}
					?>
				</tbody>
			</table>

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
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// manage_group_list Page manage_group_list - End

// manage_users_list Page manage_users_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "manage_users_list") {
	site_log_generate("Manage Users List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	// Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table 
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User Name</th>
						<th>Email Id</th>
						<th>Mobile No</th>
						<th>Plan Details</th>
						<th>User Status</th>
						<th>User Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					// To Send the request API 
					$replace_txt = '{
          "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
        }';
					// Add bearer token
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// It will call "manage_users" API to verify, can we can we allow to view the manage_users list
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/list/manage_users_list',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'GET',
							CURLOPT_POSTFIELDS => $replace_txt,
							CURLOPT_HTTPHEADER => array(
								$bearer_token,
								'Content-Type: application/json'
							),
						)
					);
					// Send the data into API and execute   
					$response = curl_exec($curl);
					site_log_generate("Manage Users List Page : " . $uname . " Execute the service [$replace_txt,$bearer_token] on " . date("Y-m-d H:i:s"), '../');
					curl_close($curl);
					// After got response decode the JSON result
					$sms = json_decode($response, false);
					site_log_generate("Manage Users List Page : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
					// To get the one by one data
					$indicatori = 0;
					if ($sms->num_of_rows > 0) {  // If the response is success to execute this condition
						for ($indicator = 0; $indicator < $sms->num_of_rows; $indicator++) {
							// Looping the indicator is less than the num_of_rows.if the condition is true to continue the process.if the condition is false to stop the process
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->usr_mgt_entry_date));
							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->user_name ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->user_email ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->user_mobile ?>
								</td>
								<td>
									<? if ($sms->report[$indicator]->plan_title) { ?>
										Plan Title :
										<?= $sms->report[$indicator]->plan_title ?><br>Plan Amount :
										<?= $sms->report[$indicator]->plan_price ?><br>Plan validity :
										<? if ($sms->report[$indicator]->annual_monthly == 'A') {
											echo "Annually";
										} else {
											echo "Monthly";

										}
									} else { ?>
										<div class="badge badge-danger">Not Purchased</div>
									<? } ?>
								</td>
								<td>
									<? if ($sms->report[$indicator]->usr_mgt_status == 'Y') { ?>
										<div class="badge badge-success">Active</div>
									<? } elseif ($sms->report[$indicator]->usr_mgt_status == 'R') { ?>
										<div class="badge badge-danger">Rejected</div>
									<? } elseif ($sms->report[$indicator]->usr_mgt_status == 'N') { ?>
										<div class="badge badge-primary">Waiting for Approval</div>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td>
									<? if (!$sms->report[$indicator]->plan_title) { ?>
										<div class="badge badge-success"><a href="pricing_plan" style="text-decoration: none;">Purchase
												Plan</a>
										</div>
									<? } else { ?>
										<div class="btn btn-outline-light btn-disabled" style="cursor: not-allowed;">Purchase Plan</div>
									<? } ?>
								</td>
							</tr>
							<?
						}
					} else if ($sms->response_status == 204) {
						site_log_generate("Manage Users List Page  : " . $user_name . "get the Service response [$sms->response_status] on " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 2, "msg" => $sms->response_msg);
					} else {
						site_log_generate("Manage Users List Page  : " . $user_name . " get the Service response [$sms->response_msg] on  " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 0, "msg" => $sms->response_msg);
					}
					?>
				</tbody>
			</table>
			<!-- General JS Scripts -->
			<script src="assets/js/jquery.dataTables.min.js"></script>
			<script src="assets/js/dataTables.buttons.min.js"></script>
			<script src="assets/js/dataTables.searchPanes.min.js"></script>
			<script src="assets/js/dataTables.select.min.js"></script>
			<script src="assets/js/jszip.min.js"></script>
			<script src="assets/js/pdfmake.min.js"></script>
			<script src="assets/js/vfs_fonts.js"></script>
			<script src="assets/js/buttons.html5.min.js"></script>
			<script src="assets/js/buttons.colVis.min.js"></script>
			<!-- filter  using-->
			<script>
				var table = $('#table-1').DataTable({
					dom: 'Bfrtip',
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6],
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}

					},
					{
						extend: 'csvHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in csvHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'pdfHtml5',
						exportOptions: {
							columns: [0, 1, 2, 3, 4, 5, 6], // Exclude the third column (index 3)
						},
						action: function (e, dt, button, config) {
							showLoader();
							// Use the built-in pdfHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					},
					{
						extend: 'searchPanes',
						config: {
							cascadePanes: true
						}
					},
						'colvis'
					],
					columnDefs: [{
						searchPanes: {
							show: false
						},
						targets: [0]
					}]
				});

				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}
// manage_users_list Page manage_users_list - End

// get_conatct_list Page get_conatct_list - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "remove_users_list") {
	site_log_generate("app_senderid_list List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	$group_master_id = htmlspecialchars(strip_tags(isset($_GET["group_master_id"]) ? $conn->real_escape_string($_GET["group_master_id"]) : ""));

	$replace_txt = '{
          "group_master_id" :  "' . $group_master_id . '"
      }';
	$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';

	$curl = curl_init();
	curl_setopt_array(
		$curl,
		array(
			CURLOPT_URL => $api_url . '/list/get_conatct_list',
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_ENCODING => '',
			CURLOPT_MAXREDIRS => 10,
			CURLOPT_TIMEOUT => 0,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
			CURLOPT_CUSTOMREQUEST => 'GET',
			CURLOPT_POSTFIELDS => $replace_txt,
			CURLOPT_HTTPHEADER => array(
				$bearer_token,
				'Content-Type: application/json'
			),
		)
	);

	$response = curl_exec($curl);
	curl_close($curl);
	$data = json_decode($response);

	if ($response == '') { ?>
				<script>
					window.location = "logout"
				</script>
			<?php }
	if ($data->response_status == 403) { ?>
				<script>
					window.location = "logout"
				</script>
			<?php }
	if ($data->response_status == 200) { ?>
				<!-- <label class="col-sm-6 col-form-label "> Group Users <label style="color:#FF0000">*</label></label> -->
				<!-- <label class="form-label col-sm-6" style="top:10px;">
					<input type="checkbox" class="cls_checkbox1 " onclick="toggle1(this);" tabindex="1" autofocus value="">
					<label class="form-label" style="top:10px;">
						Select all
					</label>
				</label> -->
				<? $indicatori = 0;
				?>
				<table style="width: 100%;">
					<?php
					// Assuming $data->contact_list exists in your JSON structure
					$contact_list = $data->contact_list;

					for ($indicator = 0; $indicator < count($contact_list); $indicator++) {
						if ($indicator % 2 == 0) { ?>
							<tr>
							<?php } ?>
							<td>
								<input type="radio" <?php if ($contact_list[$indicator]->mobile_no) { ?><?php } ?>
									class="cls_checkbox1" style="margin-left:15px;" id="txt_whatsapp_mobno_<?= $indicator ?>"
									name="txt_whatsapp_mobno" tabindex="1" autofocus
									value="<?= $contact_list[$indicator]->mobile_no . "-" . $contact_list[$indicator]->group_contacts_id ?>">
								<label class="form-label">
									<?= $contact_list[$indicator]->mobile_no ?>
								</label>
							</td>
							<?php
							if ($indicator % 2 == 1) { ?>
							</tr>
						<?php }
					}
					?>
				</table>
				<?
	} else if ($data->response_status == 204) {
		echo $data->response_status;
	}
}
// get_conatct_list Page get_conatct_list - End


// plans_details - check the available count - start (Create group)
if ($_SERVER['REQUEST_METHOD'] == "POST" and $tmpl_call_function == "plans_details") {
	site_log_generate("plans_details - check the available count Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');

	$replace_txt = '{
    "user_id":"' . $_SESSION['yjwatsp_user_id'] . '"
  }';
	$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
	$curl = curl_init();
	curl_setopt_array(
		$curl,
		array(
			CURLOPT_URL => $api_url . '/list/updateplans_list',
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
	site_log_generate("plans_details - check the available count : " . $_SESSION['yjwatsp_user_name'] . " Execute the get sender id service on " . date("Y-m-d H:i:s"));
	$response = curl_exec($curl);
	curl_close($curl);
	$state1 = json_decode($response, false);
	site_log_generate("plans_details - check the available count  : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"));

	if ($state1->response_status == 403) { ?>
				<script>
					window.location = "logout"
				</script>
			<? }

	if ($state1->response_status == 200) {
		for ($indicator = 0; $indicator < count($state1->plans_update); $indicator++) {
			$available_group_count = $state1->plans_update[$indicator]->available_group_count;
			$total_group_count = $state1->plans_update[$indicator]->total_group_count;
			$used_group_count = $state1->plans_update[$indicator]->used_group_count;
		}
	}

	if ($total_group_count == $used_group_count && $available_group_count == 0) {
		echo 0;
	} else {

	}
}
// add contact group - check the available count - End (Create group)

// messenger_responses Page messenger_responses - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "messenger_responses") {
	site_log_generate("Messenger Response List Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	// Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table 
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>Username</th>
						<th>Sender</th>
						<th>Receiver</th>
						<th>Reference ID</th>
						<th>Message Type</th>
						<th>Status</th>
						<th>Entry Date</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<?
					// To Send the request API 
					$replace_txt = '{
              "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '"
            }';
					// Add bearer token
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// It will call "messenger_response_list" API to verify, can we can we allow to view the messenger_response_list 
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/report/messenger_response_list',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'POST',
							CURLOPT_POSTFIELDS => $replace_txt,
							CURLOPT_HTTPHEADER => array(
								$bearer_token,
								'Content-Type: application/json'
							),
						)
					);
					// Send the data into API and execute  
					$response = curl_exec($curl);
					curl_close($curl);
					// After got response decode the JSON result
					$sms = json_decode($response, false);
					site_log_generate("Messenger Response List Page : User : " . $_SESSION['yjwatsp_user_name'] . " executed the Query reponse ($response) on " . date("Y-m-d H:i:s"));
					// To get the one by one data
					$indicatori = 0;
					if ($sms->response_status == 200) { // If the response is success to execute this condition
						for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
							// Looping the indicator is less than the count of report.if the condition is true to continue the process.if the condition is false to stop the process
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->message_rec_date));
							$tr_bg_clr = "";
							$td_text_clr = " font-weight: bold;";
							$stat_view = 'Read ';
							if ($sms->report[$indicator]->message_is_read == 'N') {
								$tr_bg_clr = "background-color: #5bd4672b";
								$td_text_clr = "color: #00391b; font-weight: bold;";
								$stat_view = 'Unread ';
							}
							?>
							<tr style="<?= $tr_bg_clr ?>">
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->user_name ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->message_from ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->message_to ?>
								</td>
								<td class="text-left">
									<? echo $string = (strlen($sms->report[$indicator]->message_resp_id) > 23) ? substr($sms->report[$indicator]->message_resp_id, 0, 20) . '...' : $sms->report[$indicator]->message_resp_id; ?>
								</td>
								<td>
									<?= strtoupper($sms->report[$indicator]->message_type) ?>
								</td>
								<td>
									<? if ($sms->report[$indicator]->message_status == 'Y') { ?><a href="#!"
											class="btn btn-outline-success btn-disabled">Active</a>
									<? } elseif ($sms->report[$indicator]->message_status == 'N') { ?><a href="#!"
											class="btn btn-outline-danger btn-disabled">Inactive</a>
									<? } ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td><a href="#!" style="<?= $td_text_clr ?>"
										onclick="func_view_response('<?= $sms->report[$indicator]->message_id ?>', '<?= $sms->report[$indicator]->message_from ?>', '<?= $sms->report[$indicator]->message_to ?>')">
										<?= $stat_view ?>View
									</a>
								</td>
							</tr>
							<?
						}
					} else if ($sms->response_status == 204) {
						site_log_generate("Messenger Response List Page : " . $user_name . "get the Service response [$sms->response_status] on " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 2, "msg" => $sms->response_msg);
					} else {
						site_log_generate("Messenger Response List Page : " . $user_name . " get the Service response [$sms->response_msg] on  " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 0, "msg" => $sms->response_msg);
					}
					?>
				</tbody>
			</table>
			<!-- General JS Scripts -->
			<script src="assets/js/jquery.dataTables.min.js"></script>
			<script src="assets/js/dataTables.buttons.min.js"></script>
			<script src="assets/js/dataTables.searchPanes.min.js"></script>
			<script src="assets/js/dataTables.select.min.js"></script>
			<script src="assets/js/jszip.min.js"></script>
			<script src="assets/js/pdfmake.min.js"></script>
			<script src="assets/js/vfs_fonts.js"></script>
			<script src="assets/js/buttons.html5.min.js"></script>
			<script src="assets/js/buttons.colVis.min.js"></script>
			<!-- filter using -->
			<script>
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
			<?
}
// messenger_responses Page messenger_responses - End

// campaign_report Page campaign_report - Start
/*if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "campaign_report") {
  site_log_generate("Campaign Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
  ?>
        <table class="table table-striped text-center" id="table-1">
            <thead>
                <tr class="text-center">
                    <th>#</th>
                    <th>User</th>
                    <th>Sender ID</th>
                    <th>Group Name</th>
                    <th>Campaign Name</th>
                    <th>Total Contacts</th>
                    <th>Success Contacts</th>
                    <th>Failure Contacts</th>
                    <th>Entry Date</th>
                </tr>
            </thead>
            <tbody>
                <?
                                $bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
                                $replace_txt = '';
                                $curl = curl_init();
                                curl_setopt_array(
                                  $curl,
                                  array(
                                    CURLOPT_URL => $api_url . '/report/campaign_report',
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
                                site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
                                $response = curl_exec($curl);
                                curl_close($curl);

                                $sms = json_decode($response, false);
                                site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

                                if ($sms->response_status == 403) { ?>
                <script>
                window.location = "logout"
                </script>
                <? }

                                // print_r($sms); exit;
                                $indicatori = 0;
                                if ($sms->response_status == 200) {
                                  for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
                                    $indicatori++;
                                    $entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->contact_mobile_entry_date));
                                    ?>
                <tr>
                    <td>
                        <?= $indicatori ?>
                    </td>
                    <td>
                        <?= strtoupper($sms->report[$indicator]->user_name) ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->mobile_no ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->group_name ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->campaign_name ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->total_contacts ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->total_success ?>
                    </td>
                    <td>
                        <?= $sms->report[$indicator]->total_failure ?>
                    </td>
                    <td>
                        <?= $entry_date ?>
                    </td>
                </tr>
                <?
                                  }
                                }
                                ?>
            </tbody>
        </table>

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
        <?
}*/
// campaign_report Page campaign_report - End


if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "business_summary_report") {
	site_log_generate("Business Summary Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	// Here we can Copy, Export CSV, Excel, PDF, Search, Column visibility the Table
	?>

			<table class="table table-striped" id="table-1">
				<thead>
					<tr>
						<th>#</th>
						<th>Date</th>
						<th>User</th>
						<th>Sender No</th>
						<!-- <th>Campaign Name</th> -->
						<!-- <th>Group Name</th> -->
						<th>Total Group Count</th>
						<th>Total Message Count</th>
						<th>Total Send Count</th>
						<th>Total Failed Count</th>
						<th>Total Revenue Earned</th>
					</tr>
				</thead>
				<tbody>
					<?
					$user_name_srch = $_REQUEST['user_name_srch'];
					$srch_1 = $_REQUEST['srch_1'];

					if ($_REQUEST['dates']) {
						$date = $_REQUEST['dates'];
					}
					// else {
					//   $date = date('m/d/Y') . "-" . date('m/d/Y'); // 01/28/2023 - 02/27/2023
					// }
				
					$td = explode('-', $date);
					$thismonth_startdate = date("Y/m/d", strtotime($td[0]));
					$thismonth_today = date("Y/m/d", strtotime($td[1]));

					$replace_txt .= '{';
					// "user_id" : "' . $_SESSION['yjwatsp_user_id'] . '",
					if (($user_name_srch != '[object HTMLSelectElement]' && empty($user_name_srch) == false) && ($user_name_srch != 'undefined') && ($user_name_srch != 'null')) {
						$replace_txt .= '"user_name" : "' . $user_name_srch . '",';
					}
					if ($date) {
						$replace_txt .= '"start_date" : "' . $thismonth_startdate . '",
            "end_date" : "' . $thismonth_today . '",';
					}

					if ($campaign_name_filter != 'undefined' && empty($campaign_name_filter) == false && $campaign_name_filter !== 'null') {
						$campaign_name_filter_trim = rtrim($campaign_name_filter, ",");
						$campaigns_name = str_replace(",", '","', $campaign_name_filter_trim);
						$replace_txt .= '"campaign_name" : "' . $campaigns_name . '",';
					}

					// To Send the request API
					$replace_txt = rtrim($replace_txt, ",");
					$replace_txt .= '}';

					// Add bearer token
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// To Get Api URL
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/report/summary_report',
							CURLOPT_RETURNTRANSFER => true,
							CURLOPT_ENCODING => '',
							CURLOPT_MAXREDIRS => 10,
							CURLOPT_TIMEOUT => 0,
							CURLOPT_FOLLOWLOCATION => true,
							CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
							CURLOPT_CUSTOMREQUEST => 'GET',
							CURLOPT_POSTFIELDS => $replace_txt,
							CURLOPT_HTTPHEADER => array(
								$bearer_token,
								'Content-Type: application/json'
							),
						)
					);
					// }
					// Send the data into API and execute
					site_log_generate("Business Summary Report Page : " . $uname . " Execute the service [$replace_txt,$bearer_token] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					// After got response decode the JSON result
					$sms = json_decode($response, false);
					site_log_generate("Business Summary Report Page  : " . $uname . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');
					// To get the one by one data
					$indicatori = 0;

					if ($response == '') { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					if ($sms->response_code == 1) {
						// If the response is success to execute this condition
						for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
							//Looping the indicator is less than the count of report.if the condition is true to continue the process.if the condition is false to stop the process
							$indicatori++;
							$entry_date = date('d-m-Y', strtotime($sms->report[$indicator]->group_contacts_entry_date));
							$user_name = $sms->report[$indicator]->user_name;
							$mobile_no = $sms->report[$indicator]->mobile_no;
							$group_name = $sms->report[$indicator]->group_name;
							$campaign_name = $sms->report[$indicator]->campaign_name;
							$total_count = $sms->report[$indicator]->total_count;
							$total_success = $sms->report[$indicator]->total_success;
							$total_failed = $sms->report[$indicator]->total_failure;
							$increment++;
							?>
							<tr style="text-align: center !important">
								<td>
									<?= $increment ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>
								<td>
									<?= strtoupper($user_name) ?>
									<input type="hidden" class="form-control" name='user_name_array[]' id='user_name_array'
										value='<?= $user_name ?>' />
								</td>

								<td>
									<?= $mobile_no ?>
								</td>
								<td>
									<?= $campaign_name ?>
									<input type="hidden" class="form-control" name='campaign_names[]' id='campaign_names'
										value='<?= $campaign_name ?>' />
								</td>
								<td>
									<?= $group_name ?>
								</td>
								<td>
									<?= $total_count ?>
								</td>

								<td>
									<?= $total_success ?>
								</td>
								<td>
									<?= $total_failed ?>
								</td>
							</tr>

							<?
						}
					} else if ($sms->response_status == 204) {
						site_log_generate("Business Summary Report Page  : " . $user_name . "get the Service response [$sms->response_status] on " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 2, "msg" => $sms->response_msg);
					} else {
						site_log_generate("Business Summary Report Page  : " . $user_name . " get the Service response [$sms->response_msg] on  " . date("Y-m-d H:i:s"), '../');
						$json = array("status" => 0, "msg" => $sms->response_msg);
					}
					?>

				</tbody>
			</table>
			<!-- General JS Scripts -->
			<script src="assets/js/jquery.dataTables.min.js"></script>
			<script src="assets/js/dataTables.buttons.min.js"></script>
			<script src="assets/js/dataTables.searchPanes.min.js"></script>
			<script src="assets/js/dataTables.select.min.js"></script>
			<script src="assets/js/jszip.min.js"></script>
			<script src="assets/js/pdfmake.min.js"></script>
			<script src="assets/js/vfs_fonts.js"></script>
			<script src="assets/js/buttons.html5.min.js"></script>
			<script src="assets/js/buttons.colVis.min.js"></script>
			<!-- filter using -->
			<script>
				var table = $('#table-1').DataTable({
					dom: 'PlBfrtip',
					searchPanes: {
						cascadePanes: true,
						initCollapsed: true
					},
					colReorder: true,
					buttons: [{
						extend: 'copyHtml5',
						exportOptions: {
							columns: [0, ':visible']
						},
						action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.copyHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					}, {
						extend: 'csvHtml5',
						exportOptions: {
							columns: ':visible'
						}, action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.csvHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					}, {
						extend: 'pdfHtml5',
						exportOptions: {
							columns: ':visible'
						}, action: function (e, dt, button, config) {
							showLoader(); // Display loader before export
							// Use the built-in copyHtml5 button action
							$.fn.dataTable.ext.buttons.pdfHtml5.action.call(this, e, dt, button, config);
							setTimeout(function () {
								hideLoader();
							}, 1000);
						}
					}, 'colvis'],
					columnDefs: [{
						searchPanes: {
							show: true
						},
						targets: [1, 2, 3, 4]
					}, {
						searchPanes: {
							show: false
						},
						targets: [1, 2, 3, 4]
					}]
				});
				function showLoader() {
					table.buttons().processing(true); // Show the DataTables Buttons processing indicator
					$(".loading").css('display', 'block');
					$('.loading').show();
				}

				function hideLoader() {
					$(".loading").css('display', 'none');
					$('.loading').hide();
					table.buttons().processing(false); // Hide the DataTables Buttons processing indicator
				}
			</script>
			<?
}

// campaign_report Page campaign_report - Start
if ($_SERVER['REQUEST_METHOD'] == "POST" and $call_function == "detailed_report") {
	site_log_generate("Campaign Report Page : User : " . $_SESSION['yjwatsp_user_name'] . " Preview on " . date("Y-m-d H:i:s"), '../');
	?>
			<table class="table table-striped text-center" id="table-1">
				<thead>
					<tr class="text-center">
						<th>#</th>
						<th>User</th>
						<th>Mobile No</th>
						<th>Group Name</th>
						<th>Campaign Name</th>
						<th>Mobile Id</th>
						<th>Response Messages</th>
						<th>Group Contact Status</th>
						<th>Date</th>
					</tr>
				</thead>
				<tbody>
					<?
					$user_name_srch = $_REQUEST['user_name_srch'];
					$srch_status = $_REQUEST['srch_status'];
					$replace_txt = '{';
					// To Send the request API
				
					if (($user_name_srch != 'undefined') && (empty($user_name_srch) == false) && ($user_name_srch != 'null')) {
						$replace_txt .= '"user_name" : "' . $user_name_srch . '",';
					}
					if (($_REQUEST['dates'] != 'undefined') && ($_REQUEST['dates'] != '[object HTMLInputElement]') && ($_REQUEST['dates'] != '')) {
						$date = $_REQUEST['dates'];
						$td = explode('-', $date);
						$thismonth_startdate = date("Y/m/d", strtotime($td[0]));
						$thismonth_today = date("Y/m/d", strtotime($td[1]));
						if ($date) {
							$replace_txt .= '"start_date" : "' . $thismonth_startdate . '",
            "end_date" : "' . $thismonth_today . '",';
						}
					} else {
						$currentDate = date('Y/m/d');
						$thirtyDaysAgo = date('Y/m/d', strtotime('-7 days', strtotime($currentDate)));
						$date = $thirtyDaysAgo . "-" . $currentDate; // 01/28/2023 - 02/27/2023
						$replace_txt .= '"start_date" : "' . $thirtyDaysAgo . '","end_date" :  "' . $currentDate . '",';
					}
					if (($campaign_name_filter != 'undefined') && (empty($campaign_name_filter) == false) && ($campaign_name_filter != 'null')) {
						$campaign_name_filter_trim = rtrim($campaign_name_filter, ",");
						$campaigns_name = str_replace(",", '","', $campaign_name_filter_trim);
						$replace_txt .= '"campaign_name" : "' . $campaigns_name . '",';
					}
					$replace_txt = rtrim($replace_txt, ",");
					$replace_txt .= '}';
					$bearer_token = 'Authorization: ' . $_SESSION['yjwatsp_bearer_token'] . '';
					// echo  $replace_txt;
					// $replace_txt = '';
					$curl = curl_init();
					curl_setopt_array(
						$curl,
						array(
							CURLOPT_URL => $api_url . '/report/detailed_report',
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
					site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " Execute the service [$replace_txt] on " . date("Y-m-d H:i:s"), '../');
					$response = curl_exec($curl);
					curl_close($curl);
					if ($response == '') { ?>
						<script>
							window.location = "logout"
						</script>
					<? }
					$sms = json_decode($response, false);
					site_log_generate("Campaign Report Page : " . $_SESSION['yjwatsp_user_name'] . " get the Service response [$response] on " . date("Y-m-d H:i:s"), '../');

					if ($sms->response_status == 403) { ?>
						<script>
							window.location = "logout"
						</script>
					<? }

					// print_r($sms); exit;
					$indicatori = 0;

					if ($sms->response_status == 200) {

						for ($indicator = 0; $indicator < count($sms->report); $indicator++) {
							$indicatori++;
							$entry_date = date('d-m-Y h:i:s A', strtotime($sms->report[$indicator]->group_contacts_entry_date));
							$user_name = $sms->report[$indicator]->user_name;

							$response_status = $sms->report[$indicator]->group_contacts_status;
							$grp_con_status = $sms->report[$indicator]->grp_con_status;
							$comments = $sms->report[$indicator]->comments;
							$disp_stat = '';
							switch ($response_status) {
								case 'Y':
									$disp_stat = '<div class="badge badge-success">SUCCESS</div>';
									break;
								case 'F':
									$disp_stat = '<div class="badge badge-danger">FAILURE</div>';
									break;
								case 'I':
									$disp_stat = '<div class="badge badge-warning">INVALID</div>';
									break;

								default:
									$disp_stat = '<div class="badge badge-info">YET TO SENT</div>';
									break;
							}

							?>
							<tr>
								<td>
									<?= $indicatori ?>
								</td>
								<td>
									<?= strtoupper($user_name) ?>
									<input type="hidden" class="form-control" name='user_name_array[]' id='user_name_array'
										value='<?= $user_name ?>' />
								</td>
								<td>
									<?= $sms->report[$indicator]->mobile_no ?>
								</td>
								<td>
									<?= $sms->report[$indicator]->group_name ?>
								</td>
								<td>
									<?= $campaign_name = $sms->report[$indicator]->campaign_name ?>
									<input type="hidden" class="form-control" name='campaign_names[]' id='campaign_names'
										value='<?= $campaign_name ?>' />
								</td>
								<td>
									<?= $sms->report[$indicator]->mobile_id ?>
								</td>
								<td>
									<?= $comments ?>
								</td>
								<td>
									<?= $disp_stat ?>
								</td>
								<td>
									<?= $entry_date ?>
								</td>

							</tr>
							<?
						}
					}
					?>
				</tbody>
			</table>

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
			<?
}
// campaign_report Page campaign_report - End


// Finally Close all Opened Mysql DB Connection
$conn->close();

// Output header with HTML Response
header('Content-type: text/html');
echo $result_value;
