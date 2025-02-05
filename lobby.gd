extends Control

var port = gamestate.DEFAULT_PORT

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("lobby_joined", self, "_update_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")
	
	if OS.get_name() == 'HTML5':
		$Connect/Server.hide()
		var data = JavaScript.eval("(new URLSearchParams(window.location.hash.replace('#', '', 1))).get('lobby')")
		if typeof(data) == TYPE_STRING:
			$Connect/Lobby.text = data
	
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size() - 2]


func _update_lobby(text):
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.set('lobby', '" + text + "'); window.location.hash = x.toString()")
	$Players/Lobby.text = text


func _on_host_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""

	var player_name = $Connect/Name.text
	
	# WEBRTC: host game code.
	var ip = $Connect/IPAddress.text
	gamestate.host_game(player_name, ip)
	
	# WEBRTC: refresh_lobby() gets called by the player_list_changed signal, emitted when host is ready.


func _on_join_pressed():
	if $Connect/Name.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return

	var ip = $Connect/IPAddress.text
	var lobby = $Connect/Lobby.text
	
	if lobby == "":
		$Connect/ErrorLabel.text = "Must specify a lobby when joining!"
		return

	$Connect/ErrorLabel.text = ""
	$Connect/Host.disabled = true
	$Connect/Join.disabled = true

	var player_name = $Connect/Name.text
	gamestate.join_game(ip, player_name, lobby)
	
	# WEBRTC: refresh_lobby() gets called by the player_list_changed signal.


func _on_connection_success():
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	if OS.get_name() == 'HTML5':
		JavaScript.eval("var x = new URLSearchParams(window.location.hash.replace('#', '', 1)); x.delete('lobby'); window.location.hash = x.toString()")
	$Players/Lobby.text = ""
	$Connect/Lobby.text = ""


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_minsize()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false


func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	$Players/List.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not get_tree().is_network_server()


func _on_start_pressed():
	gamestate.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")


func _on_server_toggled(button_pressed):
	if button_pressed:
		Server.listen(port)
		$Connect/Server.text = "Stop"
	else:
		Server.stop()
		$Connect/Server.text = "Listen"
