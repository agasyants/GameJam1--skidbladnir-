extends SubViewport

func turn_off():
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
func turn_on():
	self.process_mode = Node.PROCESS_MODE_INHERIT
	self.render_target_update_mode = SubViewport.UPDATE_ALWAYS
