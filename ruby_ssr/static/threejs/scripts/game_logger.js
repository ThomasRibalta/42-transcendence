function LOG_DEBUG(msg){
	console.log("%c [DEBUG]: %o", 'color: green;', msg);
}

function LOG_INFO(msg){
	console.log("%c [INFO]: %o", 'color: blue;', msg);
}

function LOG_WARNING(msg){
	console.log("%c [WARNING]: %o", 'color: purple;', msg);
}

function LOG_ERROR(msg){
	console.log("%c [ERROR]: %o", 'color: red;', msg);
}

export {LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR}
