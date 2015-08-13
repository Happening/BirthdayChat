DatePicker = require 'datepicker'

exports.nd = (day) ->
	date = DatePicker.dayToDate(day)
	now = new Date()
	y = now.getFullYear()-1
	cutOffTime = now.getTime() - 3*24*3600*1000
	loop
		date.setFullYear y++
		break if date.getTime() > cutOffTime
	0|(date.getTime() / 864e5)