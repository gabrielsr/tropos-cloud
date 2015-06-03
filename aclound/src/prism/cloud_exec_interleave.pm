dtmc

//formula noError = true & sT1_1 < 4 & sT1_2 < 4 & sT2_11 < 4 & sT2_12 < 4 & sT2_21 < 4 & sT2_22 < 4 & sT3_1 < 4 & sT3_2 < 4 & sT4_1 < 4 & (sT4_21 < 4 | (true  & sT4_22 < 4));




	const TASKS_COUNT = 500;
	const INSTANCE_MAX = 10;

	const TASKS_COMPLEXTY = 100;
	const INSTANCE_CAPACITY = 10;


// backlog
global jobs_todo:[0..TASKS_COUNT] init TASKS_COUNT;
global jobs_completed:[0..TASKS_COUNT] init 0;


//number of instances
// instances that was created but not configured yet
global instances_created:[0..INSTANCE_MAX] init 0;
// instances that is ready to assign
global instances_ready:[0..INSTANCE_MAX] init 0;
// instances assigned to a job
global instances_assigned:[0..INSTANCE_MAX] init 0;
// instances that is unavailable
global instances_unavailable:[0..INSTANCE_MAX] init 0;

formula active_instances = instances_created+instances_ready+instances_assigned+instances_unavailable;
formula instances_running = instances_assigned-instances_unavailable;

formula job_conclusion_rate = 1-(TASKS_COMPLEXTY/(TASKS_COMPLEXTY+instances_running*INSTANCE_CAPACITY));

const double rTaskT1_1;

