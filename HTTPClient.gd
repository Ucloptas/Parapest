extends Node

# Singleton for handling HTTP requests to the backend
const BASE_URL = "http://localhost:5000"

var auth_token: String = ""
var user_data: Dictionary = {}

# Store the current HTTPRequest node
var _http_request: HTTPRequest

func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)

# Login function
func login(username: String, password: String, callback: Callable) -> void:
	var json = JSON.stringify({"username": username, "password": password})
	_make_request("/api/login", HTTPClient.METHOD_POST, json, func(result, response_code, headers, body):
		# Check for connection errors
		if result != HTTPRequest.RESULT_SUCCESS:
			var error_msg = "Connection error. Make sure the backend server is running on " + BASE_URL
			callback.call(false, {"error": error_msg})
			return
		
		if response_code == 200:
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(body.get_string_from_utf8())
			if parse_result == OK:
				var data = json_parser.data
				auth_token = data.get("token", "")
				user_data = data.get("user", {})
				callback.call(true, data)
			else:
				callback.call(false, {"error": "Failed to parse response"})
		else:
			var error_msg = _parse_error_response(body)
			callback.call(false, {"error": error_msg})
	)

# Register function
func register(username: String, password: String, role: String, family_id: String, callback: Callable) -> void:
	var payload = {
		"username": username,
		"password": password,
		"role": role
	}
	if role == "child" and family_id != "":
		payload["familyId"] = family_id
	
	var json = JSON.stringify(payload)
	_make_request("/api/register", HTTPClient.METHOD_POST, json, func(result, response_code, headers, body):
		# Check for connection errors
		if result != HTTPRequest.RESULT_SUCCESS:
			var error_msg = "Connection error. Make sure the backend server is running on " + BASE_URL
			callback.call(false, {"error": error_msg})
			return
		
		if response_code == 200:
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(body.get_string_from_utf8())
			if parse_result == OK:
				var data = json_parser.data
				auth_token = data.get("token", "")
				user_data = data.get("user", {})
				callback.call(true, data)
			else:
				callback.call(false, {"error": "Failed to parse response"})
		else:
			var error_msg = _parse_error_response(body)
			callback.call(false, {"error": error_msg})
	)

# Get chores
func get_chores(callback: Callable) -> void:
	_make_authenticated_request("/api/chores", HTTPClient.METHOD_GET, "", callback)

# Create chore
func create_chore(title: String, description: String, points: int, callback: Callable) -> void:
	var json = JSON.stringify({
		"title": title,
		"description": description,
		"points": points
	})
	_make_authenticated_request("/api/chores", HTTPClient.METHOD_POST, json, callback)

# Update chore
func update_chore(chore_id: String, title: String, description: String, points: int, callback: Callable) -> void:
	var json = JSON.stringify({
		"title": title,
		"description": description,
		"points": points
	})
	_make_authenticated_request("/api/chores/" + chore_id, HTTPClient.METHOD_PUT, json, callback)

# Delete chore
func delete_chore(chore_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/chores/" + chore_id, HTTPClient.METHOD_DELETE, "", callback)

# Get rewards
func get_rewards(callback: Callable) -> void:
	_make_authenticated_request("/api/rewards", HTTPClient.METHOD_GET, "", callback)

# Create reward
func create_reward(title: String, description: String, cost: int, callback: Callable) -> void:
	var json = JSON.stringify({
		"title": title,
		"description": description,
		"cost": cost
	})
	_make_authenticated_request("/api/rewards", HTTPClient.METHOD_POST, json, callback)

# Update reward
func update_reward(reward_id: String, title: String, description: String, cost: int, callback: Callable) -> void:
	var json = JSON.stringify({
		"title": title,
		"description": description,
		"cost": cost
	})
	_make_authenticated_request("/api/rewards/" + reward_id, HTTPClient.METHOD_PUT, json, callback)

# Delete reward
func delete_reward(reward_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/rewards/" + reward_id, HTTPClient.METHOD_DELETE, "", callback)

# Get family members
func get_family(callback: Callable) -> void:
	_make_authenticated_request("/api/family", HTTPClient.METHOD_GET, "", callback)

# Get completed chores
func get_completed_chores(callback: Callable) -> void:
	_make_authenticated_request("/api/completed-chores", HTTPClient.METHOD_GET, "", callback)

# Get redeemed rewards
func get_redeemed_rewards(callback: Callable) -> void:
	_make_authenticated_request("/api/redeemed-rewards", HTTPClient.METHOD_GET, "", callback)

# Complete a chore (for children)
func complete_chore(chore_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/chores/" + chore_id + "/complete", HTTPClient.METHOD_POST, "", callback)

# Redeem a reward (for children)
func redeem_reward(reward_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/rewards/" + reward_id + "/redeem", HTTPClient.METHOD_POST, "", callback)

# Logout
func logout() -> void:
	auth_token = ""
	user_data = {}

# Helper to make authenticated requests
func _make_authenticated_request(endpoint: String, method: int, body: String, callback: Callable) -> void:
	if auth_token == "":
		callback.call(false, {"error": "Not authenticated"})
		return
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	
	_http_request.request_completed.connect(func(result, response_code, response_headers, response_body):
		_handle_response(result, response_code, response_headers, response_body, callback)
	, CONNECT_ONE_SHOT)
	
	var url = BASE_URL + endpoint
	_http_request.request(url, headers, method, body)

# Helper to make regular requests
func _make_request(endpoint: String, method: int, body: String, callback: Callable) -> void:
	var headers = ["Content-Type: application/json"]
	
	_http_request.request_completed.connect(func(result, response_code, response_headers, response_body):
		callback.call(result, response_code, response_headers, response_body)
	, CONNECT_ONE_SHOT)
	
	var url = BASE_URL + endpoint
	_http_request.request(url, headers, method, body)

# Handle response
func _handle_response(result, response_code, headers, body, callback: Callable) -> void:
	# Check for connection errors
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "Connection error. Make sure the backend server is running on " + BASE_URL
		callback.call(false, {"error": error_msg})
		return
	
	if response_code >= 200 and response_code < 300:
		var json_parser = JSON.new()
		var parse_result = json_parser.parse(body.get_string_from_utf8())
		if parse_result == OK:
			callback.call(true, json_parser.data)
		else:
			callback.call(true, {})
	else:
		var error_msg = _parse_error_response(body)
		callback.call(false, {"error": error_msg})

# Parse error response
func _parse_error_response(body: PackedByteArray) -> String:
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(body.get_string_from_utf8())
	if parse_result == OK:
		var data = json_parser.data
		return data.get("error", "Unknown error")
	return "Unknown error"

