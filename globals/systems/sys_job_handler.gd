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

## Submit a job to the job system for deferred loading. Takes in a work
## function, which runs on a separate thread, and a complete function, which 
## runs on the main thread. Anything that modifies the game world should happen
## in the complete function.
## [codeblock]
## work_function: func worker() -> JobResult
## complete_function: func complete(status: JobStatus, data: Variant) -> Variant
## [/codeblock]
## The complete function can be set up to run across multiple frames. If your
## complete function could still take a long period of time to add all of its
## features, which could freeze the game. The return type of the complete
## function is used to tell the job system of the work this job still needs to
## do. If the return value is non-null, the job system will add the job back
## to the queue.
func submit(work_function: Callable, complete_function: Callable) -> void:
	var job := Job.new()
	job.id = _get_next_job_id()
	job.worker = work_function
	job.complete = complete_function
	job.status = JobStatus.QUEUED
	
	WorkerThreadPool.add_task(_run_job.bind(job))

## Submits work to the main thread to be called over the next few frames. Does
## not spin up a worker thread or do any work on threads, simply puts main 
## thread work into the job queue to get to eventually.
## [codeblock]
## complete_function: func complete(status: JobStatus, data: Variant) -> Variant
## [/codeblock]
## The complete function can be set up to run across multiple frames. If your
## complete function could still take a long period of time to add all of its
## features, which could freeze the game. The return type of the complete
## function is used to tell the job system of the work this job still needs to
## do. If the return value is non-null, the job system will add the job back
## to the queue.
func defer(complete_function: Callable, user_data: Variant) -> void:
	var job := Job.new()
	job.id = _get_next_job_id()
	job.worker_task_id = -1
	job.complete = complete_function
	job.user_data = user_data
	job.status = JobStatus.COMPLETED
	
	_mux_finished_jobs.lock()
	_finished_jobs.push_back(job)
	_mux_finished_jobs.unlock()


func _process(_delta: float) -> void:
	var start_time := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time <= 3:
		_mux_finished_jobs.lock()
		if _finished_jobs.is_empty():
			_mux_finished_jobs.unlock()
			return
		
		var job : Job = _finished_jobs.pop_front()
		_mux_finished_jobs.unlock()
		
		if job.worker_task_id != -1:
			WorkerThreadPool.wait_for_task_completion(job.worker_task_id)
		
		var data : Variant = job.complete.call(job.status, job.user_data)
		if data != null:
			job.user_data = data
			
			_mux_finished_jobs.lock()
			_finished_jobs.push_back(job)
			_mux_finished_jobs.unlock()
		

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