module T1_1_RequestAInstance
	sT1_1 :[0..4] init 0;
	
	[success0_0]  sT1_1 = 0 -> (sT1_1'=1);//init to running
	
	// we should transit to success after create the target number and 
	// explicit call this module with a st1_1=1 to create a new instance after a not recovarable failure?

	[] sT1_1 =  1 & active_instances < INSTANCE_MAX -> 
		rTaskT1_1 : (instances_created'=instances_created+1) &
			(sT1_1' = 2) //create instance
		+ (1 - rTaskT1_1) : (sT1_1'=4);//cant create instance


	//[] sT1_1 =  1 -> rTaskT1_1 : (sT1_1'=2) + (1 - rTaskT1_1) : (sT1_1'=4);//running to final state

	[success0_1] sT1_1 = 2 -> (sT1_1'=1);//return to 1
	[success0_1] sT1_1 = 3 -> (sT1_1'=3);//final state skipped
	[failT1_1] sT1_1 = 4 -> (sT1_1'=1);//final state failure
endmodule

const double rTaskT1_2;

module T1_2_StartConfiguration
	sT1_2 :[0..4] init 0;
	
	[success0_1]  sT1_2 = 0 -> (sT1_2'=1);//init to running
	



	[] sT1_2 =  1 -> rTaskT1_2 : (sT1_2'=2)  //from created to ready
			& (instances_created'=max(instances_created-1,0))
			& (instances_ready'=min(instances_ready+1,INSTANCE_MAX))

		 + (1 - rTaskT1_2) : (sT1_2'=4);//running to final state

	[success0_2] sT1_2 = 2 -> (sT1_2'=0);//final state success
	[success0_2] sT1_2 = 3 -> (sT1_2'=3);//final state skipped
	[failT1_2] sT1_2 = 4 -> (sT1_2'=0);//final state failure
endmodule

formula G1 = (((sT1_1=2)) | ((sT1_2=2)));

const double rTaskT2_11;

module T2_11_FetchJob
	sT2_11 :[0..4] init 0;
	
	[success0_0]  sT2_11 = 0 -> (sT2_11'=1);//init to running
	



	[] sT2_11 =  1 & jobs_todo > 0 -> rTaskT2_11 : (sT2_11'=2) 
		& (jobs_todo'= jobs_todo-1) //do fetch a task
		+ (1 - rTaskT2_11) : (sT2_11'=4);//running to final state
	
	[success1_1] sT2_11 = 2 -> (sT2_11'=1);//final state success
	[success1_1] sT2_11 = 3 -> (sT2_11'=3);//final state skipped
	[failT2_11] sT2_11 = 4 -> (sT2_11'=1);//final state failure
endmodule

const double rTaskT2_12;

module T2_12_AssignJobToAnInstance
	sT2_12 :[0..4] init 0;
	
	[success1_1]  sT2_12 = 0 -> (sT2_12'=1);//init to running
	



	[] sT2_12 =  1 & instances_ready > 0 -> rTaskT2_12 : (sT2_12'=2) //from ready to assigned
			& (instances_ready'= instances_ready-1)
			& (instances_assigned'=min(instances_assigned+1,INSTANCE_MAX))

		+ (1 - rTaskT2_12) : (sT2_12'=4);//running to final state
	[success1_2] sT2_12 = 2 -> (sT2_12'=0);//final state success
	[success1_2] sT2_12 = 3 -> (sT2_12'=3);//final state skipped
	[failT2_12] sT2_12 = 4 -> (sT2_12'=0);//final state failure
endmodule

const double rTaskT2_21;

module T2_21_ExecuteJob
	sT2_21 :[0..4] init 0;
	
	[success0_0]  sT2_21 = 0 -> (sT2_21'=1);//init to running
	



	[] sT2_21 =  1 & (instances_assigned > 0) -> rTaskT2_21*job_conclusion_rate : (sT2_21'=2) // concluded job
	+ rTaskT2_21*(1-job_conclusion_rate) : (sT2_21'=2) //not concluded yet
	+ (1 - rTaskT2_21) : (sT2_21'=4)//running to final state
		& (instances_unavailable'=min(instances_unavailable+1,INSTANCE_MAX));
	
	[success2_1] sT2_21 = 2 -> (sT2_21'=1);//final state success
	[success2_1] sT2_21 = 3 -> (sT2_21'=3);//final state skipped
	[failT2_21] sT2_21 = 4 -> (sT2_21'=1);//final state failure
endmodule

const double rTaskT2_22;

module T2_22_GetJobResult
	sT2_22 :[0..4] init 0;
	
	[success2_1]  sT2_22 = 0 -> (sT2_22'=1);//init to running
	



	[] sT2_22 =  1 -> rTaskT2_22 : (sT2_22'=2) 
		&(jobs_completed'=min(jobs_completed+1,TASKS_COUNT))
		+ (1 - rTaskT2_22) : (sT2_22'=4);//running to final state
	[success2_2] sT2_22 = 2 -> (sT2_22'=0);//final state success
	[success2_2] sT2_22 = 3 -> (sT2_22'=3);//final state skipped
	[failT2_22] sT2_22 = 4 -> (sT2_22'=0);//final state failure
endmodule

const double rTaskT2_23;

module T2_23_ReturnInstanceToPool
	sT2_23 :[0..4] init 0;
	
	[success2_2]  sT2_23 = 0 -> (sT2_23'=1);//init to running
	



	[] sT2_23 =  1 -> rTaskT2_23 : (sT2_23'=2)
		& (instances_assigned'=max(instances_assigned-1,0))
		& (instances_ready'=min(instances_ready+1,INSTANCE_MAX))
		+ (1 - rTaskT2_23) : (sT2_23'=4);//running to final state
	[success2_3] sT2_23 = 2 -> (sT2_23'=0);//final state success
	[success2_3] sT2_23 = 3 -> (sT2_23'=3);//final state skipped
	[failT2_23] sT2_23 = 4 -> (sT2_23'=0);//final state failure
endmodule

formula G2 = ((((sT2_11=2)) | ((sT2_12=2))) | (((sT2_21=2)) | ((sT2_22=2)) | ((sT2_23=2))));

const double rTaskT3_1;

module T3_1_MergeResults
	sT3_1 :[0..4] init 0;
	
	[success0_0]  sT3_1 = 0 -> (sT3_1'=1);//init to running
	



	[] sT3_1 =  1 &(jobs_todo=0) -> rTaskT3_1 : (sT3_1'=2) + (1 - rTaskT3_1) : (sT3_1'=4);//running to final state
	[success3_1] sT3_1 = 2 -> (sT3_1'=2);//final state success
	[success3_1] sT3_1 = 3 -> (sT3_1'=3);//final state skipped
	[failT3_1] sT3_1 = 4 -> (sT3_1'=4);//final state failure
endmodule

const double rTaskT3_2;

module T3_2_SendResponse
	sT3_2 :[0..4] init 0;
	
	[success3_1]  sT3_2 = 0 -> (sT3_2'=1);//init to running
	



	[] sT3_2 =  1 -> rTaskT3_2 : (sT3_2'=2) + (1 - rTaskT3_2) : (sT3_2'=4);//running to final state
	[success3_2] sT3_2 = 2 -> (sT3_2'=2);//final state success
	[success3_2] sT3_2 = 3 -> (sT3_2'=3);//final state skipped
	[failT3_2] sT3_2 = 4 -> (sT3_2'=4);//final state failure
endmodule

formula G3 = (((sT3_1=2)) | ((sT3_2=2)));

const double rTaskT4_1;

module T4_1_IdentifyInstanceFailure
	sT4_1 :[0..4] init 0;
	
	[success0_0]  sT4_1 = 0 -> (sT4_1'=1);//init to running
	



	[] sT4_1 =  1 & (instances_unavailable>0) -> rTaskT4_1 : (sT4_1'=2) 
		+ (1 - rTaskT4_1) : (sT4_1'=4);//running to final state

	[success4_1] sT4_1 = 2 -> (sT4_1'=1);//final state success
	[success4_1] sT4_1 = 3 -> (sT4_1'=1);//final state skipped
	[failT4_1] sT4_1 = 4 -> (sT4_1'=1);//final state failure
endmodule

const double rTaskT4_21;
const double maxRetriesT4_21=3;

module T4_21_RecoverWithRestart
	sT4_21 :[0..4] init 0;
	triesT4_21 : [0..3] init 0;

	[success4_1]  sT4_21 = 0 -> (sT4_21'=1) & (triesT4_21'=0);//init to running
	

	[] sT4_21 = 1 & triesT4_21 < maxRetriesT4_21 -> rTaskT4_21 : (sT4_21'=2) 
	& (instances_unavailable'=max(instances_unavailable-1,0))
	+ (1 - rTaskT4_21) : (triesT4_21'=triesT4_21+1);//try
	[] sT4_21 = 1 & triesT4_21 = maxRetriesT4_21 -> (sT4_21'=4);//no more retries
	[success4_2] sT4_21 = 2 -> (sT4_21'=0);//final state success
	[success4_2] sT4_21 = 3 -> (sT4_21'=3);//final state skipped
	[failT4_21] sT4_21 = 4 -> (sT4_21'=0);//final state failure
endmodule

const double rTaskT4_221;

module T4_221_DisposeFailInstance
	sT4_221 :[0..4] init 0;
	
	[failT4_21]   sT4_221 = 0 -> (sT4_221'=1);//init to running

	[] sT4_221 =  1 -> rTaskT4_221 : (sT4_221'=2) 
		&(instances_unavailable'=max(instances_unavailable-1,0))
		+ (1 - rTaskT4_221) : (sT4_221'=4);//running to final state
	[success4_3] sT4_221 = 2 -> (sT4_221'=0);//final state success
	[success4_3] sT4_221 = 3 -> (sT4_221'=3);//final state skipped
	[failT4_221] sT4_221 = 4 -> (sT4_221'=0);//final state failure
endmodule

const double rTaskT4_222;

module T4_222_RecreateInstance
	sT4_222 :[0..4] init 0;
	
	[failT4_21]   sT4_222 = 0 -> (sT4_222'=1);//init to running
	[success4_3]  sT4_222 = 0 -> (sT4_222'=3);//not used, skip running

	//TODO call create instance and configure
	[] sT4_222 =  1 -> rTaskT4_222 : (sT4_222'=2) + (1 - rTaskT4_222) : (sT4_222'=4);//running to final state
	[success4_4] sT4_222 = 2 -> (sT4_222'=2);//final state success
	[success4_4] sT4_222 = 3 -> (sT4_222'=3);//final state skipped
	[failT4_222] sT4_222 = 4 -> (sT4_222'=4);//final state failure
endmodule

formula G4 = (((sT4_1=2)) | (((sT4_21=2)) | (((sT4_221=2)) | ((sT4_222=2)))));

formula G0 = G1 | G2 | G3 | G4;