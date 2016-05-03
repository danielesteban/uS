'use strict';

var Setup = function(networks) {
	var nav = document.getElementsByTagName('nav')[0],
		form = document.getElementsByTagName('form')[0];

	networks.forEach(function(ssid, index) {
		var li = document.createElement('li'),
			a = document.createElement('a');

		a.appendChild(document.createTextNode(ssid));
		a.addEventListener('click', function() {
			nav.style.display = 'none';
			form.style.display = '';
			if(index === networks.length - 1) form.ssid.focus();
			else {
				form.ssid.value = ssid;
				form.password.focus();
			}
		});
		li.appendChild(a);
		nav.appendChild(li);
	});
	[
		{
			input: form.password,
			checkbox: form.showWifiPassword
		},
		{
			input: form.appPassword,
			checkbox: form.showAppPassword
		}
	].forEach(function(password) {
		password.checkbox.addEventListener('change', function() {
			password.input.type = this.checked ? 'text' : 'password';
			password.input.focus();
		});
	});
	form.addEventListener('submit', function(e) {
		e.preventDefault();
		if(form.ssid.value === "" || form.password.value === "" || form.mdnsHost.value === "") return;
		if(form.password.value.length < 8 || form.password.value.length > 64)
			return alert('Error: La password del wifi debe ser de 8 a 64 caractéres.');
		if(form.appPassword.value.length < 8 || form.appPassword.value.length > 64)
			return alert('Error: La password del interfaz web debe ser de 8 a 64 caractéres.');
		
		var params = [form.ssid.value, form.password.value, CryptoJS.HmacSHA256(form.appPassword.value, "||TheFuckingSecurestKeyEver||").toString(), form.mdnsHost.value];
		if(form.noipHost.value !== "" && form.noipUser.value !== "" && form.noipPassword.value !== "") {
			params.push(form.noipHost.value, b64(form.noipUser.value + ':' + form.noipPassword.value))
		}
		Api('config', params);
		form.style.display = 'none';
		alert('La configuración se ha guardado con éxito!');
	});
};

window.addEventListener('DOMContentLoaded', function() {
	Api('networks', [], function(response) {
		var networks = [];
		response = response || {};
		for(var bssid in response) networks.push(response[bssid].split(',')[0]);
		networks.push('Otra red...')
		Setup(networks);
	});
});
