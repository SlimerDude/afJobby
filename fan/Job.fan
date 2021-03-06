using concurrent

** Wraps a job
** TODO break out a JobTrigger mixin / concept
const class Job {
	private const Log			log				:= Job#.pod.log
	private const AtomicBool	logScheduleRef	:= AtomicBool(false)
	private const AtomicBool	isCancelledRef	:= AtomicBool(false)
	private const AtomicRef		lastRunTimeRef	:= AtomicRef()
	private const AtomicRef		nextRunTimeRef	:= AtomicRef()
	
	internal const Type		jobType
	
	const |Job| job	
	
	Bool isCancelled {
		get { isCancelledRef.val }
		set { isCancelledRef.val = it }
	}
	
	DateTime? lastRunTime {
		get { lastRunTimeRef.val }
		internal set { lastRunTimeRef.val = it }
	}
	
	DateTime? nextRunTime {
		get { nextRunTimeRef.val }
		internal set { nextRunTimeRef.val = it }
	}
	
	internal new make(|This| f) { f(this) }

	Duration interval() {
		jobConfig := (JobConfig) jobType.facet(JobConfig#)
		return jobConfig.every
	}
	
	Void calcNextRunTime() {
		jobConfig := (JobConfig) jobType.facet(JobConfig#)
		
		if (lastRunTime == null) {
			if (jobConfig.at != null) {
				day := Time.now >= jobConfig.at.minus(251ms) ? Date.today + 1day : Date.today
				nextRunTime = day.toDateTime(jobConfig.at)
				return
			}
			nextRunTime = DateTime.now.plus(jobConfig.every)
			return
		}

		nextRunTime = lastRunTime.plus(jobConfig.every)
	}
	
	Void cancel() {
		isCancelled = true
	}
	
	Void logSchedule() {
		if (nextRunTime == null) {
			log.info("${typeof.name.toDisplayName} NOT scheduled to run")
			return
		}
		
		// no need to log this every day
		if (logScheduleRef.val == false)
			log.info("Scheduled ${typeof.name.toDisplayName} to run at " + nextRunTime.toLocale("DD MMM YYYY, hh:mm:ss") + ", and every ${DurationLocale.approx(interval)} thereafter")
		logScheduleRef.val = true
	}
}
