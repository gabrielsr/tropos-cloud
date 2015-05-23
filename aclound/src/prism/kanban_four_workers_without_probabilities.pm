mdp


	formula w1_isAvailable =  worker1=0 ;
	formula w2_isAvailable =  worker2=0;
	formula w3_isAvailable =  worker3=0;
	formula w4_isAvailable =  worker4=0;


module kanban

	// number of tasks to do
	todo:[0..10] init 10;

	//number of completed tasks
	done:[0..10] init 0;

	//rename to w1_status
	// perceved status
	// n = 0 ready
	// n = 1 working
	// n = 2 unavailable
	// *? n = 3 trying to recover

	worker1:[0..2] init 0; 
	worker2:[0..2] init 0; 
	worker3:[0..2] init 0; 
	worker4:[0..2] init 0;
	
	// real state of a worker
	w1_state:[0..1] init 1;
	w2_state:[0..1] init 1;
	w3_state:[0..1] init 1;
	w4_state:[0..1] init 1;

	// - non deterministic a job is fetched by an available worker
	[fetch] (todo > 0 & worker1 =0 & w1_state = 1) -> (worker1'=1) & (todo'=todo-1);
	[fetch] (todo > 0 & worker2 =0 & w2_state = 1) -> (worker2'=1) & (todo'=todo-1);
	[fetch] (todo > 0 & worker3 =0 & w3_state = 1) -> (worker3'=1) & (todo'=todo-1);
	[fetch] (todo > 0 & worker4 =0 & w4_state = 1) -> (worker4'=1) & (todo'=todo-1);


	// non deterministically a worker complete a job if it is in a working state
	[complete] worker1 = 1 & w1_state = 1 & done<10 -> (worker1'=0) & (done'=done+1);
	[complete] worker2 = 1 & w2_state = 1 & done<10 -> (worker2'=0) & (done'=done+1);
	[complete] worker3 = 1 & w3_state = 1 & done<10 -> (worker3'=0) & (done'=done+1);
	[complete] worker4 = 1 & w4_state = 1 & done<10 -> (worker4'=0) & (done'=done+1);

	// generate failures in workers
	[fail] (w1_state = 1) -> (w1_state' = 0);
	[fail] (w2_state = 1) -> (w2_state' = 0);
	[fail] (w3_state = 1) -> (w3_state' = 0);
	[fail] (w4_state = 1) -> (w4_state' = 0);


	// if:: a worker has a task assigned and is discovered to be unavailable
	// than:: give back to backlog the task, mark as unavailable
	[discover_assigned_fail] worker1 = 1 & w1_state = 0 & todo<10 ->
		(worker1'=2) 
		& (todo'=todo+1);
	[discover_assigned_fail] worker2 = 1 & w2_state = 0 & todo<10 ->
		(worker2'=2) 
		& (todo'=todo+1);
	[discover_assigned_fail] worker3 = 1 & w3_state = 0 & todo<10 -> 
		(worker3'=2) 
		& (todo'=todo+1) ;
	[discover_assigned_fail] worker4 = 1 & w4_state = 0 & todo<10 -> 
		(worker4'=2) 
		& (todo'=todo+1);

	// if:: a worker has a task assigned and is discovered to be unavailable
	// than:: give back to backlog the task, and mark as unavailable
	[discover_unavailable] worker1 = 0 & w1_state = 0 ->
		(worker1'=2);
	[discover_unavailable] worker2 = 0 & w2_state = 0 ->
		(worker2'=2);
	[discover_unavailable] worker3 = 0 & w3_state = 0 -> 
		(worker3'=2);
	[discover_unavailable] worker4 = 0 & w4_state = 0 -> 
		(worker4'=2);

	// recover an worker in failure state
	[try_recover] worker1 = 2 -> (worker1'=0) & (w1_state'=1);
	[try_recover] worker2 = 2 -> (worker2'=0) & (w2_state'=1);
	[try_recover] worker3 = 2 -> (worker3'=0) & (w3_state'=1);
	[try_recover] worker4 = 2 -> (worker4'=0) & (w4_state'=1);



endmodule