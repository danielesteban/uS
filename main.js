'use strict';

var Main = function(status) {
	['boot', 'epoch'].forEach(function(epoch) {
		status[epoch] = status[epoch][0] * 1000 + status[epoch][1] / 1000;
	});

	var uptime = document.getElementById('uptime'),
		timeDiff = (new Date() * 1) - status.epoch,
		updateTime = function() {
			var server = (new Date() * 1) - timeDiff,
				up = (server - status.boot) / 1000,
				fmt = function(n) {
					n = n + '';
					return (n < 10 ? '0' : '') + n;
				},
				hour = fmt(Math.floor(up / 3600)),
				min = fmt(Math.floor(up % 3600 / 60)),
				sec = fmt(Math.floor(up % 60));

			while(uptime.firstChild) uptime.removeChild(uptime.firstChild);
			uptime.appendChild(document.createTextNode(hour + ':' + min + ':' + sec));
		};

	setInterval(updateTime, 250);
	updateTime();

	var editor = ace.edit(document.getElementById('editor'));
	editor.getSession().setMode("ace/mode/lua");
	editor.setTheme("ace/theme/ambiance");
	editor.$blockScrolling = Infinity;

	var scripts = document.getElementById('scripts').getElementsByTagName('nav')[0],
		scriptTrigger = document.getElementById('scriptTrigger'),
		scriptInterval = document.getElementById('scriptInterval'),
		scriptSilent = document.getElementById('scriptSilent'),
		loadingScript = false,
		activeScript = null,
		loadScript = function(id) {
			if(loadingScript) return;
			loadingScript = true;
			editor.setValue('')
			Api('script', [id], function(code) {
				activeScript = id;
				for(var i in status.scripts) {
					document.getElementById('script_' + i).className = i === id ? 'active' : '';
				}
				loadingScript = false;
				scriptTrigger.value = status.scripts[id].trigger;
				scriptInterval.value = status.scripts[id].interval;
				scriptInterval.parentNode.style.display = status.scripts[id].trigger == 'interval' ? '' : 'none';
				scriptSilent.checked = status.scripts[id].silent == 1;
				editor.setValue(code, 1);
			}, true);
		},
		updateScripts = function() {
			while(scripts.firstChild) scripts.removeChild(scripts.firstChild);
			for(var id in status.scripts) {
				var li = document.createElement('li'),
					a = document.createElement('a');

				li.id = 'script_' + id;
				li.className = id === activeScript ? 'active' : '';
				a.appendChild(document.createTextNode(id + '.lua'));
				a.addEventListener('click', function(id) {
					return function() {
						loadScript(id);
					};
				}(id));
				li.appendChild(a);
				scripts.appendChild(li);
			}
		},
		saveScriptData = function() {
			Api('editScript', [
				activeScript,
				status.scripts[activeScript].trigger,
				status.scripts[activeScript].interval,
				status.scripts[activeScript].silent
			], function(response) {
				status.scripts = response;
				updateScripts();
			});
		};

	scriptTrigger.addEventListener('change', function() {
		if(activeScript === null) return;
		scriptInterval.parentNode.style.display = this.value == 'interval' ? '' : 'none';
		status.scripts[activeScript].trigger = this.value;
		saveScriptData()
	});

	scriptInterval.addEventListener('change', function() {
		if(activeScript === null) return;
		status.scripts[activeScript].interval = parseInt(this.value, 10);
		saveScriptData()
	});

	scriptSilent.addEventListener('change', function() {
		if(activeScript === null) return;
		status.scripts[activeScript].silent = this.checked ? 1 : 0;
		saveScriptData()
	});

	updateScripts();
	for(var id in status.scripts) {
		loadScript(id);
		break;
	}

	var savingScript = false;
	document.getElementById('saveScript').addEventListener('click', function() {
		if(activeScript === null || savingScript) return;
		savingScript = true;
		konsolePrint("Guardando & Compilando: " + activeScript + ".lc");
		Api('editScript', [
			activeScript,
			status.scripts[activeScript].trigger,
			status.scripts[activeScript].interval,
			status.scripts[activeScript].silent
		].concat(editor.getValue().split('\n')), function(response) {
			status.scripts = response;
			updateScripts();
			savingScript = false;
			konsolePrint("Listo!", true);
			refreshTimeout && clearTimeout(refreshTimeout);
			refreshTimeout = setTimeout(refreshKonsole, 1000);
		});
	});

	var runningScript = false;
	document.getElementById('runScript').addEventListener('click', function() {
		if(activeScript === null || runningScript) return;
		runningScript = true;
		konsolePrint("Ejecutando: " + activeScript + ".lc");
		Api('runScript', [activeScript], function(status) {
			runningScript = false;
			konsolePrint(status == 1 ? 'OK' : 'Error!', true);
			refreshTimeout && clearTimeout(refreshTimeout);
			refreshTimeout = setTimeout(refreshKonsole, 1000);
		}, true);
	});

	var removingScript = false;
	document.getElementById('removeScript').addEventListener('click', function() {
		if(activeScript === null || removingScript || !confirm("¿Estás seguro?")) return;
		removingScript = true;
		var name = activeScript;
		activeScript = null;
		scriptTrigger.value = 'manual';
		scriptInterval.value = 30;
		scriptInterval.parentNode.style.display = 'none';
		scriptSilent.checked = false;
		editor.setValue('');
		Api('removeScript', [name], function(response) {
			status.scripts = response;
			updateScripts();
			removingScript = false;
			for(var id in status.scripts) {
				loadScript(id);
				break;
			}
		});
	});

	var addingScript = false;
	document.getElementById('addScript').addEventListener('click', function() {
		if(addingScript) return;
		var name = window.prompt("Nombre del script");
		if(!name) return;
		addingScript = true;
		Api('editScript', [name, 'manual', 30, 0], function(response) {
			status.scripts = response;
			updateScripts();
			addingScript = false;
			loadScript(name);
		});
	});

	var konsole = document.getElementById('konsole'),
		konsoleClear = function() {
			while(konsole.firstChild) konsole.removeChild(konsole.firstChild);
		},
		konsolePrint = function(log, append) {
			!append && konsoleClear();
			log.split('\n').forEach(function(line) {
				var div = document.createElement('div');
				div.appendChild(document.createTextNode(line));
				konsole.appendChild(div);
			});
			konsole.scrollTop = konsole.scrollHeight;
		},
		refreshingKonsole = false,
		refreshTimeout = setTimeout(refreshKonsole, 30000),
		refreshKonsole = function() {
			refreshTimeout && clearTimeout(refreshTimeout);
			refreshTimeout = setTimeout(refreshKonsole, 30000);
			if(refreshingKonsole) return;
			refreshingKonsole = true;
			konsoleClear();
			Api('log', [], function(log) {
				konsolePrint(log);
				refreshingKonsole = false;
			}, true);
		};

	document.getElementById('refreshKonsole').addEventListener('click', refreshKonsole);
	refreshKonsole();

	document.getElementById('restart').addEventListener('click', function() {
		if(!confirm("¿Estás seguro?")) return;
		Api('restart', []);
		setInterval(function() {
			window.location.reload();
		}, 1000);
	});

	document.getElementById('logout').addEventListener('click', function() {
		window.localStorage.removeItem("µS:Auth");
		window.location.reload();
	});

	document.body.parentNode.className = 'main';
	document.getElementById('main').style.display = '';
};

window.addEventListener('DOMContentLoaded', function() {
	if(window.AUTH = window.localStorage.getItem("µS:Auth")) {
		Api('status', [], function(response) {
			if(response) return Main(response);
			window.localStorage.removeItem("µS:Auth");
			window.location.reload();
		});
	} else {
		var login = document.getElementById('login');
		login.getElementsByTagName('form')[0].addEventListener('submit', function(e) {
			e.preventDefault();
			if(this.password.value == "") return;
			var button = this.getElementsByTagName('button')[0];
			button.disabled = true;
			window.AUTH = CryptoJS.HmacSHA256(this.password.value, "||TheFuckingSecurestKeyEver||").toString();
			Api('status', [], function(response) {
				button.disabled = false;
				if(response == null) {
					window.AUTH = null;
					return alert('Error: Password incorrecta!');
				}
				login.style.display = 'none';
				Main(response);
				window.localStorage.setItem("µS:Auth", window.AUTH);
			});
		});
		login.style.display = '';
	}
});
