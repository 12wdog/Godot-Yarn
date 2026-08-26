extends Node

enum JobStatus {
	QUEUED,
	RUNNING,
	COMPLETED,
	FAILED,
}

var _next_job_id : int = 0
var _mux_next_job_id := Mutex.new()

var _finished_jobs : Array[Job] = []
var _mux_finished_jobs := Mutex.new()

func submit(work_function: Callable, complete_function: Callable) -> void:
	var job := Job.new()
	job.id = _get_next_job_id()
	job.worker = work_function
	job.complete = complete_function
	job.status = JobStatus.QUEUED
	
	WorkerThreadPool.add_task(_run_job.bind(job))

func _process(_delta: float) -> void:
	_mux_finished_jobs.lock()
	
	if _finished_jobs.is_empty():
		_mux_finished_jobs.unlock()
		return
	
	var jobs := _finished_jobs
	_finished_jobs = []
	
	_mux_finished_jobs.unlock()
	
	for job : Job in jobs:
		WorkerThreadPool.wait_for_task_completion(job.worker_task_id)
		job.complete.call(job.status, job.user_data)

func _get_next_job_id() -> int:
	_mux_next_job_id.lock()
	_next_job_id += 1
	_mux_next_job_id.unlock()
	
	return _next_job_id

func _run_job(job : Job) -> void:
	job.worker_task_id = WorkerThreadPool.get_caller_task_id()
	job.status = JobStatus.RUNNING
	
	var result : JobResult = job.worker.call()
	
	job.status = result.status
	
	job.user_data = result.data
	
	_mux_finished_jobs.lock()
	_finished_jobs.push_back(job)
	_mux_finished_jobs.unlock()


class Job extends RefCounted:
	var id : int
	var worker_task_id: int
	var status : JobStatus
	var user_data : Variant
	var worker : Callable
	var complete : Callable
