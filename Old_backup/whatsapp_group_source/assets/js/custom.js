/**
 *
 * You can write your JS code here, DO NOT touch the default style file
 * because it will make it harder for you to update.
 * 
 */

"use strict";

function get_available_balance() {
	var txt_receiver_user = $("#txt_receiver_user").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			get_available_balance: 'get_available_balance',
			txt_receiver_user: txt_receiver_user
		},
		success: function(response) {
			$("#id_count_display").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function getParentUser() {
	var txt_parent_user = $("#txt_parent_user").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			getParentUser: 'getParentUser',
			txt_parent_user: txt_parent_user
		},
		success: function(response) {
			$("#txt_receiver_user").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function getStateByCountry() {
	var txt_country = $("#txt_country").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			getStateByCountry: 'getStateByCountry',
			txt_country: txt_country
		},
		success: function(response) {
			$("#txt_state").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function getCityByState() {
	var txt_state = $("#txt_state").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			getCityByState: 'getCityByState',
			txt_state: txt_state
		},
		success: function(response) {
			$("#txt_city").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function func_open_tab(newtab) {
	if (newtab == 'signup') {
		$("#tab_signin").css("display", "none");
		$("#tab_forgotpwd").css("display", "none");
		$("#tab_signup").css("display", "block");
		$("#txt_user_name").focus();
	}
	if (newtab == 'signin') {
		$("#tab_forgotpwd").css("display", "none");
		$("#tab_signup").css("display", "none");
		$("#tab_signin").css("display", "block");
		$("#txt_username").focus();
	}
	if (newtab == 'forgotpwd') {
		$("#tab_signin").css("display", "none");
		$("#tab_signup").css("display", "none");
		$("#tab_forgotpwd").css("display", "block");
		$("#txt_user_email_fp").focus();
	}
}

function password_visible() {
	var x = document.getElementById("txt_password");
	if (x.type === "password") {
		x.type = "text";
		$('#id_display_visiblitity').html('<i class="icofont icofont-eye"></i>');
	} else {
		x.type = "password";
		$('#id_display_visiblitity').html('<i class="icofont icofont-eye-blocked"></i>');
	}
}

function getStateByCountry() {
	var txt_country = $("#txt_country").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			getStateByCountry: 'getStateByCountry',
			txt_country: txt_country
		},
		success: function(response) {
			$("#txt_state").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function getCityByState() {
	var txt_state = $("#txt_state").val();
	$.ajax({
		type: 'post',
		url: "ajax/call_functions.php",
		data: {
			getCityByState: 'getCityByState',
			txt_state: txt_state
		},
		success: function(response) {
			$("#txt_city").html(response.msg);
		},
		error: function(response, status, error) {}
	});
}

function call_validate_mobileno() {
	var txt_user_mobile = $("#txt_user_mobile").val();
	// console.log(txt_user_mobile+"@@@@@"+txt_user_mobile.length);
	var stt = -1;
	if(txt_user_mobile.length > 9) {
			var letter = txt_user_mobile.charAt(0);
			// console.log("!!!"+letter);
			if(letter == 0 || letter == 1 || letter == 2 || letter == 3 || letter == 4 || letter == 5) {
					stt = 0;
			} else {
					stt = 1;
			}

			if(stt == 0)
					$('#txt_user_mobile').css('border-color','red'); 
			else
					$('#txt_user_mobile').css('border-color','#ccc'); 
	}
	// console.log(txt_user_mobile+"======"+stt);
	return stt;
}

function checkPasswordStrength() {
	var number = /([0-9])/;
	var alphabets = /([a-zA-Z])/;
	var special_characters = /([~,!,@,#,$,%,^,&,*,-,_,+,=,?,>,<])/;
	console.log($('#txt_user_password').val());
	if($('#txt_user_password').val().length<8) {
			console.log("Weak (should be atleast 8 characters.)");
			$('#txt_user_password').css('border-color','red'); 
			return false;
	} else {    
			if($('#txt_user_password').val().match(number) && $('#txt_user_password').val().match(alphabets) && $('#txt_user_password').val().match(special_characters)) {
					console.log("Strong");
					$('#txt_user_password').css('border-color','#a0a0a0'); 
					return true;
			} else {
					console.log("Medium (should include alphabets, numbers and special characters.)");
					$('#txt_user_password').css('border-color','red'); 
					return false;
			}
	}
}

function clsAlphaNoOnly(e) { // Accept only alpha numerics, no special characters 
	var key = e.keyCode;
	if ((key >= 65 && key <= 90) || (key >= 97 && key <= 122) || (key >= 48 && key <= 57) || key == 32 || key == 95) {
		return true;
	}
	return false;
}

const scrollTop = document.getElementById('scrolltop');
window.onscroll = () => {
	if (window.scrollY > 0) {
		scrollTop.style.visibility = "visible";
		scrollTop.style.opacity = 1;
	} else {
		scrollTop.style.visibility = "hidden";
		scrollTop.style.opacity = 0;
	}
};