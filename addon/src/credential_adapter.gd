## Injected persistence boundary for native OS credential facilities.
## Implementations must commit writes atomically. The addon verifies every write
## by reading the committed value back before reporting success.
class_name PocketBaseCredentialAdapter
extends RefCounted

enum Status {
	OK,
	NOT_FOUND,
	UNAVAILABLE,
	INVALID_ARGUMENT,
	IO_ERROR,
}

class Result extends RefCounted:
	var status: Status = Status.UNAVAILABLE
	var value: String = ""
	var detail: String = ""

	func _init(
		resolved_status: Status = Status.UNAVAILABLE,
		resolved_value: String = "",
		resolved_detail: String = ""
	) -> void:
		status = resolved_status
		value = resolved_value
		detail = resolved_detail

	func is_ok() -> bool:
		return status == Status.OK

func read_value(_key: String) -> Result:
	return Result.new(Status.UNAVAILABLE, "", "credential adapter read is unavailable")

func write_value(_key: String, _value: String) -> Result:
	return Result.new(Status.UNAVAILABLE, "", "credential adapter write is unavailable")


## Process-memory web adapter. Values intentionally do not survive page reload.
## Browser memory is script-accessible and is not represented as a keystore.
class WebMemoryAdapter extends PocketBaseCredentialAdapter:
	static var _values: Dictionary[String, String] = {}

	func read_value(key: String) -> Result:
		if not _values.has(key):
			return Result.new(Status.NOT_FOUND)
		return Result.new(Status.OK, _values[key])

	func write_value(key: String, value: String) -> Result:
		_values[key] = value
		return Result.new(Status.OK)

	static func clear_process_memory() -> void:
		_values.clear()
