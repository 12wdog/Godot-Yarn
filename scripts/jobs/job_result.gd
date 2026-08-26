class_name JobResult
extends RefCounted

var status : JobHandler.JobStatus
var data : Variant


static func completed(user_data : Variant) -> JobResult:
	var result := JobResult.new()
	result.status = JobHandler.JobStatus.COMPLETED
	result.data = user_data
	return result

static func failed(error : Error) -> JobResult:
	var result := JobResult.new()
	result.status = JobHandler.JobStatus.FAILED
	result.data = error
	return result
