extends Node

# Singleton for handling HTTP requests to the backend
const BASE_URL = "http://localhost:5000"

var auth_token: String = ""
var user_data: Dictionary = {}
var selected_character: String = ""  # Stores selected character for child users

# Store the current HTTPRequest node
var _http_request: HTTPRequest
var _pending_callback: Callable
var _pending_auth_callback: Callable
var _request_queue: Array = []  # Queue for requests when HTTPRequest is busy
var _request_in_progress: bool = false

func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)

# Login function
func login(username: String, password: String, callback: Callable) -> void:
	var json = JSON.stringify({"username": username, "password": password})
	_make_request("/api/login", HTTPClient.METHOD_POST, json, func(result, response_code, _headers, body):
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
	_make_request("/api/register", HTTPClient.METHOD_POST, json, func(result, response_code, _headers, body):
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

# Get pending completions (for parent approval)
func get_pending_completions(callback: Callable) -> void:
	_make_authenticated_request("/api/pending-completions", HTTPClient.METHOD_GET, "", callback)

# Approve a pending completion (parent only)
func approve_completion(pending_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/pending-completions/" + pending_id + "/approve", HTTPClient.METHOD_POST, "", callback)

# Reject a pending completion (parent only)
func reject_completion(pending_id: String, callback: Callable) -> void:
	_make_authenticated_request("/api/pending-completions/" + pending_id + "/reject", HTTPClient.METHOD_POST, "", callback)

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
		print("HTTPClient: Not authenticated - auth_token is empty")
		callback.call(false, {"error": "Not authenticated"})
		return
	
	# If a request is in progress, queue this one
	if _request_in_progress:
		print("HTTPClient: Request in progress, queuing request to: ", endpoint)
		_request_queue.append({
			"endpoint": endpoint,
			"method": method,
			"body": body,
			"callback": callback,
			"authenticated": true
		})
		return
	
	# Start the request
	_request_in_progress = true
	_start_authenticated_request(endpoint, method, body, callback)

func _start_authenticated_request(endpoint: String, method: int, body: String, callback: Callable) -> void:
	# Disconnect any existing connections to prevent callback mixing
	if _http_request.request_completed.is_connected(_on_authenticated_request_completed):
		_http_request.request_completed.disconnect(_on_authenticated_request_completed)
	
	# Store callback for this request
	_pending_auth_callback = callback
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	
	var url = BASE_URL + endpoint
	print("HTTPClient: Making authenticated request to: ", url, " Method: ", method)
	
	# Connect the signal before making the request
	_http_request.request_completed.connect(_on_authenticated_request_completed, CONNECT_ONE_SHOT)
	
	# Use call_deferred to ensure we're not in the middle of another request
	call_deferred("_execute_authenticated_request", url, headers, method, body, callback)

func _on_authenticated_request_completed(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray) -> void:
	if _pending_auth_callback.is_valid():
		_handle_response(result, response_code, response_headers, response_body, _pending_auth_callback)
		_pending_auth_callback = Callable()
	
	# Mark request as complete and process queue on next frame
	_request_in_progress = false
	call_deferred("_process_queue")

# Helper to make regular requests
func _make_request(endpoint: String, method: int, body: String, callback: Callable) -> void:
	# If a request is in progress, queue this one
	if _request_in_progress:
		print("HTTPClient: Request in progress, queuing request to: ", endpoint)
		_request_queue.append({
			"endpoint": endpoint,
			"method": method,
			"body": body,
			"callback": callback,
			"authenticated": false
		})
		return
	
	# Start the request
	_request_in_progress = true
	_start_regular_request(endpoint, method, body, callback)

func _start_regular_request(endpoint: String, method: int, body: String, callback: Callable) -> void:
	# Disconnect any existing connections to prevent callback mixing
	if _http_request.request_completed.is_connected(_on_request_completed):
		_http_request.request_completed.disconnect(_on_request_completed)
	
	# Store callback for this request
	_pending_callback = callback
	
	var headers = ["Content-Type: application/json"]
	var url = BASE_URL + endpoint
	
	# Connect the signal before making the request
	_http_request.request_completed.connect(_on_request_completed, CONNECT_ONE_SHOT)
	
	# Use call_deferred to ensure we're not in the middle of another request
	call_deferred("_execute_regular_request", url, headers, method, body, callback)

func _on_request_completed(result: int, response_code: int, response_headers: PackedStringArray, response_body: PackedByteArray) -> void:
	if _pending_callback.is_valid():
		_pending_callback.call(result, response_code, response_headers, response_body)
		_pending_callback = Callable()
	
	# Mark request as complete and process queue on next frame
	_request_in_progress = false
	call_deferred("_process_queue")

# Execute the actual HTTP request (called deferred)
func _execute_authenticated_request(url: String, headers: Array, method: int, body: String, callback: Callable) -> void:
	var error = _http_request.request(url, headers, method, body)
	if error != OK:
		print("HTTPClient: Request failed with error: ", error)
		_request_in_progress = false
		_http_request.request_completed.disconnect(_on_authenticated_request_completed)
		callback.call(false, {"error": "Failed to make request"})
		call_deferred("_process_queue")
		return

func _execute_regular_request(url: String, headers: Array, method: int, body: String, callback: Callable) -> void:
	var error = _http_request.request(url, headers, method, body)
	if error != OK:
		_request_in_progress = false
		_http_request.request_completed.disconnect(_on_request_completed)
		callback.call(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
		call_deferred("_process_queue")
		return

# Process the next request in the queue
func _process_queue() -> void:
	if _request_queue.is_empty():
		return
	
	if _request_in_progress:
		return  # Still processing, wait
	
	var next_request = _request_queue.pop_front()
	print("HTTPClient: Processing queued request to: ", next_request.endpoint)
	
	if next_request.authenticated:
		_start_authenticated_request(next_request.endpoint, next_request.method, next_request.body, next_request.callback)
	else:
		_start_regular_request(next_request.endpoint, next_request.method, next_request.body, next_request.callback)

# Handle response
func _handle_response(result, response_code, _headers, body, callback: Callable) -> void:
	# Check for connection errors
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "Connection error. Make sure the backend server is running on " + BASE_URL
		print("HTTPClient: Connection error - ", result)
		callback.call(false, {"error": error_msg})
		return
	
	var body_text = body.get_string_from_utf8()
	print("HTTPClient: Response code: ", response_code, " Body: ", body_text)
	
	if response_code >= 200 and response_code < 300:
		var json_parser = JSON.new()
		var parse_result = json_parser.parse(body_text)
		if parse_result == OK:
			var data = json_parser.data
			print("HTTPClient: Parsed data type: ", typeof(data), " Data: ", data)
			callback.call(true, data)
		else:
			print("HTTPClient: JSON parse error: ", parse_result)
			# If body is empty or just whitespace, return empty array
			if body_text.strip_edges().is_empty():
				callback.call(true, [])
			else:
				callback.call(true, {})
	else:
		var error_msg = _parse_error_response(body)
		print("HTTPClient: Error response: ", error_msg)
		callback.call(false, {"error": error_msg})

# Parse error response
func _parse_error_response(body: PackedByteArray) -> String:
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(body.get_string_from_utf8())
	if parse_result == OK:
		var data = json_parser.data
		return data.get("error", "Unknown error")
	return "Unknown error"
